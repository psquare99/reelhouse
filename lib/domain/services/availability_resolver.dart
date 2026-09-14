import '../models/availability_status.dart';

/// Represents a source check tuple used for availability and playback resolution.
class SourceCheckInfo {
  final String sourceId;
  final String sourceType; // 'removableStorage' or 'localDevice'
  final bool isSourceAvailable; // Physical file check or source availability
  final String storageId;
  final String storageName;
  final bool isStorageConnected;

  const SourceCheckInfo({
    required this.sourceId,
    required this.sourceType,
    required this.isSourceAvailable,
    required this.storageId,
    required this.storageName,
    required this.isStorageConnected,
  });

  bool get isEffectivelyAvailable {
    if (sourceType == 'localDevice') {
      return isSourceAvailable;
    }
    return isSourceAvailable && isStorageConnected;
  }
}

/// Dynamic resolver that computes an item's [AvailabilityStatus] from its physical sources.
class AvailabilityResolver {
  const AvailabilityResolver();

  AvailabilityStatus resolve(List<SourceCheckInfo> sources) {
    if (sources.isEmpty) {
      return AvailabilityStatus.unavailable;
    }

    final hasLocal = sources.any(
      (s) => s.sourceType == 'localDevice' && s.isSourceAvailable,
    );
    final hasRemovable = sources.any(
      (s) => s.sourceType == 'removableStorage' && s.isEffectivelyAvailable,
    );

    if (hasLocal && hasRemovable) {
      return AvailabilityStatus.availableOnMultipleSources;
    } else if (hasLocal) {
      return AvailabilityStatus.availableLocally;
    } else if (hasRemovable) {
      return AvailabilityStatus.availableOnRemovableStorage;
    } else {
      return AvailabilityStatus.unavailable;
    }
  }
}
