/// Physical storage capacity information for a storage location or volume.
class StorageCapacity {
  /// Total storage capacity of the volume in bytes.
  final int totalBytes;

  /// Available free storage capacity on the volume in bytes.
  final int availableBytes;

  const StorageCapacity({
    required this.totalBytes,
    required this.availableBytes,
  });

  /// Bytes currently consumed on the volume.
  int get usedBytes => (totalBytes - availableBytes).clamp(0, totalBytes);

  /// Proportion of storage currently used (0.0 to 1.0).
  double get usedFraction =>
      totalBytes > 0 ? (usedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  @override
  String toString() =>
      'StorageCapacity(total: $totalBytes, available: $availableBytes, used: $usedBytes)';
}

/// Representation of an application-managed local device storage destination.
///
/// Corresponds to Section 5 of the M5 specification:
/// - Has a stable storage identity (e.g. 'local-device').
/// - Has a human-readable display name (e.g. 'This Device').
/// - Has a physical root directory path managed by MATINEE.
/// - Exposes total and available capacity where supported by the platform.
/// - Exposes connectivity/accessibility state.
/// - Is explicitly marked as application-managed ([isApplicationManaged] == true).
class DeviceStorageDestination {
  /// Stable unique identifier for this storage record in MATINEE (e.g. 'local-device').
  final String id;

  /// Human-readable display label (e.g. 'This Device').
  final String name;

  /// Physical filesystem root directory where application-managed media is stored.
  final String rootPath;

  /// Hardware or platform filesystem identifier (e.g. 'internal-app-storage' or volume ID).
  final String filesystemIdentifier;

  /// Total storage capacity of the hosting volume in bytes, if available.
  final int? totalBytes;

  /// Available free storage capacity on the hosting volume in bytes, if available.
  final int? availableBytes;

  /// Whether the destination directory / hosting volume is currently accessible.
  final bool isAccessible;

  /// Always true for MATINEE-managed device destinations, distinguishing them from user-managed external disks.
  final bool isApplicationManaged;

  /// Timestamp when the storage destination was last verified or seen.
  final DateTime lastSeenAt;

  const DeviceStorageDestination({
    required this.id,
    required this.name,
    required this.rootPath,
    required this.filesystemIdentifier,
    this.totalBytes,
    this.availableBytes,
    required this.isAccessible,
    this.isApplicationManaged = true,
    required this.lastSeenAt,
  });

  /// Copies this destination with updated fields.
  DeviceStorageDestination copyWith({
    String? id,
    String? name,
    String? rootPath,
    String? filesystemIdentifier,
    int? totalBytes,
    int? availableBytes,
    bool? isAccessible,
    bool? isApplicationManaged,
    DateTime? lastSeenAt,
  }) {
    return DeviceStorageDestination(
      id: id ?? this.id,
      name: name ?? this.name,
      rootPath: rootPath ?? this.rootPath,
      filesystemIdentifier: filesystemIdentifier ?? this.filesystemIdentifier,
      totalBytes: totalBytes ?? this.totalBytes,
      availableBytes: availableBytes ?? this.availableBytes,
      isAccessible: isAccessible ?? this.isAccessible,
      isApplicationManaged: isApplicationManaged ?? this.isApplicationManaged,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  String toString() =>
      'DeviceStorageDestination(id: $id, name: $name, rootPath: $rootPath, accessible: $isAccessible, free: $availableBytes, total: $totalBytes)';
}

/// Status of resolving the application-managed device storage destination.
enum DeviceStorageResolutionStatus {
  /// The destination is registered in MATINEE and is currently accessible on the filesystem.
  registeredAndAccessible,

  /// The destination is registered in MATINEE but is currently inaccessible (e.g. missing directory, unmounted volume, permission failure).
  ///
  /// Important invariant: An inaccessible destination is NEVER treated as deleted.
  registeredAndInaccessible,

  /// No application-managed device storage destination has been registered in MATINEE.
  notRegistered,
}

/// Result of resolving the application-managed device storage destination.
class DeviceStorageResolution {
  /// The resolution status.
  final DeviceStorageResolutionStatus status;

  /// The resolved destination details, populated when registered.
  final DeviceStorageDestination? destination;

  /// Optional contextual message or error description.
  final String? message;

  const DeviceStorageResolution({
    required this.status,
    this.destination,
    this.message,
  });

  /// Factory for a registered and accessible destination.
  factory DeviceStorageResolution.registeredAndAccessible(
    DeviceStorageDestination destination,
  ) {
    return DeviceStorageResolution(
      status: DeviceStorageResolutionStatus.registeredAndAccessible,
      destination: destination,
    );
  }

  /// Factory for a registered but currently inaccessible destination.
  factory DeviceStorageResolution.registeredAndInaccessible(
    DeviceStorageDestination destination, {
    String? message,
  }) {
    return DeviceStorageResolution(
      status: DeviceStorageResolutionStatus.registeredAndInaccessible,
      destination: destination,
      message: message,
    );
  }

  /// Factory when no device destination is registered.
  factory DeviceStorageResolution.notRegistered({String? message}) {
    return DeviceStorageResolution(
      status: DeviceStorageResolutionStatus.notRegistered,
      message: message,
    );
  }

  /// Whether a destination is registered in the database (even if currently inaccessible).
  bool get isRegistered =>
      status != DeviceStorageResolutionStatus.notRegistered;

  /// Whether the destination is registered and ready for read/write operations.
  bool get isAccessible =>
      status == DeviceStorageResolutionStatus.registeredAndAccessible;

  @override
  String toString() =>
      'DeviceStorageResolution(status: $status, destination: $destination, message: $message)';
}
