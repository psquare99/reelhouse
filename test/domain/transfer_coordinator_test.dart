import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/services/transfer_service_impl.dart';
import 'package:reelhouse/domain/models/device_storage_destination.dart';
import 'package:reelhouse/domain/models/transfer_models.dart';
import 'package:reelhouse/domain/services/device_storage_service.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/domain/services/transfer_coordinator.dart';

class FakeDeviceStorageService implements DeviceStorageService {
  String rootPath;
  bool accessible;
  int availableBytes;
  int totalBytes;

  FakeDeviceStorageService({
    required this.rootPath,
    this.accessible = true,
    this.availableBytes = 50 * 1024 * 1024 * 1024,
    this.totalBytes = 100 * 1024 * 1024 * 1024,
  });

  @override
  Future<DeviceStorageResolution> resolveDestination() async {
    final dest = DeviceStorageDestination(
      id: 'device-storage-internal',
      name: 'This Device',
      rootPath: rootPath,
      filesystemIdentifier: 'internal-app-storage',
      isAccessible: accessible,
      isApplicationManaged: true,
      availableBytes: availableBytes,
      totalBytes: totalBytes,
      lastSeenAt: DateTime.now(),
    );

    if (accessible) {
      return DeviceStorageResolution.registeredAndAccessible(dest);
    } else {
      return DeviceStorageResolution.registeredAndInaccessible(
        dest,
        message: 'Device storage is inaccessible',
      );
    }
  }

  @override
  Future<DeviceStorageDestination> ensureDefaultDestinationRegistered() async {
    final res = await resolveDestination();
    return res.destination!;
  }

  @override
  Future<DeviceStorageDestination> registerDestination({
    required String rootPath,
    String? name,
    String? id,
    bool createDirectory = false,
  }) async {
    this.rootPath = rootPath;
    final res = await resolveDestination();
    return res.destination!;
  }

  @override
  Future<StorageCapacity?> getDestinationCapacity(String rootPath) async {
    return StorageCapacity(
      totalBytes: totalBytes,
      availableBytes: availableBytes,
    );
  }

  @override
  Future<bool> isDestinationAccessible(String rootPath) async {
    return accessible && Directory(rootPath).existsSync();
  }

  @override
  Future<String> resolveMediaFilePath(String relativePath) async {
    return p.join(rootPath, relativePath);
  }
}

class FakeStorageIdentityService implements StorageIdentityService {
  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'fs-identity-1';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      'HDD Storage';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async =>
      Directory(rootUriOrPath).existsSync();

  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;

  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {}
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late Directory sourceDir;
  late Directory destDir;
  late FakeDeviceStorageService deviceStorageService;
  late StorageIdentityService storageIdentityService;
  late TransferServiceImpl transferService;
  late TransferCoordinator coordinator;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp(
      'reelhouse_coordinator_test_',
    );
    sourceDir = Directory(p.join(tempDir.path, 'source'))
      ..createSync(recursive: true);
    destDir = Directory(p.join(tempDir.path, 'dest'))
      ..createSync(recursive: true);

