import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/models/transfer_models.dart';
import '../../domain/services/device_storage_service.dart';
import '../../domain/services/storage_identity_service.dart';
import '../../domain/services/transfer_service.dart';
import '../database/database.dart';

/// Resolved physical source candidate for an offline transfer.
class _ResolvedSource {
  final MediaSource mediaSource;
  final Storage storage;
  final String fullPath;
  final int fileSize;

  const _ResolvedSource({
    required this.mediaSource,
    required this.storage,
    required this.fullPath,
    required this.fileSize,
  });
}

/// Production implementation of [TransferService].
///
/// Implements M5.2 Transfer Engine:
/// - Supports movie, episode, and season transfers.
/// - Performs live source availability resolution (only selecting currently readable files).
/// - Validates destination capacity before initiating byte copy.
/// - Performs chunked/buffered streaming I/O to a safe temporary artifact (.reelhouse-partial).
/// - Exposes reactive stream and callback progress notifications.
/// - Supports cooperative cancellation and robust filesystem failure handling.
/// - Persists transfer jobs in SQLite across app lifecycles.
/// - Enforces duplicate transfer protection and strict destination root containment.
class TransferServiceImpl implements TransferService {
  final AppDatabase database;
  final DeviceStorageService deviceStorageService;
  final StorageIdentityService? storageIdentityService;
  final Uuid _uuid;

  final StreamController<TransferProgress> _progressController =
      StreamController<TransferProgress>.broadcast();

  /// Active transfer tokens keyed by media ID and transfer ID.
  final Map<String, CancellationToken> _activeTokens = {};

  /// Current active progress snapshots keyed by media ID.
  final Map<String, TransferProgress> _activeProgress = {};

