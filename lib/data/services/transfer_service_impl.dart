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

      // Check if destination is already verified and finalized on disk
      final existingTarget = File(targetFullPath);
      if (existingTarget.existsSync() &&
          existingTarget.lengthSync() == sourceSize) {
        // Destination file is already present and valid. Avoid redundant copying.
        final tempFile = File(tempFilePath);
        if (tempFile.existsSync()) {
          try {
            tempFile.deleteSync();
          } catch (_) {}
        }

        final now = DateTime.now();
        await database.upsertTransferJob(
          TransferJobsCompanion.insert(
            id: transferId,
            mediaType: scope == TransferScope.movie ? 'movie' : 'episode',
            mediaId: mediaId,
            sourceMediaSourceId: resolved.mediaSource.id,
            destinationStorageId: destination.id,
            destinationRelativePath: destRelPath,
            status: 'COMPLETED',
            totalBytes: BigInt.from(sourceSize),
            bytesTransferred: Value(BigInt.from(sourceSize)),
            startedAt: now,
            completedAt: Value(now),
          ),
        );

        final completedProgress = TransferProgress(
          transferId: transferId,
          scope: scope,
          mediaId: mediaId,
          state: TransferState.completed,
          bytesTransferred: batchBytesBase + sourceSize,
          totalBytes: effectiveTotalBytes,
          currentItemName: itemDisplayName ?? resolved.mediaSource.filename,
          currentItemIndex: currentItemIndex,
          totalItems: totalItems,
        );
        _emitProgress(completedProgress, onProgress);

        return TransferResult(
          transferId: transferId,
          scope: scope,
          mediaId: mediaId,
          state: TransferState.completed,
          bytesTransferred: sourceSize,
          totalBytes: sourceSize,
          destinationPath: targetFullPath,
        );
      }

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

      // 8. Transition to VERIFYING (M5.3 Verification Boundary)
      await database.updateTransferJobProgress(
        transferId,
        status: 'VERIFYING',
        bytesTransferred: bytesCopied,
      );

      final verifyingProgress = TransferProgress(
        transferId: transferId,
        scope: scope,
        mediaId: mediaId,
        state: TransferState.verifying,
        bytesTransferred: batchBytesBase + bytesCopied,
        totalBytes: effectiveTotalBytes,
        currentItemName: itemDisplayName ?? resolved.mediaSource.filename,
        currentItemIndex: currentItemIndex,
        totalItems: totalItems,
      );
      _emitProgress(verifyingProgress, onProgress);

      if (token.isCancelled) {
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

      // 9. Verification & Atomic Finalization
      await _verifyAndFinalize(
        tempFilePath: tempFilePath,
        targetFullPath: targetFullPath,
        expectedBytes: sourceSize,
        mediaId: mediaId,
      );

      // 10. Transition to COMPLETED
      final completedAt = DateTime.now();
      await database.updateTransferJobProgress(
        transferId,
        status: 'COMPLETED',
        bytesTransferred: sourceSize,
        completedAt: completedAt,
      );

      final completedProgress = TransferProgress(
        transferId: transferId,
        scope: scope,
        mediaId: mediaId,
        state: TransferState.completed,
        bytesTransferred: batchBytesBase + sourceSize,
        totalBytes: effectiveTotalBytes,
        currentItemName: itemDisplayName ?? resolved.mediaSource.filename,
        currentItemIndex: currentItemIndex,
        totalItems: totalItems,
      );
      _emitProgress(completedProgress, onProgress);

      return TransferResult(
        transferId: transferId,
        scope: scope,
        mediaId: mediaId,
        state: TransferState.completed,
        bytesTransferred: sourceSize,
        totalBytes: sourceSize,
        destinationPath: targetFullPath,
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

  @override
  Future<List<TransferResult>> reconcileTransfers() async {
    final interruptedJobs = await database.getInterruptedTransferJobs();
    if (interruptedJobs.isEmpty) {
      return const [];
    }

    final results = <TransferResult>[];

    for (final job in interruptedJobs) {
      // If job is currently active in memory, skip reconciliation for this job
      if (isMediaTransferring(job.mediaId) || isMediaTransferring(job.id)) {
        continue;
      }

      final scope = TransferScope.fromString(job.mediaType);
      final expectedBytes = job.totalBytes.toInt();

      final storage = await database.getStorageById(job.destinationStorageId);
      if (storage == null || storage.rootUri.isEmpty) {
        final error =
            'Destination storage ${job.destinationStorageId} is missing or inaccessible.';
        await database.updateTransferJobProgress(
          job.id,
          status: 'FAILED',
          error: error,
          completedAt: DateTime.now(),
        );
        results.add(
          TransferResult(
            transferId: job.id,
            scope: scope,
            mediaId: job.mediaId,
            state: TransferState.failed,
            bytesTransferred: 0,
            totalBytes: expectedBytes,
            error: error,
          ),
        );
        continue;
      }

      final targetFullPath = _resolveSafeDestinationPath(
        destinationRoot: storage.rootUri,
        relativePath: job.destinationRelativePath,
      );
      final tempFilePath = '$targetFullPath.reelhouse-partial';

      final targetFile = File(targetFullPath);
      final tempFile = File(tempFilePath);

      // Case 1: Final destination file already exists and has the expected size
      if (targetFile.existsSync() && targetFile.lengthSync() == expectedBytes) {
        if (tempFile.existsSync()) {
          try {
            tempFile.deleteSync();
          } catch (_) {}
        }
        await database.updateTransferJobProgress(
          job.id,
          status: 'COMPLETED',
          bytesTransferred: expectedBytes,
          completedAt: DateTime.now(),
        );
        results.add(
          TransferResult(
            transferId: job.id,
            scope: scope,
            mediaId: job.mediaId,
            state: TransferState.completed,
            bytesTransferred: expectedBytes,
            totalBytes: expectedBytes,
            destinationPath: targetFullPath,
          ),
        );
        continue;
      }

      // Case 2: Job was interrupted in VERIFYING and partial file exists
      if (job.status == 'VERIFYING' && tempFile.existsSync()) {
        try {
          await _verifyAndFinalize(
            tempFilePath: tempFilePath,
            targetFullPath: targetFullPath,
            expectedBytes: expectedBytes,
            mediaId: job.mediaId,
          );

          await database.updateTransferJobProgress(
            job.id,
            status: 'COMPLETED',
            bytesTransferred: expectedBytes,
            completedAt: DateTime.now(),
          );
          results.add(
            TransferResult(
              transferId: job.id,
              scope: scope,
              mediaId: job.mediaId,
              state: TransferState.completed,
              bytesTransferred: expectedBytes,
              totalBytes: expectedBytes,
              destinationPath: targetFullPath,
            ),
          );
          continue;
        } catch (e) {
          if (tempFile.existsSync()) {
            try {
              tempFile.deleteSync();
            } catch (_) {}
          }
          final error = 'Recovery verification failed: $e';
          await database.updateTransferJobProgress(
            job.id,
            status: 'FAILED',
            error: error,
            completedAt: DateTime.now(),
          );
          results.add(
            TransferResult(
              transferId: job.id,
              scope: scope,
              mediaId: job.mediaId,
              state: TransferState.failed,
              bytesTransferred: 0,
              totalBytes: expectedBytes,
              error: error,
            ),
          );
          continue;
        }
      }

      // Case 3: Job was interrupted in TRANSFERRING, PREPARING, or QUEUED (or VERIFYING with missing partial)
      final bool hadPartial = tempFile.existsSync();
      if (hadPartial) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }

      final error = hadPartial
          ? 'Transfer was interrupted before completion.'
          : 'Transfer was interrupted and partial file is missing.';

      await database.updateTransferJobProgress(
        job.id,
        status: 'FAILED',
        error: error,
        completedAt: DateTime.now(),
      );

      results.add(
        TransferResult(
          transferId: job.id,
          scope: scope,
          mediaId: job.mediaId,
          state: TransferState.failed,
          bytesTransferred: 0,
          totalBytes: expectedBytes,
          error: error,
        ),
      );
    }

    return results;
  }

  @override
  Future<int> cleanStalePartials() async {
    final destinationResolution = await deviceStorageService
        .resolveDestination();
    if (!destinationResolution.isAccessible ||
        destinationResolution.destination == null) {
      return 0;
    }

    final rootDir = Directory(destinationResolution.destination!.rootPath);
    if (!rootDir.existsSync()) {
      return 0;
    }

    // Active relative paths in database (TRANSFERRING or VERIFYING)
    final activeJobs = await database.getInterruptedTransferJobs();
    final activeRelativePaths = activeJobs
        .map((j) => p.normalize(j.destinationRelativePath).toLowerCase())
        .toSet();

    var cleanedCount = 0;

    try {
      final entities = rootDir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.reelhouse-partial')) {
          final relPath = p.normalize(
            p.relative(entity.path, from: rootDir.path),
          );
          // Strip .reelhouse-partial suffix to compare against destinationRelativePath
          final baseRelPath = relPath.substring(
            0,
            relPath.length - '.reelhouse-partial'.length,
          );

          final isActiveInDb = activeRelativePaths.contains(
            baseRelPath.toLowerCase(),
          );
          final isActiveInMemory = _activeTokens.values.any(
            (t) => !t.isCancelled,
          );

          if (!isActiveInDb && !isActiveInMemory) {
            try {
              entity.deleteSync();
              cleanedCount++;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    return cleanedCount;
  }

  /// Verifies a partial transfer artifact and atomically finalizes it to [targetFullPath].
  Future<void> _verifyAndFinalize({
    required String tempFilePath,
    required String targetFullPath,
    required int expectedBytes,
    required String mediaId,
  }) async {
    final tempFile = File(tempFilePath);
    final targetFile = File(targetFullPath);

    // If partial file doesn't exist, check if target file is already finalized and valid
    if (!tempFile.existsSync()) {
      if (targetFile.existsSync()) {
        final targetLength = await targetFile.length();
        if (targetLength == expectedBytes) {
          // Destination file is already present, valid, and finalized
          return;
        }
        throw VerificationFailedException(
          'Partial file not found at $tempFilePath and existing destination has mismatched size $targetLength (expected $expectedBytes).',
          expectedBytes: expectedBytes,
          actualBytes: targetLength,
          mediaId: mediaId,
        );
      }
      throw VerificationFailedException(
        'Partial file not found at $tempFilePath.',
        expectedBytes: expectedBytes,
        actualBytes: 0,
        mediaId: mediaId,
      );
    }

    // 1. Verify existence & size
    final int actualBytes;
    try {
      actualBytes = await tempFile.length();
    } catch (e) {
      throw VerificationFailedException(
        'Unable to inspect partial file size at $tempFilePath: $e',
        expectedBytes: expectedBytes,
        actualBytes: 0,
        mediaId: mediaId,
      );
    }

    if (actualBytes < expectedBytes) {
      throw VerificationFailedException(
        'Partial file size ($actualBytes bytes) is smaller than expected ($expectedBytes bytes).',
        expectedBytes: expectedBytes,
        actualBytes: actualBytes,
        mediaId: mediaId,
      );
    }

    if (actualBytes > expectedBytes) {
      throw VerificationFailedException(
        'Partial file size ($actualBytes bytes) is larger than expected ($expectedBytes bytes).',
        expectedBytes: expectedBytes,
        actualBytes: actualBytes,
        mediaId: mediaId,
      );
    }

    // 2. Verify file readability (sample read)
    try {
      final raf = await tempFile.open(mode: FileMode.read);
      try {
        if (actualBytes > 0) {
          final sampleLength = actualBytes < 1024 ? actualBytes : 1024;
          final sample = await raf.read(sampleLength);
          if (sample.length != sampleLength) {
            throw const FileSystemException(
              'Short read during verification sampling.',
            );
          }
        }
      } finally {
        await raf.close();
      }
    } catch (e) {
      throw VerificationFailedException(
        'Partial file at $tempFilePath is unreadable: $e',
        expectedBytes: expectedBytes,
        actualBytes: actualBytes,
        mediaId: mediaId,
      );
    }

    // 3. Atomic Finalization
    final parentDir = targetFile.parent;
    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }

    // Collision handling
    if (targetFile.existsSync()) {
      final targetLength = await targetFile.length();
      if (targetLength == expectedBytes) {
        // Target file already exists with identical valid size
        try {
          await tempFile.delete();
        } catch (_) {}
        return;
      }
      // Target file exists but has mismatched size / is stale. Remove before atomic rename.
      try {
        await targetFile.delete();
      } catch (_) {}
    }

    // Atomically rename partial to target destination
    try {
      await tempFile.rename(targetFullPath);
    } catch (e) {
      throw TransferException(
        'Failed to atomically finalize transfer destination from $tempFilePath to $targetFullPath: $e',
        mediaId: mediaId,
        cause: e,
      );
    }
  }

  @override
  Future<MediaSource> registerCompletedTransfer(String transferId) async {
    // 1. Fetch transfer job
    final job = await database.getTransferJobById(transferId);
    if (job == null) {
      throw TransferException(
        'Transfer job $transferId not found.',
        mediaId: null,
      );
    }

    // 2. Validate transfer state is strictly COMPLETED
    if (job.status != 'COMPLETED') {
      throw TransferException(
        'Transfer job $transferId is in state ${job.status}, not COMPLETED. Only verified and finalized transfers can be registered as MediaSources.',
        mediaId: job.mediaId,
      );
    }

    // 3. Lookup destination storage
    final storage = await database.getStorageById(job.destinationStorageId);
    if (storage == null || storage.rootUri.isEmpty) {
      throw TransferException(
        'Destination storage ${job.destinationStorageId} is missing or inaccessible.',
        mediaId: job.mediaId,
      );
    }

    // 4. Construct and validate finalized destination path (ensure not partial)
    final normRelPath = p
        .normalize(job.destinationRelativePath)
        .replaceAll('\\', '/');
    if (normRelPath.endsWith('.reelhouse-partial')) {
      throw TransferException(
        'Cannot register unfinalized temporary partial artifact $normRelPath as a MediaSource.',
        mediaId: job.mediaId,
      );
    }

    final fullPath = _resolveSafeDestinationPath(
      destinationRoot: storage.rootUri,
      relativePath: normRelPath,
    );
    final finalFile = File(fullPath);
    if (!finalFile.existsSync()) {
      throw TransferException(
        'Final destination file does not exist at $fullPath.',
        mediaId: job.mediaId,
      );
    }

    // 5. Verify logical media item existence
    if (job.mediaType == 'movie') {
      final movie = await database.findMovieById(job.mediaId);
      if (movie == null) {
        throw TransferException(
          'Logical movie ${job.mediaId} not found in library.',
          mediaId: job.mediaId,
        );
      }
    } else {
      final episode = await database.findEpisodeById(job.mediaId);
      if (episode == null) {
        throw TransferException(
          'Logical episode ${job.mediaId} not found in library.',
          mediaId: job.mediaId,
        );
      }
    }

    // 6. Idempotency & Collision check
    final existingSource = await database.findMediaSourceByStorageAndPath(
      storage.id,
      normRelPath,
    );

    if (existingSource != null) {
      if (job.mediaType == 'movie' && existingSource.movieId == job.mediaId) {
        return existingSource;
      }
      if (job.mediaType == 'episode' &&
          existingSource.episodeId == job.mediaId) {
        return existingSource;
      }
      throw TransferException(
        'MediaSource collision: Path $normRelPath on storage ${storage.id} is already registered to a different media item (movie: ${existingSource.movieId}, episode: ${existingSource.episodeId}).',
        mediaId: job.mediaId,
      );
    }

    // 7. Inherit metadata from original source if available
    final origSource = await database.getMediaSourceById(
      job.sourceMediaSourceId,
    );
    final filename = p.basename(normRelPath);
    final extension = p.extension(normRelPath).replaceAll('.', '');
    final fileSize = finalFile.lengthSync();
    final now = DateTime.now();
    final newSourceId = _uuid.v4();

    final companion = MediaSourcesCompanion.insert(
      id: newSourceId,
      movieId: job.mediaType == 'movie'
          ? Value(job.mediaId)
          : const Value.absent(),
      episodeId: job.mediaType == 'episode'
          ? Value(job.mediaId)
          : const Value.absent(),
      storageId: storage.id,
      sourceType: 'localDevice',
      relativePath: normRelPath,
      filename: filename,
      extension: extension,
      fileSize: BigInt.from(fileSize),
      videoCodec: origSource?.videoCodec != null
          ? Value(origSource!.videoCodec)
          : const Value.absent(),
      audioCodec: origSource?.audioCodec != null
          ? Value(origSource!.audioCodec)
          : const Value.absent(),
      resolution: origSource?.resolution != null
          ? Value(origSource!.resolution)
          : const Value.absent(),
      audioChannels: origSource?.audioChannels != null
          ? Value(origSource!.audioChannels)
          : const Value.absent(),
      subtitleInformation: origSource?.subtitleInformation != null
          ? Value(origSource!.subtitleInformation)
          : const Value.absent(),
      fingerprint: origSource?.fingerprint != null
          ? Value(origSource!.fingerprint)
          : const Value.absent(),
      duration: origSource?.duration != null
          ? Value(origSource!.duration)
          : const Value.absent(),
      createdAt: now,
      firstSeenAt: now,
      lastSeenAt: now,
      available: const Value(true),
    );

    await database.insertMediaSource(companion);
    return (await database.getMediaSourceById(newSourceId))!;
  }

  @override
  Future<List<MediaSource>> registerCompletedSeasonTransfers(
    String seasonId,
  ) async {
    final season = await database.findSeasonById(seasonId);
    if (season == null) {
      throw TransferException('Season $seasonId not found.', mediaId: seasonId);
    }

    if (season.seasonNumber < 0) {
      throw TransferException(
        'TV Extras (Season ${season.seasonNumber}) are excluded from canonical season transfers.',
        mediaId: seasonId,
      );
    }

    final allEpisodes = await database.getEpisodesForSeason(seasonId);
    final results = <MediaSource>[];

    for (final ep in allEpisodes) {
      final jobs = await database.getTransferJobsForMedia(ep.id);
      final completedJob = jobs
          .where((j) => j.status == 'COMPLETED')
          .lastOrNull;
      if (completedJob != null) {
        final registered = await registerCompletedTransfer(completedJob.id);
        results.add(registered);
      }
    }

    return results;
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
