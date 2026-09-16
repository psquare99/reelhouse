/// Represents the user's consumption and playback state of a media item in REELHOUSE.
///
/// Section 18:
/// - UNWATCHED: Item has not been started.
/// - IN_PROGRESS: Item was started and has an active playback position, but has not completed.
/// - WATCHED: Item was watched to completion or marked as watched by the user.
enum WatchState {
  /// Item has not been started.
  unwatched,

  /// Item was started and has an active playback position, but has not completed.
  inProgress,

  /// Item was watched to completion or marked as watched by the user.
  watched;

  /// Parses a raw database/metadata string into a [WatchState].
  static WatchState fromString(String? value) {
    if (value == null) return WatchState.unwatched;
    switch (value.toUpperCase()) {
      case 'IN_PROGRESS':
        return WatchState.inProgress;
      case 'WATCHED':
        return WatchState.watched;
      case 'UNWATCHED':
      default:
        return WatchState.unwatched;
    }
  }

  /// Converts this [WatchState] to its canonical database storage string.
  String toDbString() {
    switch (this) {
      case WatchState.unwatched:
        return 'UNWATCHED';
      case WatchState.inProgress:
        return 'IN_PROGRESS';
      case WatchState.watched:
        return 'WATCHED';
    }
  }

  /// Human-readable label for UI display.
  String get displayLabel {
    switch (this) {
      case WatchState.unwatched:
        return 'Unwatched';
      case WatchState.inProgress:
        return 'In Progress';
      case WatchState.watched:
        return 'Watched';
    }
  }

  bool get isUnwatched => this == WatchState.unwatched;
  bool get isInProgress => this == WatchState.inProgress;
  bool get isWatched => this == WatchState.watched;
}
