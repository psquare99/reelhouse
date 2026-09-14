/// Lifecycle state of an offline media transfer operation.
///
/// Transfers are explicitly separated from [MediaSource]. Only when a transfer
/// transitions to [completed] is a corresponding local [MediaSource] registered.
enum TransferJobStatus {
  /// Transfer is waiting in queue to begin.
  queued,

  /// File data is actively streaming from source to local device storage.
  downloading,

  /// Transfer has been temporarily paused by user or system.
  paused,

  /// Transfer has completed and passed post-transfer integrity checks.
  completed,

  /// Transfer encountered an error (insufficient space, read error, disconnected disk).
  failed,

  /// Transfer was aborted by user; partial temporary files cleaned up.
  cancelled;

  static TransferJobStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'QUEUED':
        return TransferJobStatus.queued;
      case 'DOWNLOADING':
        return TransferJobStatus.downloading;
      case 'PAUSED':
        return TransferJobStatus.paused;
      case 'COMPLETED':
        return TransferJobStatus.completed;
      case 'FAILED':
        return TransferJobStatus.failed;
      case 'CANCELLED':
        return TransferJobStatus.cancelled;
      default:
        return TransferJobStatus.queued;
    }
  }

  String toDbString() => name.toUpperCase();

  bool get isActive =>
      this == TransferJobStatus.queued || this == TransferJobStatus.downloading;
}
