import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/platform/device_storage_service_impl.dart';
import 'package:reelhouse/data/platform/platform_storage_adapter.dart';
import 'package:reelhouse/domain/models/device_storage_destination.dart';
import 'package:reelhouse/domain/models/storage_type.dart';
import 'package:reelhouse/domain/scanner/library_scanner_service.dart';
import 'package:reelhouse/domain/services/device_storage_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';

class MockLocalStorageManager implements LocalStorageManager {
  String basePath;
  int availableBytes;
  int totalBytes;

  MockLocalStorageManager({
    required this.basePath,
    this.availableBytes = 50 * 1024 * 1024 * 1024,
    this.totalBytes = 100 * 1024 * 1024 * 1024,
  });

  @override
  Future<String> getLocalMediaDirectoryPath() async => basePath;

  @override
  Future<int> getAvailableDeviceStorageBytes() async => availableBytes;

  @override
  Future<int> getTotalDeviceStorageBytes() async => totalBytes;

  @override
  Future<int> getUsedOfflineStorageBytes() async => 0;

  @override
  Future<String> resolveLocalPath(String relativePath) async =>
      p.join(basePath, relativePath);

  @override
  Future<bool> verifyLocalCopyIntegrity(
    String relativePath,
    int expectedBytes,
  ) async => true;

  @override
  Future<bool> deleteLocalCopy(String relativePath) async => true;
}

class MockPlatformStorageAdapter implements PlatformStorageAdapter {
  bool connected;
  int availableBytes;
  int totalBytes;
  bool shouldThrowOnCapacity;

  MockPlatformStorageAdapter({
    this.connected = true,
    this.availableBytes = 50 * 1024 * 1024 * 1024,
    this.totalBytes = 100 * 1024 * 1024 * 1024,
    this.shouldThrowOnCapacity = false,
  });

  @override
  Future<bool> isStorageConnected(String rootUri) async => connected;

  @override
  Future<String?> getFilesystemIdentifier(String rootUri) async =>
      'test-fs-identity';

  @override
  Future<String> getStorageDisplayName(String rootUri) async => 'Test Device';

  @override
  Future<int> getAvailableBytes(String rootUri) async {
    if (shouldThrowOnCapacity) throw Exception('Capacity query failed');
    return availableBytes;
  }

  @override
  Future<int> getTotalBytes(String rootUri) async {
    if (shouldThrowOnCapacity) throw Exception('Capacity query failed');
    return totalBytes;
  }

  @override
  Future<bool> fileExists(String rootUri, String relativePath) async => true;

  @override
  Future<int> getFileSizeBytes(String rootUri, String relativePath) async => 0;

  @override
  Future<String> resolvePlaybackUri(
    String rootUri,
    String relativePath,
  ) async => p.join(rootUri, relativePath);
}

