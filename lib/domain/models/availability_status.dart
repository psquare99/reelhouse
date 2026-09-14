/// Represents the physical availability state of a logical media item in REELHOUSE.
///
/// Availability is source-aware and dynamically computed from all physical
/// [MediaSource] records associated with a Movie or TV Episode.
enum AvailabilityStatus {
  /// At least one physical copy is intact and available on the local device storage.
  availableLocally,

  /// At least one physical copy is present on a currently connected removable drive.
  availableOnRemovableStorage,

  /// Physical copies are available both locally on device and on connected removable storage.
  availableOnMultipleSources,

  /// All physical storage locations containing copies are currently disconnected or unavailable.
  unavailable;

  /// Whether the media item can currently be played without connecting external media.
  bool get isPlayable => this != AvailabilityStatus.unavailable;

  /// Human-readable label for cinematic cards and details.
  String get displayLabel {
    switch (this) {
      case AvailabilityStatus.availableLocally:
        return 'Available Offline';
      case AvailabilityStatus.availableOnRemovableStorage:
        return 'Available on Disk';
      case AvailabilityStatus.availableOnMultipleSources:
        return 'Available Locally & on Disk';
      case AvailabilityStatus.unavailable:
        return 'Unavailable';
    }
  }
}
