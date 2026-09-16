import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database.dart';
import '../services/storage_identity_service.dart';
import 'media_scanner.dart';

/// Progress state emitted during a library scan operation.
class ScanProgress {
  final String storageId;
  final String storageName;
  final int filesDiscovered;
  final int moviesIdentified;
  final int tvEpisodesIdentified;
  final int needsVerification;
  final String? currentFile;
  final bool isComplete;
  final String? error;

  const ScanProgress({
    required this.storageId,
    required this.storageName,
    this.filesDiscovered = 0,
    this.moviesIdentified = 0,
    this.tvEpisodesIdentified = 0,
    this.needsVerification = 0,
    this.currentFile,
    this.isComplete = false,
    this.error,
  });

  ScanProgress copyWith({
    int? filesDiscovered,
    int? moviesIdentified,
    int? tvEpisodesIdentified,
    int? needsVerification,
    String? currentFile,
    bool? isComplete,
    String? error,
  }) {
    return ScanProgress(
      storageId: storageId,
      storageName: storageName,
      filesDiscovered: filesDiscovered ?? this.filesDiscovered,
      moviesIdentified: moviesIdentified ?? this.moviesIdentified,
      tvEpisodesIdentified: tvEpisodesIdentified ?? this.tvEpisodesIdentified,
      needsVerification: needsVerification ?? this.needsVerification,
      currentFile: currentFile ?? this.currentFile,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }
}

/// Final summary of an incremental scan operation.
class ScanSummary {
  final String storageId;
  final String storageName;
  final int filesDiscovered;
  final int newSourcesAdded;
  final int sourcesRestored;
  final int sourcesMarkedMissing;
  final int moviesIdentified;
  final int tvEpisodesIdentified;
  final int needsVerification;
  final Duration duration;

  const ScanSummary({
    required this.storageId,
    required this.storageName,
    required this.filesDiscovered,
    required this.newSourcesAdded,
    required this.sourcesRestored,
    required this.sourcesMarkedMissing,
    required this.moviesIdentified,
    required this.tvEpisodesIdentified,
    required this.needsVerification,
    required this.duration,
  });

  @override
  String toString() =>
      'ScanSummary($storageName: $filesDiscovered files found, $newSourcesAdded added, $sourcesRestored restored, $sourcesMarkedMissing missing, duration: ${duration.inMilliseconds}ms)';
}

/// Incremental library scanning and media source registration service.
///
/// Implements Sections 10, 11, 12, 43, 45, and 46 of the design specification:
/// - Discovers media files without blocking the UI.
/// - Performs incremental synchronization against existing records.
/// - Preserves separation between logical entities (Movie/TvShow) and physical MediaSources.
/// - Marks missing physical files as unavailable without deleting the cinema catalogue item.
/// - Reconnects previously missing files when they reappear.
class LibraryScannerService {
  final AppDatabase database;
  final StorageIdentityService storageIdentityService;
  final MediaScanner mediaScanner;
  final Uuid _uuid;