    deviceStorageService = FakeDeviceStorageService(rootPath: destDir.path);
    storageIdentityService = FakeStorageIdentityService();
    transferService = TransferServiceImpl(
      database: db,
      deviceStorageService: deviceStorageService,
      storageIdentityService: storageIdentityService,
    );
    coordinator = TransferCoordinator(
      transferService: transferService,
      database: db,
      deviceStorageService: deviceStorageService,
      storageIdentityService: storageIdentityService,
    );
  });

  tearDown(() async {
    coordinator.dispose();
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('TransferCoordinator sequential execution and automatic MediaSource registration', () async {
    final now = DateTime.now();

    // 1. Setup DB: Device Storage & External HDD Storage
    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'device-storage-internal',
            name: 'This Device',
            storageType: 'DEVICE_LOCAL_STORAGE',
            filesystemIdentifier: 'internal-app-storage',
            rootUri: destDir.path,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'hdd-1',
            name: 'Cinema HDD',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: 'fs-identity-1',
            rootUri: sourceDir.path,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    // 2. Setup Movies
    final movieFile1 = File(
      p.join(sourceDir.path, 'Inception (2010)', 'Inception.mkv'),
    )..createSync(recursive: true);
    movieFile1.writeAsBytesSync(Uint8List(1024 * 100)); // 100 KB

    final movieFile2 = File(
      p.join(sourceDir.path, 'Interstellar (2014)', 'Interstellar.mkv'),
    )..createSync(recursive: true);
    movieFile2.writeAsBytesSync(Uint8List(1024 * 150)); // 150 KB

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'movie-inception',
            detectedTitle: 'Inception',
            title: const drift.Value('Inception'),
            year: const drift.Value(2010),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'src-inception-hdd',
            movieId: const drift.Value('movie-inception'),
            storageId: 'hdd-1',
            sourceType: 'removableStorage',
            relativePath: 'Inception (2010)/Inception.mkv',
            filename: 'Inception.mkv',
            extension: 'mkv',
            fileSize: BigInt.from(1024 * 100),
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'movie-interstellar',
            detectedTitle: 'Interstellar',
            title: const drift.Value('Interstellar'),
            year: const drift.Value(2014),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'src-interstellar-hdd',
            movieId: const drift.Value('movie-interstellar'),
            storageId: 'hdd-1',
            sourceType: 'removableStorage',
            relativePath: 'Interstellar (2014)/Interstellar.mkv',
            filename: 'Interstellar.mkv',
            extension: 'mkv',
            fileSize: BigInt.from(1024 * 150),
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    // 3. Queue both transfers concurrently
    final f1 = coordinator.requestMovieTransfer('movie-inception');
    final f2 = coordinator.requestMovieTransfer('movie-interstellar');

    // Duplicate transfer protection: calling requestMovieTransfer again returns f1 without duplicating
    final f1Duplicate = coordinator.requestMovieTransfer('movie-inception');
    expect(identical(f1, f1Duplicate), isTrue);

    final results = await Future.wait([f1, f2]);
    expect(results[0].state, equals(TransferState.completed));
    expect(results[1].state, equals(TransferState.completed));

    // Verify automatic MediaSource registration
    final sources1 = await db.getSourcesForMovie('movie-inception');
    expect(sources1.length, equals(2));
    final devSource1 = sources1.firstWhere(
      (s) => s.storageId == 'device-storage-internal',
    );
    expect(
      devSource1.relativePath,
      equals('movies/Inception (2010)/Inception.mkv'),
    );
    expect(
      File(p.join(destDir.path, devSource1.relativePath)).existsSync(),
      isTrue,
    );

    final sources2 = await db.getSourcesForMovie('movie-interstellar');
    expect(sources2.length, equals(2));
    final devSource2 = sources2.firstWhere(
      (s) => s.storageId == 'device-storage-internal',
    );
    expect(
      devSource2.relativePath,
      equals('movies/Interstellar (2014)/Interstellar.mkv'),
    );
    expect(
      File(p.join(destDir.path, devSource2.relativePath)).existsSync(),
      isTrue,
    );
  });

  test('TransferCoordinator deletion of local offline copy reclaims space and updates source', () async {
    final now = DateTime.now();

    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'device-storage-internal',
            name: 'This Device',
            storageType: 'DEVICE_LOCAL_STORAGE',
            filesystemIdentifier: 'internal-app-storage',
            rootUri: destDir.path,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'hdd-1',
            name: 'Cinema HDD',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: 'fs-identity-1',
            rootUri: sourceDir.path,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    final movieFile = File(p.join(sourceDir.path, 'Dune (2021)', 'Dune.mkv'))
      ..createSync(recursive: true);
    movieFile.writeAsBytesSync(Uint8List(1024 * 50));

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'movie-dune',
            detectedTitle: 'Dune',
            title: const drift.Value('Dune'),
            year: const drift.Value(2021),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'src-dune-hdd',
            movieId: const drift.Value('movie-dune'),
            storageId: 'hdd-1',
            sourceType: 'removableStorage',
            relativePath: 'Dune (2021)/Dune.mkv',
            filename: 'Dune.mkv',
            extension: 'mkv',
            fileSize: BigInt.from(1024 * 50),
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    // Transfer movie
    final res = await coordinator.requestMovieTransfer('movie-dune');
    expect(res.state, equals(TransferState.completed));

    // Verify source exists
    var sources = await db.getSourcesForMovie('movie-dune');
    expect(sources.length, equals(2));
    final devSource = sources.firstWhere(
      (s) => s.storageId == 'device-storage-internal',
    );
    final localCopyFile = File(
      p.join(destDir.path, 'Movies/Dune (2021)/Dune.mkv'),
    );
    expect(localCopyFile.existsSync(), isTrue);

    // Delete local copy via coordinator
    await coordinator.deleteOfflineCopy(devSource.id);

    // Verify file deleted from disk
    expect(localCopyFile.existsSync(), isFalse);

    // Verify device MediaSource deleted from database, but HDD source remains intact
    sources = await db.getSourcesForMovie('movie-dune');
    expect(sources.length, equals(1));
    expect(sources.first.storageId, equals('hdd-1'));

    // Verify movie entity and HDD file are completely untouched
    final allMovies = await (db.select(
      db.movies,
    )..where((m) => m.id.equals('movie-dune'))).get();
    expect(allMovies, isNotEmpty);
    expect(movieFile.existsSync(), isTrue);
  });

  test('TransferCoordinator error translation to human-readable message', () {
    expect(
      TransferCoordinator.formatError(
        const InsufficientStorageException(
          requiredBytes: 1000,
          availableBytes: 100,
        ),
      ),
      contains('free space on this device'),
    );

    expect(
      TransferCoordinator.formatError(
        const NoAvailableSourceException('Drive disconnected'),
      ),
      contains('original source drive is not connected'),
    );

    expect(
      TransferCoordinator.formatError(
        const TransferException('Transfer was cancelled.'),
      ),
      equals('Transfer was cancelled.'),
    );
  });
}
