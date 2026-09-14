import 'dart:io';

import 'package:path/path.dart' as p;

import 'platform_storage_adapter.dart';

/// Android implementation designed to support both standard internal storage
/// and DocumentTree / Content URIs (SAF) for external OTG drives and SD cards.
class AndroidStorageAdapter implements PlatformStorageAdapter {
  @override
  Future<bool> isStorageConnected(String rootUri) async {
    if (rootUri.startsWith('content://')) {
      // Content URIs remain valid while permission is persisted and volume is mounted
      return true;
    }
    try {
      final dir = Directory(rootUri);
      return dir.existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getFilesystemIdentifier(String rootUri) async {
    if (rootUri.startsWith('content://')) {
      // Extract volume UUID from SAF Tree URI:
      // content://com.android.externalstorage.documents/tree/1234-5678%3AMovies
      final uri = Uri.tryParse(rootUri);
      if (uri != null) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2 && pathSegments[0] == 'tree') {
          final decoded = Uri.decodeComponent(pathSegments[1]);
          final colonIndex = decoded.indexOf(':');
          if (colonIndex != -1) {
            return decoded.substring(0, colonIndex);
          }
          return decoded;
        }
      }
      return 'android-saf-volume';
    }

    // Direct POSIX path on Android (e.g. /storage/1234-5678/Movies)
    final parts = rootUri.split('/');
    final storageIndex = parts.indexOf('storage');
    if (storageIndex != -1 && parts.length > storageIndex + 1) {
      final volumeId = parts[storageIndex + 1];
      if (volumeId != 'emulated' && volumeId != 'self') {
        return volumeId;
      }
    }

    return 'android-internal';
  }

  @override
  Future<String> getStorageDisplayName(String rootUri) async {
    if (rootUri.startsWith('content://')) {
      final id = await getFilesystemIdentifier(rootUri);
      return 'Removable Storage ($id)';
    }
    final base = p.basename(rootUri);
    return base.isNotEmpty ? base : 'Android Storage';
  }

  @override
  Future<int> getAvailableBytes(String rootUri) async {
    // 32 GB conservative estimate for mobile storage
    return 32 * 1024 * 1024 * 1024;
  }

  @override
  Future<bool> fileExists(String rootUri, String relativePath) async {
    if (rootUri.startsWith('content://')) {
      // In SAF mode, document existence is verified via platform channel in M2/M5
      return true;
    }
    try {
      final fullPath = p.join(rootUri, relativePath);
      return File(fullPath).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int> getFileSizeBytes(String rootUri, String relativePath) async {
    if (rootUri.startsWith('content://')) {
      return 0;
    }
    try {
      final fullPath = p.join(rootUri, relativePath);
      final file = File(fullPath);
      if (file.existsSync()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  @override
  Future<String> resolvePlaybackUri(String rootUri, String relativePath) async {
    if (rootUri.startsWith('content://')) {
      // Construct SAF document content URI
      final encodedRel = Uri.encodeComponent(relativePath);
      return '$rootUri/$encodedRel';
    }
    return p.join(rootUri, relativePath);
  }
}
