import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/services/storage_identity_service.dart';
import 'android_storage_adapter.dart';
import 'platform_storage_adapter.dart';
import 'windows_storage_adapter.dart';

/// Fallback platform adapter for Web and unsupported environments.
class GenericStorageAdapter implements PlatformStorageAdapter {
  @override
  Future<bool> isStorageConnected(String rootUri) async => true;

  @override
  Future<String?> getFilesystemIdentifier(String rootUri) async =>
      'generic-storage';

  @override
  Future<String> getStorageDisplayName(String rootUri) async =>
      p.basename(rootUri);

  @override
  Future<int> getAvailableBytes(String rootUri) async =>
      50 * 1024 * 1024 * 1024;

  @override
  Future<int> getTotalBytes(String rootUri) async => 100 * 1024 * 1024 * 1024;

  @override
  Future<bool> fileExists(String rootUri, String relativePath) async => true;

  @override
  Future<int> getFileSizeBytes(String rootUri, String relativePath) async => 0;

  @override
  Future<String> resolvePlaybackUri(
    String rootUri,
    String relativePath,
  ) async => '$rootUri/$relativePath';
}

/// Production implementation of [StorageIdentityService].
class StorageIdentityServiceImpl implements StorageIdentityService {
  final PlatformStorageAdapter _adapter;

  StorageIdentityServiceImpl([PlatformStorageAdapter? adapter])
    : _adapter = adapter ?? _createPlatformAdapter();

  static PlatformStorageAdapter _createPlatformAdapter() {
    try {
      if (Platform.isWindows) {
        return WindowsStorageAdapter();
      } else if (Platform.isAndroid) {
        return AndroidStorageAdapter();
      }
    } catch (_) {
      // Platform check may throw on Web
    }
    return GenericStorageAdapter();
  }

  static const String markerFileName = '.reelhouse_source';

  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async {
    // 1. Try hardware filesystem identifier from platform adapter
    final hardwareId = await _adapter.getFilesystemIdentifier(rootUriOrPath);
    if (hardwareId != null && hardwareId.isNotEmpty) {
      return hardwareId;
    }

    // 2. Check for existing .reelhouse_source marker file
    final markerId = await readMarkerIdentifier(rootUriOrPath);
    if (markerId != null && markerId.isNotEmpty) {
      return markerId;
    }

    // 3. Fallback: normalize path
    return rootUriOrPath.hashCode.toRadixString(16);
  }

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async {
    return _adapter.getStorageDisplayName(rootUriOrPath);
  }

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async {
    return _adapter.isStorageConnected(rootUriOrPath);
  }

  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async {
    if (rootUriOrPath.startsWith('content://')) {
      return null;
    }
    try {
      final marker = File(p.join(rootUriOrPath, markerFileName));
      if (marker.existsSync()) {
        final content = await marker.readAsString();
        final trimmed = content.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {
    if (rootUriOrPath.startsWith('content://')) {
      return;
    }
    try {
      final marker = File(p.join(rootUriOrPath, markerFileName));
      await marker.writeAsString(storageId);
    } catch (_) {}
  }
}