class MockStorageIdentityService implements StorageIdentityService {
  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'mock-fs-id';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      'Mock Storage';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async => true;

  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;

  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {}
}

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late MockLocalStorageManager localManager;
  late MockPlatformStorageAdapter adapter;
  late DeviceStorageService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reelhouse_storage_test_');
    db = AppDatabase(NativeDatabase.memory());
    localManager = MockLocalStorageManager(basePath: tempDir.path);
    adapter = MockPlatformStorageAdapter();
    service = DeviceStorageServiceImpl(
      database: db,
      localStorageManager: localManager,
      adapter: adapter,
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('M5.1 — Registration & Persistence', () {
    test(
      'resolves default destination and initializes rootUri in database',
      () async {
        final destination = await service.ensureDefaultDestinationRegistered();

        expect(destination.id, 'local-device');
        expect(destination.name, 'This Device');
        expect(destination.rootPath, tempDir.path);
        expect(destination.isAccessible, true);
        expect(destination.isApplicationManaged, true);
        expect(destination.availableBytes, 50 * 1024 * 1024 * 1024);
        expect(destination.totalBytes, 100 * 1024 * 1024 * 1024);

        // Verify database state
        final dbRecord = await db.getDeviceStorage();
        expect(dbRecord, isNotNull);
        expect(dbRecord!.rootUri, tempDir.path);
        expect(dbRecord.storageType, 'DEVICE_LOCAL_STORAGE');
      },
    );

    test('registers custom application-managed destination', () async {
      final customPath = p.join(tempDir.path, 'custom_media');
      await Directory(customPath).create(recursive: true);

      final destination = await service.registerDestination(
        rootPath: customPath,
        name: 'Internal Fast Storage',
      );

      expect(destination.id, 'local-device');
      expect(destination.name, 'Internal Fast Storage');
      expect(destination.rootPath, customPath);
      expect(destination.isAccessible, true);
      expect(destination.isApplicationManaged, true);

      final resolution = await service.resolveDestination();
      expect(
        resolution.status,
        DeviceStorageResolutionStatus.registeredAndAccessible,
      );
      expect(resolution.destination?.rootPath, customPath);
      expect(resolution.destination?.name, 'Internal Fast Storage');
    });

    test('registration persists across database instances (restart simulation)', () async {
      await service.ensureDefaultDestinationRegistered();

      // Simulate app restart with a fresh service pointing to the same database
      final restartedService = DeviceStorageServiceImpl(
        database: db,
        localStorageManager: localManager,
        adapter: adapter,
      );

      final resolution = await restartedService.resolveDestination();
      expect(
        resolution.status,
        DeviceStorageResolutionStatus.registeredAndAccessible,
      );
      expect(resolution.destination?.id, 'local-device');
      expect(resolution.destination?.rootPath, tempDir.path);
      expect(resolution.isAccessible, true);
      expect(resolution.isRegistered, true);
    });
  });

  group('M5.1 — Identity Stability & Deduplication', () {
    test('repeated initialization/resolution does not create duplicate storage rows', () async {
      await service.ensureDefaultDestinationRegistered();
      await service.ensureDefaultDestinationRegistered();
      await service.resolveDestination();
      await service.resolveDestination();

      final allStorages = await db.getAllStorages();
      final deviceStorages = allStorages
          .where((s) => s.storageType == 'DEVICE_LOCAL_STORAGE')
          .toList();

      expect(deviceStorages.length, 1);
      expect(deviceStorages.first.id, 'local-device');
    });

    test(
      'device storage exposes isApplicationManaged == true and stable identity',
      () async {
        final dest = await service.ensureDefaultDestinationRegistered();
        expect(dest.isApplicationManaged, true);
        expect(dest.filesystemIdentifier, isNotEmpty);
      },
    );
  });

  group('M5.1 — Accessibility & Inaccessibility States', () {
    test('accessible destination reports registeredAndAccessible', () async {
      await service.ensureDefaultDestinationRegistered();
      final resolution = await service.resolveDestination();

      expect(
        resolution.status,
        DeviceStorageResolutionStatus.registeredAndAccessible,
      );
      expect(resolution.isAccessible, true);
      expect(resolution.isRegistered, true);
    });

    test('inaccessible destination reports registeredAndInaccessible without deleting registration', () async {
      final nonExistentPath = p.join(tempDir.path, 'deleted_folder');
      await service.registerDestination(rootPath: nonExistentPath);

      final resolution = await service.resolveDestination();

      expect(
        resolution.status,
        DeviceStorageResolutionStatus.registeredAndInaccessible,
      );
      expect(resolution.isAccessible, false);
      expect(resolution.isRegistered, true);
      expect(resolution.destination, isNotNull);
      expect(resolution.destination?.rootPath, nonExistentPath);

      // Verify persistent record remains in the database
      final dbRecord = await db.getDeviceStorage();
      expect(dbRecord, isNotNull);
      expect(dbRecord!.rootUri, nonExistentPath);
      expect(dbRecord.available, false);
    });

    test('unregistered destination reports notRegistered', () async {
      // Delete seeded storage to test unregistered state
      await (db.delete(
        db.storages,
      )..where((s) => s.storageType.equals('DEVICE_LOCAL_STORAGE'))).go();

      final resolution = await service.resolveDestination();

      expect(resolution.status, DeviceStorageResolutionStatus.notRegistered);
      expect(resolution.isAccessible, false);
      expect(resolution.isRegistered, false);
      expect(resolution.destination, isNull);
    });
  });

  group('M5.1 — Capacity Information', () {
    test(
      'returns accurate total, available, used, and fraction metrics',
      () async {
        adapter.availableBytes = 30 * 1024 * 1024 * 1024;
        adapter.totalBytes = 100 * 1024 * 1024 * 1024;

        final capacity = await service.getDestinationCapacity(tempDir.path);

        expect(capacity, isNotNull);
        expect(capacity!.availableBytes, 30 * 1024 * 1024 * 1024);
        expect(capacity.totalBytes, 100 * 1024 * 1024 * 1024);
        expect(capacity.usedBytes, 70 * 1024 * 1024 * 1024);
        expect(capacity.usedFraction, closeTo(0.70, 0.01));
      },
    );

    test(
      'handles capacity query platform failures gracefully without throwing',
      () async {
        adapter.shouldThrowOnCapacity = true;

        final capacity = await service.getDestinationCapacity(tempDir.path);
        expect(capacity, isNull);

        final resolution = await service.resolveDestination();
        expect(
          resolution.status,
          DeviceStorageResolutionStatus.registeredAndAccessible,
        );
        expect(resolution.destination?.totalBytes, isNull);
        expect(resolution.destination?.availableBytes, isNull);
      },
    );
  });

  group('M5.1 — Scanner Isolation (Section 6)', () {
    test('device storage is clearly distinguished from user-managed external storage', () {
      expect(
        StorageType.deviceLocalStorage.toDbString(),
        'DEVICE_LOCAL_STORAGE',
      );
      expect(StorageType.removableVolume.toDbString(), 'REMOVABLE_VOLUME');
      expect(
        StorageType.fromString('DEVICE_LOCAL_STORAGE'),
        StorageType.deviceLocalStorage,
      );
      expect(
        StorageType.fromString('REMOVABLE_VOLUME'),
        StorageType.removableVolume,
      );
    });

    test('LibraryScannerService refuses to scan application-managed DEVICE_LOCAL_STORAGE', () async {
      final storage = Storage(
        id: 'local-device',
        name: 'This Device',
        storageType: 'DEVICE_LOCAL_STORAGE',
        filesystemIdentifier: 'internal-app-storage',
        rootUri: tempDir.path,
        lastSeenAt: DateTime.now(),
        available: true,
      );

      final scannerService = LibraryScannerService(
        database: db,
        storageIdentityService: MockStorageIdentityService(),
      );

      final summary = await scannerService.scanStorage(storage);

      expect(summary.filesDiscovered, 0);
      expect(summary.newSourcesAdded, 0);
      expect(summary.moviesIdentified, 0);
      expect(summary.tvEpisodesIdentified, 0);
      expect(summary.duration, Duration.zero);
    });
  });

  group('M5.1 — Path Resolution', () {
    test(
      'resolves relative media path inside managed destination root',
      () async {
        await service.ensureDefaultDestinationRegistered();

        final resolved = await service.resolveMediaFilePath(
          'movies/Inception (2010)/Inception.mkv',
        );
        final expected = p.join(
          tempDir.path,
          'movies/Inception (2010)/Inception.mkv',
        );

        expect(resolved, expected);
      },
    );
  });
}
