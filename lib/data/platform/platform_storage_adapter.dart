/// Platform-neutral contract for physical storage operations.
///
/// Hides the divergence between standard filesystem paths on Windows/Desktop
/// and DocumentTree / Content URIs on Android.
abstract class PlatformStorageAdapter {
  /// Checks whether the storage location is currently mounted and accessible.
  Future<bool> isStorageConnected(String rootUri);

  /// Obtains the persistent hardware or volume identifier (e.g. Win32 Volume Serial or Android Volume UUID).
  Future<String?> getFilesystemIdentifier(String rootUri);

  /// Obtains the human-readable volume label or directory display name.
  Future<String> getStorageDisplayName(String rootUri);

  /// Obtains available free storage bytes at the storage location.
  Future<int> getAvailableBytes(String rootUri);

  /// Obtains total storage capacity in bytes at the storage location.
  Future<int> getTotalBytes(String rootUri);

  /// Checks if a file exists relative to the storage root.
  Future<bool> fileExists(String rootUri, String relativePath);

  /// Gets the file size in bytes for a file relative to the storage root.
  Future<int> getFileSizeBytes(String rootUri, String relativePath);

  /// Resolves the URI or path string suitable for external player launching.
  Future<String> resolvePlaybackUri(String rootUri, String relativePath);
}
