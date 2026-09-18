/// Scope of an offline media transfer operation.
enum TransferScope {
  /// Single movie transfer.
  movie,

  /// Single TV episode transfer.
  episode,

  /// Entire TV season batch transfer (transfers canonical episodes).
  season;

  String toDbString() => name.toUpperCase();

  static TransferScope fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MOVIE':
        return TransferScope.movie;
      case 'EPISODE':
        return TransferScope.episode;
      case 'SEASON':
        return TransferScope.season;
      default:
        return TransferScope.movie;
    }
  }
}

/// Lifecycle states of a media transfer operation defined in the M5 specification.
///
/// Flow:
/// QUEUED -> PREPARING -> TRANSFERRING -> VERIFYING -> COMPLETED
///    |          |             |             |
///    +--------> CANCELLED     +-> FAILED    +-> FAILED
enum TransferState {
  /// Transfer request has been accepted and queued.
  queued,

  /// Validating source availability, destination capacity, and paths.
  preparing,

  /// Actively streaming bytes from source file to temporary destination file.
  transferring,

  /// Post-transfer file integrity and consistency checks (owned by M5.3).
  verifying,

  /// Verified and finalized; ready for MediaSource registration (M5.3/M5.4).
  completed,

  /// Encountered an unrecoverable error (I/O error, source disconnect, insufficient space).
  failed,

  /// Cooperatively aborted by the user or system before completion.
  cancelled;

  String toDbString() {
    switch (this) {
      case TransferState.queued:
        return 'QUEUED';
      case TransferState.preparing:
        return 'PREPARING';
      case TransferState.transferring:
        return 'TRANSFERRING';
      case TransferState.verifying:
        return 'VERIFYING';
      case TransferState.completed:
        return 'COMPLETED';
      case TransferState.failed:
        return 'FAILED';
      case TransferState.cancelled:
        return 'CANCELLED';
    }
  }

  static TransferState fromString(String value) {
    switch (value.toUpperCase()) {
      case 'QUEUED':
        return TransferState.queued;
      case 'PREPARING':
        return TransferState.preparing;
      case 'TRANSFERRING':
      case 'DOWNLOADING':
        return TransferState.transferring;
      case 'VERIFYING':
        return TransferState.verifying;
      case 'COMPLETED':
        return TransferState.completed;
      case 'FAILED':
        return TransferState.failed;
      case 'CANCELLED':
        return TransferState.cancelled;
      default:
        return TransferState.queued;
    }
  }

  /// Whether this state is terminal (non-active).
  bool get isTerminal =>
      this == TransferState.completed ||
      this == TransferState.failed ||
      this == TransferState.cancelled;

  /// Whether this transfer is actively in-flight or preparing.
  bool get isActive => !isTerminal;
}

/// Token used to cooperatively signal cancellation to an active transfer.
class CancellationToken {
  bool _isCancelled = false;
  String? _reason;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _isCancelled;
  String? get reason => _reason;

  /// Requests cancellation of the ongoing transfer operation.
  void cancel([String? reason]) {
    if (_isCancelled) return;
    _isCancelled = true;
    _reason = reason;
    for (final listener in List.of(_listeners)) {
      try {
        listener();
      } catch (_) {}
    }
  }

  /// Adds a listener to be notified when cancellation occurs.
  void addListener(void Function() listener) {
    if (_isCancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  /// Removes a cancellation listener.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }
}

/// Progress state emitted during a transfer operation.
class TransferProgress {
  /// Unique identifier of the transfer job.
  final String transferId;

  /// Scope of the transfer (movie, episode, season).
  final TransferScope scope;

  /// Logical media ID (movieId, episodeId, or seasonId).
  final String mediaId;

  /// Current lifecycle state of the transfer.
  final TransferState state;

  /// Number of bytes transferred so far.
  final int bytesTransferred;

  /// Total size in bytes to transfer.
  final int totalBytes;

  /// Display name of the item currently transferring.
  final String? currentItemName;

  /// 1-based index of current item in a batch (e.g. season transfer).
  final int currentItemIndex;

  /// Total number of items in a batch.
  final int totalItems;

  /// Error message if the transfer encountered a problem.
  final String? error;

  const TransferProgress({
    required this.transferId,
    required this.scope,
    required this.mediaId,
    required this.state,
    required this.bytesTransferred,
    required this.totalBytes,
    this.currentItemName,
    this.currentItemIndex = 1,
    this.totalItems = 1,
    this.error,
  });

  /// Fraction of completion between 0.0 and 1.0.
  double get fraction =>
      totalBytes > 0 ? (bytesTransferred / totalBytes).clamp(0.0, 1.0) : 0.0;

  /// Percentage integer between 0 and 100.
  int get percentage => (fraction * 100).toInt();

  @override
  String toString() =>
      'TransferProgress(id: $transferId, state: $state, $bytesTransferred / $totalBytes bytes ($percentage%))';
}

/// Final or intermediate result of a transfer operation.
class TransferResult {
  final String transferId;
  final TransferScope scope;
  final String mediaId;
  final TransferState state;
  final int bytesTransferred;
  final int totalBytes;
  final String? destinationPath;
  final String? temporaryPath;
  final String? error;

  const TransferResult({
    required this.transferId,
    required this.scope,
    required this.mediaId,
    required this.state,
    required this.bytesTransferred,
    required this.totalBytes,
    this.destinationPath,
    this.temporaryPath,
    this.error,
  });

  bool get isSuccess =>
      state == TransferState.completed || state == TransferState.transferring;
  bool get isCancelled => state == TransferState.cancelled;
  bool get isFailed => state == TransferState.failed;

  @override
  String toString() =>
      'TransferResult(id: $transferId, state: $state, bytes: $bytesTransferred/$totalBytes, dest: $destinationPath, temp: $temporaryPath, error: $error)';
}

/// Base exception for media transfer operations.
class TransferException implements Exception {
  final String message;
  final String? mediaId;
  final Object? cause;

  const TransferException(this.message, {this.mediaId, this.cause});

  @override
  String toString() => 'TransferException: $message';
}

/// Thrown when no connected or readable media source is found for the requested item.
class NoAvailableSourceException extends TransferException {
  const NoAvailableSourceException(super.message, {super.mediaId});
}

/// Thrown when host device storage has insufficient available space.
class InsufficientStorageException extends TransferException {
  final int requiredBytes;
  final int availableBytes;

  const InsufficientStorageException({
    required this.requiredBytes,
    required this.availableBytes,
    super.mediaId,
  }) : super(
         'Insufficient device storage: required $requiredBytes bytes, but only $availableBytes bytes available.',
       );
}

/// Thrown when a transfer for the same media item is already in progress.
class DuplicateTransferException extends TransferException {
  const DuplicateTransferException(super.message, {super.mediaId});
}

/// Thrown when a transfer is aborted via cancellation token.
class TransferCancelledException extends TransferException {
  const TransferCancelledException([super.message = 'Transfer was cancelled.']);
}

/// Thrown when the application-managed device storage destination is missing or inaccessible.
class DeviceStorageUnavailableException extends TransferException {
  const DeviceStorageUnavailableException(super.message);
}
