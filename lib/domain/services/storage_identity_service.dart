/// Contract for identifying and monitoring storage devices across platforms.
///
/// Hides platform-specific hardware identification:
/// - Windows: Win32 Volume Serial Number (`GetVolumeInformationW`) & GUID
/// - Android: `StorageVolume` filesystem UUID & DocumentTree URI
/// - Secondary Fallback: `.reelhouse_source` marker file
abstract class StorageIdentityService {
  /// Obtains a persistent hardware or filesystem identifier for the specified storage location.
  Future<String> getFilesystemIdentifier(String rootUriOrPath);

  /// Obtains the volume label or human-readable name for the storage device.
  Future<String> getStorageDisplayName(String rootUriOrPath);

  /// Checks whether the storage location is currently connected and accessible.
  Future<bool> isStorageConnected(String rootUriOrPath);

  /// Checks for or reads a secondary `.reelhouse_source` marker file on the volume.
  Future<String?> readMarkerIdentifier(String rootUriOrPath);

  /// Writes a secondary `.reelhouse_source` marker file to assist identification when hardware IDs fluctuate.
  Future<void> writeMarkerIdentifier(String rootUriOrPath, String storageId);
}
