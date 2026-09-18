import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/device_storage_destination.dart';
import '../../domain/services/device_storage_service.dart';
import '../../domain/services/local_storage_manager.dart';
import '../database/database.dart';
import 'android_storage_adapter.dart';
import 'platform_storage_adapter.dart';
import 'storage_identity_service_impl.dart';
import 'windows_storage_adapter.dart';

/// Production implementation of [DeviceStorageService].
///
/// Implements M5.1 Device Storage Foundation:
/// - Manages persistent registration and resolution of REELHOUSE application-managed device storage.
/// - Distinguishes between registered + accessible, registered + inaccessible, and not registered.
/// - Queries platform capacity (available and total bytes).
/// - Enforces persistent identity across application restarts.
/// - Ensures that an inaccessible destination does not invalidate or erase its persistent registration.
class DeviceStorageServiceImpl implements DeviceStorageService {
  final AppDatabase database;
  final LocalStorageManager localStorageManager;
  final PlatformStorageAdapter _adapter;

  DeviceStorageServiceImpl({
    required this.database,
    required this.localStorageManager,
    PlatformStorageAdapter? adapter,
  }) : _adapter = adapter ?? _createPlatformAdapter();

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

  @override
  Future<DeviceStorageResolution> resolveDestination() async {
    final storageRecord = await database.getDeviceStorage();

    if (storageRecord == null) {
      return DeviceStorageResolution.notRegistered(
        message:
            'No application-managed device storage destination is registered.',
      );
    }

    var effectivePath = storageRecord.rootUri.trim();
    if (effectivePath.isEmpty) {
      // If rootUri is uninitialized in the database record, resolve default and update
      effectivePath = await localStorageManager.getLocalMediaDirectoryPath();
      await database.updateStorageRootUri(storageRecord.id, effectivePath);
    }

    final isAccessible = await isDestinationAccessible(effectivePath);
    final now = DateTime.now();

    // Query platform storage capacity
    final capacity = await getDestinationCapacity(effectivePath);

    final destination = DeviceStorageDestination(
      id: storageRecord.id,
      name: storageRecord.name,
      rootPath: effectivePath,
      filesystemIdentifier: storageRecord.filesystemIdentifier,
      totalBytes: capacity?.totalBytes,
      availableBytes: capacity?.availableBytes,
      isAccessible: isAccessible,
      isApplicationManaged: true,
      lastSeenAt: now,
    );

    if (isAccessible) {
      if (!storageRecord.available) {
        await database.updateStorageStatus(
          storageRecord.id,
          available: true,
          lastSeenAt: now,
        );
      }
      return DeviceStorageResolution.registeredAndAccessible(destination);
    } else {
      if (storageRecord.available) {
        // Mark unavailable in database without deleting or invalidating the record
        await database.updateStorageStatus(
          storageRecord.id,
          available: false,
          lastSeenAt: now,
        );
      }
      return DeviceStorageResolution.registeredAndInaccessible(
        destination,
        message: 'Device storage directory is not currently accessible on the host filesystem.',
      );
    }
  }

  @override
  Future<DeviceStorageDestination> ensureDefaultDestinationRegistered() async {
    final existing = await database.getDeviceStorage();
    final now = DateTime.now();

    if (existing != null) {
      var rootPath = existing.rootUri.trim();
      if (rootPath.isEmpty) {
        rootPath = await localStorageManager.getLocalMediaDirectoryPath();
        await database.updateStorageRootUri(existing.id, rootPath);
      }

      final isAccessible = await isDestinationAccessible(rootPath);
      final capacity = await getDestinationCapacity(rootPath);

      return DeviceStorageDestination(
        id: existing.id,
        name: existing.name,
        rootPath: rootPath,
        filesystemIdentifier: existing.filesystemIdentifier,
        totalBytes: capacity?.totalBytes,
        availableBytes: capacity?.availableBytes,
        isAccessible: isAccessible,
        isApplicationManaged: true,
        lastSeenAt: now,
      );
    }

    // Default initialization
    final defaultPath = await localStorageManager.getLocalMediaDirectoryPath();
    final dir = Directory(defaultPath);
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
      } catch (_) {}
    }

    final isAccessible = dir.existsSync();
    final fsId =
        await _adapter.getFilesystemIdentifier(defaultPath) ??
        'internal-app-storage';

    final companion = StoragesCompanion.insert(
      id: 'local-device',
      name: 'This Device',
      storageType: 'DEVICE_LOCAL_STORAGE',
      filesystemIdentifier: fsId,
      rootUri: defaultPath,
      lastSeenAt: now,
      available: Value(isAccessible),
    );

    await database.upsertStorage(companion);

    final capacity = await getDestinationCapacity(defaultPath);

    return DeviceStorageDestination(
      id: 'local-device',
      name: 'This Device',
      rootPath: defaultPath,
      filesystemIdentifier: fsId,
      totalBytes: capacity?.totalBytes,
      availableBytes: capacity?.availableBytes,
      isAccessible: isAccessible,
      isApplicationManaged: true,
      lastSeenAt: now,
    );
  }

  @override
  Future<DeviceStorageDestination> registerDestination({
    required String rootPath,
    String? name,
    String? id,
    bool createDirectory = false,
  }) async {
    final storageId = id ?? 'local-device';
    final displayName = name ?? 'This Device';
    final now = DateTime.now();

    final dir = Directory(rootPath);
    if (createDirectory && !dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
      } catch (_) {}
    }

    final isAccessible = dir.existsSync();
    final fsId =
        await _adapter.getFilesystemIdentifier(rootPath) ??
        'internal-app-storage';

    final companion = StoragesCompanion.insert(
      id: storageId,
      name: displayName,
      storageType: 'DEVICE_LOCAL_STORAGE',
      filesystemIdentifier: fsId,
      rootUri: rootPath,
      lastSeenAt: now,
      available: Value(isAccessible),
    );

    await database.upsertStorage(companion);

    final capacity = await getDestinationCapacity(rootPath);

    return DeviceStorageDestination(
      id: storageId,
      name: displayName,
      rootPath: rootPath,
      filesystemIdentifier: fsId,
      totalBytes: capacity?.totalBytes,
      availableBytes: capacity?.availableBytes,
      isAccessible: isAccessible,
      isApplicationManaged: true,
      lastSeenAt: now,
    );
  }

  @override
  Future<StorageCapacity?> getDestinationCapacity(String rootPath) async {
    try {
      final avail = await _adapter.getAvailableBytes(rootPath);
      final total = await _adapter.getTotalBytes(rootPath);
      return StorageCapacity(totalBytes: total, availableBytes: avail);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isDestinationAccessible(String rootPath) async {
    if (rootPath.isEmpty) return false;
    if (rootPath.startsWith('content://')) {
      return _adapter.isStorageConnected(rootPath);
    }
    try {
      final dir = Directory(rootPath);
      return dir.existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> resolveMediaFilePath(String relativePath) async {
    final resolution = await resolveDestination();
    if (resolution.destination != null) {
      return p.join(resolution.destination!.rootPath, relativePath);
    }
    return localStorageManager.resolveLocalPath(relativePath);
  }
}
