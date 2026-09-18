import '../models/device_storage_destination.dart';

/// Abstract service contract for managing REELHOUSE application-managed device storage.
///
/// Implements M5.1 Device Storage Foundation:
/// - Provides a dedicated boundary for discovering and resolving the device storage destination.
/// - Distinguishes between registered + accessible, registered + inaccessible, and not registered states.
/// - Queries platform capacity (available and total bytes).
/// - Enforces that an inaccessible destination does not invalidate its persistent registration.
/// - Ensures that application-managed device storage remains distinct from user-managed external media.
abstract class DeviceStorageService {
  /// Resolves the current application-managed device destination.
  ///
  /// Evaluates persistent registration in the database and verifies real-time filesystem accessibility.
  /// Distinguishes between:
  /// - [DeviceStorageResolutionStatus.registeredAndAccessible]
  /// - [DeviceStorageResolutionStatus.registeredAndInaccessible]
  /// - [DeviceStorageResolutionStatus.notRegistered]
  Future<DeviceStorageResolution> resolveDestination();

  /// Ensures that the default REELHOUSE-managed device destination is registered persistently.
  ///
  /// If already registered, returns the resolved destination. If not, establishes the default
  /// platform-appropriate directory, ensures it exists on disk, and records it in the database.
  Future<DeviceStorageDestination> ensureDefaultDestinationRegistered();

  /// Explicitly registers or updates an application-managed device storage destination.
  ///
  /// [rootPath] must be a legitimate local directory path.
  /// [name] is an optional custom display name (defaults to 'This Device').
  /// [id] is an optional storage ID (defaults to 'local-device').
  /// [createDirectory] whether to attempt creating the directory if missing (defaults to false).
  Future<DeviceStorageDestination> registerDestination({
    required String rootPath,
    String? name,
    String? id,
    bool createDirectory = false,
  });

  /// Queries the physical storage capacity (total and available bytes) of a given storage root.
  Future<StorageCapacity?> getDestinationCapacity(String rootPath);

  /// Checks whether a given storage root directory exists and is accessible.
  Future<bool> isDestinationAccessible(String rootPath);

  /// Resolves the absolute local path for a given relative media path within the active destination.
  Future<String> resolveMediaFilePath(String relativePath);
}
