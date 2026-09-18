import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/services/local_storage_manager.dart';
import 'windows_storage_adapter.dart';

/// Implementation of [LocalStorageManager] managing application-managed offline media storage.
class LocalStorageManagerImpl implements LocalStorageManager {
  String? _cachedBasePath;

  @override
  Future<String> getLocalMediaDirectoryPath() async {
    if (_cachedBasePath != null) {
      return _cachedBasePath!;
    }

    Directory baseDir;
    try {
      if (Platform.isAndroid) {
        // On Android, use app-specific external files dir (no special permissions required)
        final externalDirs = await getExternalStorageDirectories();
        if (externalDirs != null && externalDirs.isNotEmpty) {
          baseDir = externalDirs.first;
        } else {
          baseDir = await getApplicationDocumentsDirectory();
        }
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final offlineDir = Directory(
      p.join(baseDir.path, 'reelhouse', 'offline_media'),
    );
    if (!offlineDir.existsSync()) {
      offlineDir.createSync(recursive: true);
    }

    _cachedBasePath = offlineDir.path;
    return _cachedBasePath!;
  }

  @override
  Future<int> getAvailableDeviceStorageBytes() async {
    try {
      final path = await getLocalMediaDirectoryPath();
      if (Platform.isWindows) {
        final adapter = WindowsStorageAdapter();
        return await adapter.getAvailableBytes(path);
      }
    } catch (_) {}
    return 64 * 1024 * 1024 * 1024;
  }

  @override
  Future<int> getTotalDeviceStorageBytes() async {
    try {
      final path = await getLocalMediaDirectoryPath();
      if (Platform.isWindows) {
        final adapter = WindowsStorageAdapter();
        return await adapter.getTotalBytes(path);
      }
    } catch (_) {}
    return 128 * 1024 * 1024 * 1024;
  }

  @override
  Future<int> getUsedOfflineStorageBytes() async {
    try {
      final dirPath = await getLocalMediaDirectoryPath();
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        return 0;
      }

      var total = 0;
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<String> resolveLocalPath(String relativePath) async {
    final base = await getLocalMediaDirectoryPath();
    return p.join(base, relativePath);
  }

  @override
  Future<bool> verifyLocalCopyIntegrity(
    String relativePath,
    int expectedBytes,
  ) async {
    try {
      final fullPath = await resolveLocalPath(relativePath);
      final file = File(fullPath);
      if (!file.existsSync()) {
        return false;
      }
      final length = await file.length();
      return length == expectedBytes;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteLocalCopy(String relativePath) async {
    try {
      final fullPath = await resolveLocalPath(relativePath);
      final file = File(fullPath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
