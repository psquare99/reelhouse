import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../data/database/database.dart';
import '../models/transfer_models.dart';
import 'device_storage_service.dart';
import 'storage_identity_service.dart';
import 'transfer_service.dart';

/// Request queued for sequential transfer processing.
class _QueuedTransfer {
  final String mediaId;
  final TransferScope scope;
  final Completer<dynamic> completer;
  final Future<dynamic> future;
  final CancellationToken cancellationToken;

  _QueuedTransfer({
    required this.mediaId,
    required this.scope,
    required this.completer,
    required this.future,
    required this.cancellationToken,
  });
}

/// Orchestrates user-facing offline transfer requests, sequential queuing,
/// automatic MediaSource registration, cooperative cancellation, and diagnostics.
///
/// Follows M5.5 specifications:
/// - One active file transfer at a time.
/// - Duplicate request protection.
/// - Automatic registration of finalized transfers as playable MediaSources.
/// - Human-readable error translation.
/// - Startup recovery integration.
class TransferCoordinator extends ChangeNotifier {
  final TransferService transferService;
  final AppDatabase database;
  final DeviceStorageService deviceStorageService;
  final StorageIdentityService? storageIdentityService;

  final List<_QueuedTransfer> _queue = [];
  _QueuedTransfer? _currentTransfer;
  bool _isProcessing = false;
  bool _isDisposed = false;
  StreamSubscription<TransferProgress>? _progressSubscription;