  LibraryScannerService({
    required this.database,
    required this.storageIdentityService,
    this.mediaScanner = const MediaScanner(),
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  static String _normalizeRelPath(String path) {
    return path.replaceAll('\\', '/').trim();
  }

  /// Performs an incremental scan of the given [storage].
  Future<ScanSummary> scanStorage(
    Storage storage, {
    void Function(ScanProgress progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();

    var progress = ScanProgress(
      storageId: storage.id,
      storageName: storage.name,
    );
    onProgress?.call(progress);

    // 1. Verify storage connectivity
    final isConnected = await storageIdentityService.isStorageConnected(
      storage.rootUri,
    );
    if (!isConnected) {
      // Disk is not connected: mark storage and its sources unavailable
      await database.updateStorageStatus(
        storage.id,
        available: false,
        lastSeenAt: now,
      );
      await database.setAllSourcesAvailableForStorage(storage.id, false);

      final errorProgress = progress.copyWith(
        isComplete: true,
        error: 'Storage location is not connected or accessible.',
      );
      onProgress?.call(errorProgress);

      return ScanSummary(
        storageId: storage.id,
        storageName: storage.name,
        filesDiscovered: 0,
        newSourcesAdded: 0,
        sourcesRestored: 0,
        sourcesMarkedMissing: 0,
        moviesIdentified: 0,
        tvEpisodesIdentified: 0,
        needsVerification: 0,
        duration: stopwatch.elapsed,
      );
    }

    // 2. Load existing media sources for this storage
    final existingSources = await database.getSourcesForStorage(storage.id);
    final existingByPath = <String, MediaSource>{
      for (final s in existingSources) _normalizeRelPath(s.relativePath): s,
    };

    // 3. Scan files recursively
    final discoveredItems = <DiscoveredMediaFile>[];
    final discoveredPathSet = <String>{};

    var filesDiscovered = 0;
    var moviesIdentified = 0;
    var tvEpisodesIdentified = 0;
    var needsVerification = 0;

    await for (final file in mediaScanner.scanStream(
      rootPath: storage.rootUri,
      onProgress: (currentPath, count) {
        // High-frequency directory traversal progress
      },
    )) {
      filesDiscovered++;
      final normPath = _normalizeRelPath(file.relativePath);
      discoveredPathSet.add(normPath);
      discoveredItems.add(file);

      if (file.parsedInfo.isMovie) {
        moviesIdentified++;
      } else if (file.parsedInfo.isTvEpisode) {
        tvEpisodesIdentified++;
      } else {
        needsVerification++;
      }

      progress = progress.copyWith(
        filesDiscovered: filesDiscovered,
        moviesIdentified: moviesIdentified,
        tvEpisodesIdentified: tvEpisodesIdentified,
        needsVerification: needsVerification,
        currentFile: file.parsedInfo.rawFilename,
      );
      onProgress?.call(progress);
    }

    // 4. Incremental Database Synchronization
    var newSourcesAdded = 0;
    var sourcesRestored = 0;
    var sourcesMarkedMissing = 0;

    for (final item in discoveredItems) {
      final normPath = _normalizeRelPath(item.relativePath);
      final existing = existingByPath[normPath];

      if (existing != null) {
        // File was previously indexed
        if (!existing.available) {
          // Reconnected / restored file!
          await database.updateSourceAvailability(
            existing.id,
            available: true,
            lastSeenAt: now,
          );
          sourcesRestored++;
        } else {
          // Update lastSeenAt
          await database.updateSourceAvailability(
            existing.id,
            available: true,
            lastSeenAt: now,
          );
        }
      } else {
        // NEW FILE DISCOVERED!
        newSourcesAdded++;

        if (item.parsedInfo.isTvEpisode) {
          await _registerTvEpisodeSource(
            storage: storage,
            item: item,
            normPath: normPath,
            timestamp: now,
          );
        } else {
          // Default to Movie
          await _registerMovieSource(
            storage: storage,
            item: item,
            normPath: normPath,
            timestamp: now,
          );
        }
      }
    }

    // 5. Handle missing / deleted files on connected disk
    for (final existing in existingSources) {
      final normPath = _normalizeRelPath(existing.relativePath);
      if (!discoveredPathSet.contains(normPath)) {
        if (existing.available) {
          // Missing file on a connected disk: mark unavailable (NEVER delete library entity!)
          await database.updateSourceAvailability(
            existing.id,
            available: false,
            lastSeenAt: now,
          );
          sourcesMarkedMissing++;
        }
      }
    }

    // 6. Update storage status to active
    await database.updateStorageStatus(
      storage.id,
      available: true,
      lastSeenAt: now,
    );

    stopwatch.stop();

    final finalProgress = progress.copyWith(
      isComplete: true,
      currentFile: null,
    );
    onProgress?.call(finalProgress);

    return ScanSummary(
      storageId: storage.id,
      storageName: storage.name,
      filesDiscovered: filesDiscovered,
      newSourcesAdded: newSourcesAdded,
      sourcesRestored: sourcesRestored,
      sourcesMarkedMissing: sourcesMarkedMissing,
      moviesIdentified: moviesIdentified,
      tvEpisodesIdentified: tvEpisodesIdentified,
      needsVerification: needsVerification,
      duration: stopwatch.elapsed,
    );
  }

  Future<void> _registerMovieSource({
    required Storage storage,
    required DiscoveredMediaFile item,
    required String normPath,
    required DateTime timestamp,
  }) async {
    final parsed = item.parsedInfo;

    // Check if logical Movie already exists (by discovery identity: detectedTitle and detectedYear)
    final existingMovie = await database.findMovieByDetectedTitleAndYear(
      parsed.title,
      parsed.year,
    );

    String movieId;
    if (existingMovie != null) {
      movieId = existingMovie.id;
    } else {
      // Create new logical Movie record with discovery hints (pending canonical identification)
      movieId = _uuid.v4();
      await database
          .into(database.movies)
          .insert(
            MoviesCompanion.insert(
              id: movieId,
              detectedTitle: parsed.title,
              detectedYear: parsed.year != null
                  ? Value(parsed.year)
                  : const Value.absent(),
              identificationStatus: const Value('PENDING'),
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );
    }

    // Insert physical MediaSource record
    final sourceType = storage.storageType == 'DEVICE_LOCAL_STORAGE'
        ? 'localDevice'
        : 'removableStorage';

    await database
        .into(database.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: _uuid.v4(),
            movieId: Value(movieId),
            storageId: storage.id,
            sourceType: sourceType,
            relativePath: normPath,
            filename: parsed.rawFilename,
            extension: parsed.extension,
            fileSize: BigInt.from(item.fileSize),
            videoCodec: parsed.videoCodec != null
                ? Value(parsed.videoCodec)
                : const Value.absent(),
            audioCodec: parsed.audioCodec != null
                ? Value(parsed.audioCodec)
                : const Value.absent(),
            resolution: parsed.resolution != null
                ? Value(parsed.resolution)
                : const Value.absent(),
            audioChannels: parsed.audioChannels != null
                ? Value(parsed.audioChannels)
                : const Value.absent(),
            createdAt: timestamp,
            firstSeenAt: timestamp,
            lastSeenAt: timestamp,
            available: const Value(true),
          ),
        );
  }

  Future<void> _registerTvEpisodeSource({
    required Storage storage,
    required DiscoveredMediaFile item,
    required String normPath,
    required DateTime timestamp,
  }) async {
    final parsed = item.parsedInfo;

    // 1. Find or create TvShow (by discovery identity: detectedTitle)
    final existingShow = await database.findTvShowByDetectedTitle(parsed.title);
    String showId;
    if (existingShow != null) {
      showId = existingShow.id;
    } else {
      // Create new logical TvShow record with discovery hints (pending canonical identification)
      showId = _uuid.v4();
      await database
          .into(database.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: showId,
              detectedTitle: parsed.title,
              identificationStatus: const Value('PENDING'),
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );
    }

    // 2. Find or create Season
    final seasonNum = parsed.seasonNumber ?? 1;
    final existingSeason = await database.findSeason(showId, seasonNum);
    String seasonId;
    if (existingSeason != null) {
      seasonId = existingSeason.id;
    } else {
      seasonId = _uuid.v4();
      await database
          .into(database.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: seasonId,
              showId: showId,
              seasonNumber: seasonNum,
            ),
          );
    }

    // 3. Find or create Episode
    final epNum = parsed.episodeNumber ?? 1;
    final existingEpisode = await database.findEpisode(seasonId, epNum);
    String episodeId;
    if (existingEpisode != null) {
      episodeId = existingEpisode.id;
    } else {
      episodeId = _uuid.v4();
      await database
          .into(database.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: episodeId,
              seasonId: seasonId,
              episodeNumber: epNum,
              name: parsed.episodeTitle != null
                  ? Value(parsed.episodeTitle)
                  : const Value.absent(),
            ),
          );
    }

    // 4. Insert physical MediaSource record
    final sourceType = storage.storageType == 'DEVICE_LOCAL_STORAGE'
        ? 'localDevice'
        : 'removableStorage';

    await database
        .into(database.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: _uuid.v4(),
            episodeId: Value(episodeId),
            storageId: storage.id,
            sourceType: sourceType,
            relativePath: normPath,
            filename: parsed.rawFilename,
            extension: parsed.extension,
            fileSize: BigInt.from(item.fileSize),
            videoCodec: parsed.videoCodec != null
                ? Value(parsed.videoCodec)
                : const Value.absent(),
            audioCodec: parsed.audioCodec != null
                ? Value(parsed.audioCodec)
                : const Value.absent(),
            resolution: parsed.resolution != null
                ? Value(parsed.resolution)
                : const Value.absent(),
            audioChannels: parsed.audioChannels != null
                ? Value(parsed.audioChannels)
                : const Value.absent(),
            createdAt: timestamp,
            firstSeenAt: timestamp,
            lastSeenAt: timestamp,
            available: const Value(true),
          ),
        );
  }
}