  TransferServiceImpl({
    required this.database,
    required this.deviceStorageService,
    this.storageIdentityService,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Stream<TransferProgress> get progressStream => _progressController.stream;

  @override
  bool isMediaTransferring(String mediaId) {
    return _activeTokens.containsKey(mediaId);
  }

  @override
  TransferProgress? getActiveProgress(String mediaId) {
    return _activeProgress[mediaId];
  }

  @override
  Future<bool> cancelTransfer(String transferId) async {
    final token = _activeTokens[transferId];
    if (token != null && !token.isCancelled) {
      token.cancel('User requested transfer cancellation.');
      return true;
    }
    return false;
  }

  @override
  Future<TransferResult> transferMovie(
    String movieId, {
    CancellationToken? cancellationToken,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    return _executeSingleTransfer(
      mediaId: movieId,
      scope: TransferScope.movie,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
  }

  @override
  Future<TransferResult> transferEpisode(
    String episodeId, {
    CancellationToken? cancellationToken,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    return _executeSingleTransfer(
      mediaId: episodeId,
      scope: TransferScope.episode,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
  }

  @override
  Future<List<TransferResult>> transferSeason(
    String seasonId, {
    CancellationToken? cancellationToken,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    // 1. Guard against duplicate active season transfers
    if (isMediaTransferring(seasonId)) {
      throw DuplicateTransferException(
        'A transfer for season $seasonId is already in progress.',
        mediaId: seasonId,
      );
    }

    final token = cancellationToken ?? CancellationToken();
    _activeTokens[seasonId] = token;

    try {
      // 2. Fetch season and canonical episodes
      final season = await database.findSeasonById(seasonId);
      if (season == null) {
        throw TransferException(
          'Season $seasonId not found.',
          mediaId: seasonId,
        );
      }

      // Exclude TV Extras (Season -1)
      if (season.seasonNumber < 0) {
        throw TransferException(
          'TV Extras (Season ${season.seasonNumber}) cannot be transferred as a canonical season batch.',
          mediaId: seasonId,
        );
      }

      final allEpisodes = await database.getEpisodesForSeason(seasonId);
      if (allEpisodes.isEmpty) {
        throw TransferException(
          'Season $seasonId has no registered episodes to transfer.',
          mediaId: seasonId,
        );
      }

      // 3. Resolve sources and calculate required aggregate size upfront
      final resolvedItems = <_ResolvedSource>[];
      final episodeList = <Episode>[];
      var totalSeasonBytes = 0;

      for (final episode in allEpisodes) {
        final resolvedSource = await _resolveAvailableSource(
          mediaId: episode.id,
          isMovie: false,
        );
        resolvedItems.add(resolvedSource);
        episodeList.add(episode);
        totalSeasonBytes += resolvedSource.fileSize;
      }

      // 4. Pre-check destination capacity for entire season upfront
      final destinationResolution = await deviceStorageService
          .resolveDestination();
      if (!destinationResolution.isAccessible ||
          destinationResolution.destination == null) {
        throw const DeviceStorageUnavailableException(
          'Application-managed device storage destination is not registered or accessible.',
        );
      }

      final availableBytes =
          destinationResolution.destination!.availableBytes ?? 0;
      if (totalSeasonBytes > availableBytes) {
        throw InsufficientStorageException(
          requiredBytes: totalSeasonBytes,
          availableBytes: availableBytes,
          mediaId: seasonId,
        );
      }

      // 5. Transfer episodes sequentially
      final results = <TransferResult>[];
      var seasonBytesTransferred = 0;
      final totalEpisodes = episodeList.length;

      for (var i = 0; i < totalEpisodes; i++) {
        if (token.isCancelled) {
          break;
        }

        final episode = episodeList[i];
        final preResolvedSource = resolvedItems[i];
        final episodeTitle = episode.name != null && episode.name!.isNotEmpty
            ? 'S${season.seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')} — ${episode.name}'
            : 'S${season.seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')}';

        final result = await _executeSingleTransfer(
          mediaId: episode.id,
          scope: TransferScope.episode,
          cancellationToken: token,
          preResolvedSource: preResolvedSource,
          batchTotalBytes: totalSeasonBytes,
          batchBytesBase: seasonBytesTransferred,
          currentItemIndex: i + 1,
          totalItems: totalEpisodes,
          itemDisplayName: episodeTitle,
          onProgress: (itemProgress) {
            onProgress?.call(itemProgress);
          },
        );

        results.add(result);
        if (result.isCancelled || result.isFailed) {
          break;
        }
        seasonBytesTransferred += result.bytesTransferred;
      }

      return results;
    } finally {
      _activeTokens.remove(seasonId);
      _activeProgress.remove(seasonId);
    }
  }

  /// Internal worker executing a single item (movie or episode) transfer.
  Future<TransferResult> _executeSingleTransfer({
    required String mediaId,
    required TransferScope scope,
    CancellationToken? cancellationToken,
    _ResolvedSource? preResolvedSource,
    int? batchTotalBytes,
    int batchBytesBase = 0,
    int currentItemIndex = 1,
    int totalItems = 1,
    String? itemDisplayName,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    // 1. Guard against duplicate active transfer for this media
    if (isMediaTransferring(mediaId)) {
      throw DuplicateTransferException(
        'A transfer for $mediaId is already in progress.',
        mediaId: mediaId,
      );
    }

    final transferId = _uuid.v4();
    final token = cancellationToken ?? CancellationToken();

    _activeTokens[mediaId] = token;
    _activeTokens[transferId] = token;

    IOSink? targetSink;
    String? tempFilePath;
    String? targetFullPath;

    try {
      // 2. Resolve available physical source
      final resolved =
          preResolvedSource ??
          await _resolveAvailableSource(
            mediaId: mediaId,
            isMovie: scope == TransferScope.movie,
          );

      final sourceFile = File(resolved.fullPath);
      final sourceSize = resolved.fileSize;
      final effectiveTotalBytes = batchTotalBytes ?? sourceSize;

      // 3. Resolve destination root & capacity
      final destinationResolution = await deviceStorageService
          .resolveDestination();
      if (!destinationResolution.isAccessible ||
          destinationResolution.destination == null) {
        throw const DeviceStorageUnavailableException(
          'Application-managed device storage destination is not registered or accessible.',
        );
      }

      final destination = destinationResolution.destination!;
      final availableBytes = destination.availableBytes ?? 0;

      // Single item capacity pre-check (if not already verified in season batch)
      if (batchTotalBytes == null && sourceSize > availableBytes) {
        throw InsufficientStorageException(
          requiredBytes: sourceSize,
          availableBytes: availableBytes,
          mediaId: mediaId,
        );
      }

      // 4. Construct deterministic destination path & temporary file
      final destRelPath = await _constructDestinationRelativePath(
        mediaId: mediaId,
        scope: scope,
        source: resolved.mediaSource,
      );

      targetFullPath = _resolveSafeDestinationPath(
        destinationRoot: destination.rootPath,
        relativePath: destRelPath,
      );

      tempFilePath = '$targetFullPath.reelhouse-partial';

      // 5. Persist initial transfer record (QUEUED)
      final now = DateTime.now();
      await database.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: transferId,
          mediaType: scope == TransferScope.movie ? 'movie' : 'episode',
          mediaId: mediaId,
          sourceMediaSourceId: resolved.mediaSource.id,
          destinationStorageId: destination.id,
          destinationRelativePath: destRelPath,
          status: 'QUEUED',
          totalBytes: BigInt.from(sourceSize),
          bytesTransferred: Value(BigInt.zero),
          startedAt: now,
        ),
      );

      var progress = TransferProgress(
        transferId: transferId,
        scope: scope,
        mediaId: mediaId,
        state: TransferState.queued,
        bytesTransferred: batchBytesBase,
        totalBytes: effectiveTotalBytes,
        currentItemName: itemDisplayName ?? resolved.mediaSource.filename,
        currentItemIndex: currentItemIndex,
        totalItems: totalItems,
      );
      _emitProgress(progress, onProgress);

      // Check cancellation before preparing
      if (token.isCancelled) {
        return await _handleCancellation(
          transferId: transferId,
          scope: scope,
          mediaId: mediaId,
          bytesTransferred: 0,
          totalBytes: effectiveTotalBytes,
          tempPath: tempFilePath,
          destPath: targetFullPath,
          token: token,
          onProgress: onProgress,
        );
      }

      // 6. Transition to PREPARING
      await database.updateTransferJobProgress(transferId, status: 'PREPARING');

      progress = TransferProgress(
        transferId: transferId,
        scope: scope,
        mediaId: mediaId,
        state: TransferState.preparing,
        bytesTransferred: batchBytesBase,
        totalBytes: effectiveTotalBytes,
        currentItemName: itemDisplayName ?? resolved.mediaSource.filename,
        currentItemIndex: currentItemIndex,
        totalItems: totalItems,
      );
      _emitProgress(progress, onProgress);

      // Ensure destination directory exists
      final targetDir = Directory(p.dirname(tempFilePath));
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      // 7. Transition to TRANSFERRING
      await database.updateTransferJobProgress(
        transferId,
        status: 'TRANSFERRING',
      );

      final tempFile = File(tempFilePath);
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }

      final sourceStream = sourceFile.openRead();
      final sink = tempFile.openWrite();
      targetSink = sink;

      var bytesCopied = 0;
      var lastEmittedBytes = 0;
      var lastDbUpdateBytes = 0;
      final stopwatch = Stopwatch()..start();

      await for (final chunk in sourceStream) {
        if (token.isCancelled) {
          await sink.flush();
          await sink.close();
          targetSink = null;

          return await _handleCancellation(
            transferId: transferId,
            scope: scope,
            mediaId: mediaId,
            bytesTransferred: batchBytesBase + bytesCopied,
            totalBytes: effectiveTotalBytes,
            tempPath: tempFilePath,
            destPath: targetFullPath,
            token: token,
            onProgress: onProgress,
          );
        }

        sink.add(chunk);
        bytesCopied += chunk.length;

        final currentTotalBytes = batchBytesBase + bytesCopied;

        // Progress notification throttling (every 1MB, or 100ms, or when complete)
        if (bytesCopied - lastEmittedBytes >= 1024 * 1024 ||
            stopwatch.elapsedMilliseconds >= 100 ||
            bytesCopied == sourceSize) {
          lastEmittedBytes = bytesCopied;
          stopwatch.reset();

          progress = TransferProgress(
            transferId: transferId,
            scope: scope,
            mediaId: mediaId,
            state: TransferState.transferring,
            bytesTransferred: currentTotalBytes,
            totalBytes: effectiveTotalBytes,
            currentItemName: itemDisplayName ?? resolved.mediaSource.filename,
            currentItemIndex: currentItemIndex,
            totalItems: totalItems,
          );
          _emitProgress(progress, onProgress);

          // Database throttling (every 10MB)
          if (bytesCopied - lastDbUpdateBytes >= 10 * 1024 * 1024) {
            lastDbUpdateBytes = bytesCopied;
            await database.updateTransferJobProgress(
              transferId,
              status: 'TRANSFERRING',
              bytesTransferred: bytesCopied,
            );
          }
        }
      }

      await sink.flush();
      await sink.close();
      targetSink = null;

      // 8. Byte copy complete (M5.2 boundary)
      // M5.2 leaves the temporary artifact (.reelhouse-partial) unverified on disk.
      // M5.3 will perform verification and atomic finalization.
      await database.updateTransferJobProgress(
        transferId,
        status: 'TRANSFERRING',
        bytesTransferred: bytesCopied,
      );

      final finalProgress = TransferProgress(
        transferId: transferId,
        scope: scope,
        mediaId: mediaId,
        state: TransferState.transferring,
        bytesTransferred: batchBytesBase + bytesCopied,
        totalBytes: effectiveTotalBytes,
        currentItemName: itemDisplayName ?? resolved.mediaSource.filename,
        currentItemIndex: currentItemIndex,
        totalItems: totalItems,
      );
      _emitProgress(finalProgress, onProgress);

      return TransferResult(
        transferId: transferId,
        scope: scope,
        mediaId: mediaId,
        state: TransferState.transferring,
        bytesTransferred: bytesCopied,
        totalBytes: sourceSize,
        destinationPath: targetFullPath,
        temporaryPath: tempFilePath,
      );
    } catch (e) {
      if (targetSink != null) {
        try {
          await targetSink.flush();
          await targetSink.close();
        } catch (_) {}
      }

      // Persist failure state
      await database.updateTransferJobProgress(
        transferId,
        status: 'FAILED',
        error: e.toString(),
        completedAt: DateTime.now(),
      );

      final failProgress = TransferProgress(
        transferId: transferId,
        scope: scope,
        mediaId: mediaId,
        state: TransferState.failed,
        bytesTransferred: batchBytesBase,
        totalBytes: batchTotalBytes ?? 0,
        currentItemName: itemDisplayName,
        currentItemIndex: currentItemIndex,
        totalItems: totalItems,
        error: e.toString(),
      );
      _emitProgress(failProgress, onProgress);

      if (e is TransferException) {
        rethrow;
      }
      throw TransferException(
        'Transfer failed for media $mediaId: $e',
        mediaId: mediaId,
        cause: e,
      );
    } finally {
      _activeTokens.remove(mediaId);
      _activeTokens.remove(transferId);
      _activeProgress.remove(mediaId);
    }
  }

  Future<TransferResult> _handleCancellation({
    required String transferId,
    required TransferScope scope,
    required String mediaId,
    required int bytesTransferred,
    required int totalBytes,
    required String tempPath,
    required String destPath,
    required CancellationToken token,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    final reason = token.reason ?? 'Transfer was cancelled.';
    await database.updateTransferJobProgress(
      transferId,
      status: 'CANCELLED',
      bytesTransferred: bytesTransferred,
      error: reason,
      completedAt: DateTime.now(),
    );

    final cancelledProgress = TransferProgress(
      transferId: transferId,
      scope: scope,
      mediaId: mediaId,
      state: TransferState.cancelled,
      bytesTransferred: bytesTransferred,
      totalBytes: totalBytes,
      error: reason,
    );
    _emitProgress(cancelledProgress, onProgress);

    return TransferResult(
      transferId: transferId,
      scope: scope,
      mediaId: mediaId,
      state: TransferState.cancelled,
      bytesTransferred: bytesTransferred,
      totalBytes: totalBytes,
      temporaryPath: tempPath,
      destinationPath: destPath,
      error: reason,
    );
  }

  void _emitProgress(
    TransferProgress progress,
    void Function(TransferProgress)? onProgress,
  ) {
    _activeProgress[progress.mediaId] = progress;
    _progressController.add(progress);
    onProgress?.call(progress);
  }

  /// Resolves the currently connected, valid, and readable physical [MediaSource] for a logical item.
  Future<_ResolvedSource> _resolveAvailableSource({
    required String mediaId,
    required bool isMovie,
  }) async {
    final sources = isMovie
        ? await database.getSourcesForMovie(mediaId)
        : await database.getSourcesForEpisode(mediaId);

    if (sources.isEmpty) {
      throw NoAvailableSourceException(
        'No physical media sources registered for $mediaId.',
        mediaId: mediaId,
      );
    }

    // Inspect sources to find a currently connected and readable file
    for (final source in sources) {
      final storage = await database.getStorageById(source.storageId);
      if (storage == null) continue;

      final isConnected = storageIdentityService != null
          ? await storageIdentityService!.isStorageConnected(storage.rootUri)
          : storage.available;

      if (!isConnected || storage.rootUri.isEmpty) {
        continue;
      }

      final fullPath = p.normalize(
        p.join(storage.rootUri, source.relativePath),
      );
      try {
        final file = File(fullPath);
        if (file.existsSync()) {
          final length = await file.length();
          if (length > 0) {
            return _ResolvedSource(
              mediaSource: source,
              storage: storage,
              fullPath: fullPath,
              fileSize: length,
            );
          }
        }
      } catch (_) {
        // Continue searching other candidates
      }
    }

    throw NoAvailableSourceException(
      'None of the physical media sources for $mediaId are currently connected or accessible on the filesystem.',
      mediaId: mediaId,
    );
  }

  /// Constructs a deterministic relative destination path for a media item.
  Future<String> _constructDestinationRelativePath({
    required String mediaId,
    required TransferScope scope,
    required MediaSource source,
  }) async {
    final cleanFilename = _sanitizePathComponent(source.filename);

    if (scope == TransferScope.movie) {
      final movie = await database.findMovieById(mediaId);
      final title = movie?.title ?? movie?.detectedTitle ?? 'Movie';
      final year = movie?.year ?? movie?.detectedYear;
      final folderName = _sanitizePathComponent(
        year != null ? '$title ($year)' : title,
      );
      return p.join('movies', folderName, cleanFilename);
    } else {
      final episode = await database.findEpisodeById(mediaId);
      if (episode != null) {
        final season = await database.findSeasonById(episode.seasonId);
        final show = season != null
            ? await database.findTvShowById(season.showId)
            : null;

        final showTitle = _sanitizePathComponent(
          show?.title ?? show?.detectedTitle ?? 'TV Show',
        );
        final seasonFolder =
            'Season ${(season?.seasonNumber ?? 1).toString().padLeft(2, '0')}';
        return p.join('tv_shows', showTitle, seasonFolder, cleanFilename);
      }
      return p.join('episodes', cleanFilename);
    }
  }

  /// Resolves the absolute destination path and ensures containment within [destinationRoot] (preventing path traversal).
  String _resolveSafeDestinationPath({
    required String destinationRoot,
    required String relativePath,
  }) {
    final normalizedRel = p.normalize(relativePath).replaceAll('\\', '/');
    final segments = p
        .split(normalizedRel)
        .where((s) => s.isNotEmpty && s != '..')
        .toList();
    final safeRelPath = p.joinAll(segments);

    final resolved = p.normalize(p.join(destinationRoot, safeRelPath));
    final normalizedRoot = p.normalize(destinationRoot);

    if (!resolved.startsWith(normalizedRoot)) {
      throw TransferException(
        'Path traversal detected: destination path $resolved escapes root $normalizedRoot',
      );
    }

    return resolved;
  }

  /// Sanitizes filesystem path components, eliminating invalid characters.
  String _sanitizePathComponent(String input) {
    return input.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
  }

  void dispose() {
    for (final token in _activeTokens.values) {
      token.cancel('Service disposed.');
    }
    _activeTokens.clear();
    _activeProgress.clear();
    _progressController.close();
  }
}