  TransferCoordinator({
    required this.transferService,
    required this.database,
    required this.deviceStorageService,
    this.storageIdentityService,
  }) {
    _progressSubscription = transferService.progressStream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  /// Active transfer queue length (excluding current active transfer).
  int get queuedCount => _queue.length;

  /// Currently executing transfer request, if any.
  String? get activeMediaId => _currentTransfer?.mediaId;

  /// Stream of transfer progress events from underlying [TransferService].
  Stream<TransferProgress> get progressStream => transferService.progressStream;

  /// Initializes transfer coordinator, reconciling interrupted jobs and cleaning stale partials.
  Future<void> initialize() async {
    try {
      await transferService.reconcileTransfers();
      await transferService.cleanStalePartials();
    } catch (e) {
      debugPrint(
        'TransferCoordinator initialization reconciliation notice: $e',
      );
    }
  }

  /// Checks if a media item is actively transferring or waiting in the queue.
  bool isMediaActiveOrQueued(String mediaId) {
    if (_currentTransfer?.mediaId == mediaId) return true;
    if (_queue.any((q) => q.mediaId == mediaId)) return true;
    return transferService.isMediaTransferring(mediaId);
  }

  /// Returns current active progress for a media item.
  TransferProgress? getActiveProgress(String mediaId) {
    return transferService.getActiveProgress(mediaId);
  }

  /// Requests copying a single movie to application-managed device storage.
  Future<TransferResult> requestMovieTransfer(String movieId) {
    return _enqueueTransfer<TransferResult>(
      mediaId: movieId,
      scope: TransferScope.movie,
    );
  }

  /// Requests copying a single TV episode to application-managed device storage.
  Future<TransferResult> requestEpisodeTransfer(String episodeId) {
    return _enqueueTransfer<TransferResult>(
      mediaId: episodeId,
      scope: TransferScope.episode,
    );
  }

  /// Requests copying all canonical episodes of a TV season to application-managed device storage.
  Future<List<TransferResult>> requestSeasonTransfer(String seasonId) {
    return _enqueueTransfer<List<TransferResult>>(
      mediaId: seasonId,
      scope: TransferScope.season,
    );
  }

  /// Cancels an ongoing or queued transfer for a specific media item.
  Future<bool> cancelMediaTransfer(String mediaId) async {
    // 1. If in queue (not started yet)
    final queueIndex = _queue.indexWhere((q) => q.mediaId == mediaId);
    if (queueIndex != -1) {
      final queued = _queue.removeAt(queueIndex);
      queued.cancellationToken.cancel('Cancelled while queued.');
      if (!queued.completer.isCompleted) {
        if (queued.scope == TransferScope.season) {
          queued.completer.complete(<TransferResult>[]);
        } else {
          queued.completer.complete(
            TransferResult(
              transferId: 'queued_${queued.mediaId}',
              scope: queued.scope,
              mediaId: queued.mediaId,
              state: TransferState.cancelled,
              bytesTransferred: 0,
              totalBytes: 0,
              error: 'Transfer cancelled before starting.',
            ),
          );
        }
      }
      notifyListeners();
      return true;
    }

    // 2. If actively transferring
    if (_currentTransfer?.mediaId == mediaId) {
      _currentTransfer!.cancellationToken.cancel('User cancelled transfer.');
    }

    return transferService.cancelTransfer(mediaId);
  }

  /// Retries a previously failed transfer job.
  Future<dynamic> retryTransferJob(TransferJob job) async {
    if (job.mediaType == 'movie') {
      return requestMovieTransfer(job.mediaId);
    } else if (job.mediaType == 'episode') {
      return requestEpisodeTransfer(job.mediaId);
    }
    return null;
  }

  /// Deletes a device-local MediaSource and its physical file on disk.
  ///
  /// Preserves the original external HDD MediaSource, logical media item, and watch history.
  Future<void> deleteOfflineCopy(String mediaSourceId) async {
    final source = await database.getMediaSourceById(mediaSourceId);
    if (source == null) return;
    if (source.sourceType != 'localDevice') {
      throw TransferException(
        'Cannot delete non-device copy (sourceId: $mediaSourceId)',
        mediaId: source.movieId ?? source.episodeId,
      );
    }

    // 1. Resolve storage root and safely remove file
    final storage = await database.getStorageById(source.storageId);
    if (storage != null && storage.rootUri.isNotEmpty) {
      final fullPath = p.normalize(
        p.join(storage.rootUri, source.relativePath),
      );
      final file = File(fullPath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }

    // 2. Remove MediaSource row from database
    await database.deleteMediaSource(mediaSourceId);
    notifyListeners();
  }

  /// Clean stale temporary files in application-managed device storage.
  Future<int> cleanStalePartials() async {
    final count = await transferService.cleanStalePartials();
    notifyListeners();
    return count;
  }

  /// Reconcile interrupted transfers.
  Future<List<TransferResult>> reconcileTransfers() async {
    final results = await transferService.reconcileTransfers();
    notifyListeners();
    return results;
  }

  /// Converts internal technical error strings into user-friendly explanations.
  static String formatError(Object? rawError) {
    if (rawError == null) {
      return "Couldn't save offline. An unknown error occurred.";
    }

    final errString = rawError is TransferException
        ? rawError.message
        : rawError.toString();
    if (errString.isEmpty) {
      return "Couldn't save offline. An unknown error occurred.";
    }

    final lower = errString.toLowerCase();
    if (lower.contains('insufficient') ||
        lower.contains('not enough space') ||
        lower.contains('capacity')) {
      return "Couldn't save offline. There isn't enough free space on this device.";
    }
    if (lower.contains('not connected') ||
        lower.contains('disconnected') ||
        lower.contains('no readable source') ||
        lower.contains('no available source')) {
      return "Couldn't save offline. The original source drive is not connected.";
    }
    if (lower.contains('destination storage') ||
        lower.contains('destination root') ||
        lower.contains('inaccessible')) {
      return "Couldn't save offline. Device storage directory is inaccessible.";
    }
    if (lower.contains('cancelled') || lower.contains('canceled')) {
      return 'Transfer was cancelled.';
    }
    if (lower.contains('duplicate')) {
      return 'A transfer is already active or queued for this title.';
    }

    return 'Couldn\'t save offline: $rawError';
  }

  Future<T> _enqueueTransfer<T>({
    required String mediaId,
    required TransferScope scope,
  }) {
    // Duplicate request protection
    if (_currentTransfer?.mediaId == mediaId) {
      return _currentTransfer!.future as Future<T>;
    }
    final existing = _queue.where((q) => q.mediaId == mediaId).firstOrNull;
    if (existing != null) {
      return existing.future as Future<T>;
    }

    final completer = Completer<T>();
    final cancellationToken = CancellationToken();

    final queued = _QueuedTransfer(
      mediaId: mediaId,
      scope: scope,
      completer: completer,
      future: completer.future,
      cancellationToken: cancellationToken,
    );

    _queue.add(queued);
    notifyListeners();

    _processQueue();

    return completer.future;
  }

  void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final item = _queue.removeAt(0);
      _currentTransfer = item;
      notifyListeners();

      try {
        if (item.cancellationToken.isCancelled) {
          if (!item.completer.isCompleted) {
            if (item.scope == TransferScope.season) {
              item.completer.complete(<TransferResult>[]);
            } else {
              item.completer.complete(
                TransferResult(
                  transferId: 'queued_${item.mediaId}',
                  scope: item.scope,
                  mediaId: item.mediaId,
                  state: TransferState.cancelled,
                  bytesTransferred: 0,
                  totalBytes: 0,
                ),
              );
            }
          }
          continue;
        }

        if (item.scope == TransferScope.movie) {
          final result = await transferService.transferMovie(
            item.mediaId,
            cancellationToken: item.cancellationToken,
          );
          if (result.state == TransferState.completed) {
            await transferService.registerCompletedTransfer(result.transferId);
          }
          if (!item.completer.isCompleted) {
            item.completer.complete(result);
          }
        } else if (item.scope == TransferScope.episode) {
          final result = await transferService.transferEpisode(
            item.mediaId,
            cancellationToken: item.cancellationToken,
          );
          if (result.state == TransferState.completed) {
            await transferService.registerCompletedTransfer(result.transferId);
          }
          if (!item.completer.isCompleted) {
            item.completer.complete(result);
          }
        } else if (item.scope == TransferScope.season) {
          final results = await transferService.transferSeason(
            item.mediaId,
            cancellationToken: item.cancellationToken,
          );
          await transferService.registerCompletedSeasonTransfers(item.mediaId);
          if (!item.completer.isCompleted) {
            item.completer.complete(results);
          }
        }
      } catch (e, st) {
        debugPrint('Transfer execution exception: $e\n$st');
        if (!item.completer.isCompleted) {
          item.completer.completeError(e, st);
        }
      } finally {
        _currentTransfer = null;
        notifyListeners();
      }
    }

    _isProcessing = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _progressSubscription?.cancel();
    super.dispose();
  }
}
