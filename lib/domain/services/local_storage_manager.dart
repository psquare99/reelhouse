/// Abstract contract for managing REELHOUSE application-managed offline media storage.
///
/// Hides platform filesystem and app directory differences (e.g. `getExternalFilesDir`
/// on Android vs AppData / Application Support on Desktop).
abstract class LocalStorageManager {
  /// Returns the absolute path to the application-managed offline media directory.
  Future<String> getLocalMediaDirectoryPath();

  /// Returns the available free space on the host device storage in bytes.
  Future<int> getAvailableDeviceStorageBytes();

  /// Returns the total bytes consumed by REELHOUSE offline media on this device.
  Future<int> getUsedOfflineStorageBytes();

  /// Resolves the absolute local path for a given relative media path.
  Future<String> resolveLocalPath(String relativePath);

  /// Checks whether a local copy exists and matches its expected file size in bytes.
  Future<bool> verifyLocalCopyIntegrity(String relativePath, int expectedBytes);

  /// Deletes a local offline copy from the application-managed storage.
  ///
  /// Must NEVER delete the original HDD file or logical cinema library entity.
  Future<bool> deleteLocalCopy(String relativePath);
}
