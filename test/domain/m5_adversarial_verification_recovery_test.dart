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
      id: 'local-device',
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
  final Map<String, bool> connectedMap = {};

  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async => 'fs-id';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async => 'Storage';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async {
    return connectedMap[rootUriOrPath] ?? true;
  }

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
  late Directory hddDir;
  late Directory deviceDir;
  late FakeDeviceStorageService deviceStorage;
  late FakeStorageIdentityService storageIdentity;
  late TransferServiceImpl transferService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('reelhouse_m56_verif_');
    hddDir = Directory(p.join(tempDir.path, 'external_hdd'))..createSync();
    deviceDir = Directory(p.join(tempDir.path, 'app_device'))..createSync();

    deviceStorage = FakeDeviceStorageService(rootPath: deviceDir.path);
    storageIdentity = FakeStorageIdentityService();

    transferService = TransferServiceImpl(
      database: db,
      deviceStorageService: deviceStorage,
      storageIdentityService: storageIdentity,
    );

    // Register external HDD storage
    await db.upsertStorage(
      StoragesCompanion.insert(
        id: 'hdd-1',
        name: 'Passport HDD',
        storageType: 'EXTERNAL_HDD',
        filesystemIdentifier: 'fs-hdd-1',
        rootUri: hddDir.path,
        lastSeenAt: DateTime.now(),
        available: const drift.Value(true),
      ),
    );

    // Update default local-device storage record rootUri
    await (db.update(
      db.storages,
    )..where((s) => s.id.equals('local-device'))).write(
      StoragesCompanion(
        rootUri: drift.Value(deviceDir.path),
        available: const drift.Value(true),
      ),
    );
  });

  tearDown(() async {
    transferService.dispose();
    await db.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Future<void> seedMovie({
    required String id,
    required String title,
    int year = 2024,
    int fileSize = 1024 * 1024,
  }) async {
    final now = DateTime.now();
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: id,
            detectedTitle: title,
            title: drift.Value(title),
            year: drift.Value(year),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final movieRelPath = p.join('Movies', '$title ($year).mkv');
    final movieFile = File(p.join(hddDir.path, movieRelPath));
    movieFile.parent.createSync(recursive: true);
    final bytes = Uint8List(fileSize);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = i % 256;
    }
    movieFile.writeAsBytesSync(bytes);

    await db.insertMediaSource(
      MediaSourcesCompanion.insert(
        id: 'src_$id',
        movieId: drift.Value(id),
        storageId: 'hdd-1',
        sourceType: 'removableStorage',
        relativePath: movieRelPath,
        filename: '$title ($year).mkv',
        extension: 'mkv',
        fileSize: BigInt.from(fileSize),
        createdAt: now,
        firstSeenAt: now,
        lastSeenAt: now,
        available: const drift.Value(true),
      ),
    );
  }

  group('Area G — Duplicate Registration Invariant', () {
    test('Invoking registerCompletedTransfer multiple times is strictly idempotent', () async {
      await seedMovie(
        id: 'mov_reg_dup',
        title: 'The Matrix',
        year: 1999,
        fileSize: 1024 * 1024,
      );

      final transferRes = await transferService.transferMovie('mov_reg_dup');
      expect(transferRes.state, TransferState.completed);

      // Register transfer 1st time
      final s1 = await transferService.registerCompletedTransfer(
        transferRes.transferId,
      );
      expect(s1.sourceType, 'localDevice');

      // Register transfer 2nd time
      final s2 = await transferService.registerCompletedTransfer(
        transferRes.transferId,
      );
      expect(s2.id, s1.id);

      // Register transfer 3rd time
      final s3 = await transferService.registerCompletedTransfer(
        transferRes.transferId,
      );
      expect(s3.id, s1.id);

      // Database should contain exactly 2 MediaSources (1 HDD + 1 LocalDevice)
      final allSources = await db.getSourcesForMovie('mov_reg_dup');
      expect(allSources.length, 2);
      expect(allSources.where((s) => s.sourceType == 'localDevice').length, 1);
    });
  });

  group('Area H — Partial / Final File Collision Matrix', () {
    test('Matrix 1: Partial exists, Final missing -> verifies and finalizes to destination', () async {
      await seedMovie(
        id: 'mov_col_1',
        title: 'Gladiator',
        year: 2000,
        fileSize: 512 * 1024,
      );

      final destRelPath = p.join(
        'movies',
        'Gladiator (2000)',
        'Gladiator (2000).mkv',
      );
      final finalPath = p.join(deviceDir.path, destRelPath);
      final partialPath = '$finalPath.reelhouse-partial';

      final partialFile = File(partialPath)..parent.createSync(recursive: true);
      partialFile.writeAsBytesSync(Uint8List(512 * 1024));

      final jobId = 'job_col_1';
      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: jobId,
          mediaType: 'movie',
          mediaId: 'mov_col_1',
          sourceMediaSourceId: 'src_mov_col_1',
          destinationStorageId: 'local-device',
          destinationRelativePath: destRelPath,
          status: 'VERIFYING',
          totalBytes: BigInt.from(512 * 1024),
          bytesTransferred: drift.Value(BigInt.from(512 * 1024)),
          startedAt: DateTime.now(),
        ),
      );

      final results = await transferService.reconcileTransfers();
      expect(results.length, 1);
      expect(results.first.state, TransferState.completed);

      expect(File(finalPath).existsSync(), true);
      expect(File(partialPath).existsSync(), false);
    });

    test('Matrix 2: Partial missing, Final exists with valid size -> completes safely', () async {
      await seedMovie(
        id: 'mov_col_2',
        title: 'Fight Club',
        year: 1999,
        fileSize: 512 * 1024,
      );

      final destRelPath = p.join(
        'movies',
        'Fight Club (1999)',
        'Fight Club (1999).mkv',
      );
      final finalPath = p.join(deviceDir.path, destRelPath);
      final finalFile = File(finalPath)..parent.createSync(recursive: true);
      finalFile.writeAsBytesSync(Uint8List(512 * 1024));

      final jobId = 'job_col_2';
      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: jobId,
          mediaType: 'movie',
          mediaId: 'mov_col_2',
          sourceMediaSourceId: 'src_mov_col_2',
          destinationStorageId: 'local-device',
          destinationRelativePath: destRelPath,
          status: 'TRANSFERRING',
          totalBytes: BigInt.from(512 * 1024),
          bytesTransferred: drift.Value(BigInt.from(256 * 1024)),
          startedAt: DateTime.now(),
        ),
      );

      final results = await transferService.reconcileTransfers();
      expect(results.length, 1);
      expect(results.first.state, TransferState.completed);
    });

    test('Matrix 3: Partial exists, Final exists with stale/corrupt size -> replaces stale final with verified partial', () async {
      await seedMovie(
        id: 'mov_col_3',
        title: 'Se7en',
        year: 1995,
        fileSize: 512 * 1024,
      );

      final destRelPath = p.join('movies', 'Se7en (1995)', 'Se7en (1995).mkv');
      final finalPath = p.join(deviceDir.path, destRelPath);
      final partialPath = '$finalPath.reelhouse-partial';

      // Stale destination file with wrong size
      final finalFile = File(finalPath)..parent.createSync(recursive: true);
      finalFile.writeAsBytesSync(Uint8List(128 * 1024)); // Only 128KB

      // Valid partial file with correct 512KB
      final partialFile = File(partialPath);
      partialFile.writeAsBytesSync(Uint8List(512 * 1024));

      final jobId = 'job_col_3';
      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: jobId,
          mediaType: 'movie',
          mediaId: 'mov_col_3',
          sourceMediaSourceId: 'src_mov_col_3',
          destinationStorageId: 'local-device',
          destinationRelativePath: destRelPath,
          status: 'VERIFYING',
          totalBytes: BigInt.from(512 * 1024),
          bytesTransferred: drift.Value(BigInt.from(512 * 1024)),
          startedAt: DateTime.now(),
        ),
      );

      final results = await transferService.reconcileTransfers();
      expect(results.length, 1);
      expect(results.first.state, TransferState.completed);

      expect(finalFile.existsSync(), true);
      expect(finalFile.lengthSync(), 512 * 1024);
      expect(partialFile.existsSync(), false);
    });

    test('Matrix 4: Partial missing, Final missing during VERIFYING -> fails deterministically', () async {
      await seedMovie(
        id: 'mov_col_4',
        title: 'Alien',
        year: 1979,
        fileSize: 512 * 1024,
      );

      final destRelPath = p.join('movies', 'Alien (1979)', 'Alien (1979).mkv');
      final jobId = 'job_col_4';
      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: jobId,
          mediaType: 'movie',
          mediaId: 'mov_col_4',
          sourceMediaSourceId: 'src_mov_col_4',
          destinationStorageId: 'local-device',
          destinationRelativePath: destRelPath,
          status: 'VERIFYING',
          totalBytes: BigInt.from(512 * 1024),
          bytesTransferred: drift.Value(BigInt.from(512 * 1024)),
          startedAt: DateTime.now(),
        ),
      );

      final results = await transferService.reconcileTransfers();
      expect(results.length, 1);
      expect(results.first.state, TransferState.failed);
      expect(results.first.error, contains('partial file is missing'));
    });
  });

  group('Area I — Corrupt Partial Files Hardening', () {
    test(
      'Partial smaller than expected fails verification and is cleaned',
      () async {
        await seedMovie(
          id: 'mov_corrupt_small',
          title: 'Parasite',
          year: 2019,
          fileSize: 1024 * 1024,
        );

        final destRelPath = p.join(
          'movies',
          'Parasite (2019)',
          'Parasite (2019).mkv',
        );
        final partialPath = p.join(
          deviceDir.path,
          '$destRelPath.reelhouse-partial',
        );
        final partialFile = File(partialPath)
          ..parent.createSync(recursive: true);
        partialFile.writeAsBytesSync(
          Uint8List(512 * 1024),
        ); // Only 512KB instead of 1MB

        final jobId = 'job_corrupt_small';
        await db.upsertTransferJob(
          TransferJobsCompanion.insert(
            id: jobId,
            mediaType: 'movie',
            mediaId: 'mov_corrupt_small',
            sourceMediaSourceId: 'src_mov_corrupt_small',
            destinationStorageId: 'local-device',
            destinationRelativePath: destRelPath,
            status: 'VERIFYING',
            totalBytes: BigInt.from(1024 * 1024),
            bytesTransferred: drift.Value(BigInt.from(1024 * 1024)),
            startedAt: DateTime.now(),
          ),
        );

        final results = await transferService.reconcileTransfers();
        expect(results.first.state, TransferState.failed);
        expect(partialFile.existsSync(), false);

        // MediaSources should not have any localDevice copy
        final sources = await db.getSourcesForMovie('mov_corrupt_small');
        expect(
          sources.where((s) => s.sourceType == 'localDevice').isEmpty,
          true,
        );
      },
    );

    test(
      'Partial larger than expected fails verification and is cleaned',
      () async {
        await seedMovie(
          id: 'mov_corrupt_large',
          title: 'Whiplash',
          year: 2014,
          fileSize: 512 * 1024,
        );

        final destRelPath = p.join(
          'movies',
          'Whiplash (2014)',
          'Whiplash (2014).mkv',
        );
        final partialPath = p.join(
          deviceDir.path,
          '$destRelPath.reelhouse-partial',
        );
        final partialFile = File(partialPath)
          ..parent.createSync(recursive: true);
        partialFile.writeAsBytesSync(
          Uint8List(1024 * 1024),
        ); // 1MB instead of 512KB

        final jobId = 'job_corrupt_large';
        await db.upsertTransferJob(
          TransferJobsCompanion.insert(
            id: jobId,
            mediaType: 'movie',
            mediaId: 'mov_corrupt_large',
            sourceMediaSourceId: 'src_mov_corrupt_large',
            destinationStorageId: 'local-device',
            destinationRelativePath: destRelPath,
            status: 'VERIFYING',
            totalBytes: BigInt.from(512 * 1024),
            bytesTransferred: drift.Value(BigInt.from(512 * 1024)),
            startedAt: DateTime.now(),
          ),
        );

        final results = await transferService.reconcileTransfers();
        expect(results.first.state, TransferState.failed);
        expect(partialFile.existsSync(), false);
      },
    );

    test('Zero-byte partial file fails verification', () async {
      await seedMovie(
        id: 'mov_corrupt_zero',
        title: 'Joker',
        year: 2019,
        fileSize: 512 * 1024,
      );

      final destRelPath = p.join('movies', 'Joker (2019)', 'Joker (2019).mkv');
      final partialPath = p.join(
        deviceDir.path,
        '$destRelPath.reelhouse-partial',
      );
      final partialFile = File(partialPath)..parent.createSync(recursive: true);
      partialFile.writeAsBytesSync(Uint8List(0)); // 0 bytes

      final jobId = 'job_corrupt_zero';
      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: jobId,
          mediaType: 'movie',
          mediaId: 'mov_corrupt_zero',
          sourceMediaSourceId: 'src_mov_corrupt_zero',
          destinationStorageId: 'local-device',
          destinationRelativePath: destRelPath,
          status: 'VERIFYING',
          totalBytes: BigInt.from(512 * 1024),
          bytesTransferred: drift.Value(BigInt.from(512 * 1024)),
          startedAt: DateTime.now(),
        ),
      );

      final results = await transferService.reconcileTransfers();
      expect(results.first.state, TransferState.failed);
      expect(partialFile.existsSync(), false);
    });
  });

  group('Area J & K — Crash Recovery and Idempotency', () {
    test('Sequential repeated reconcileTransfers() calls converge to identical state without oscillation', () async {
      await seedMovie(
        id: 'mov_idem',
        title: 'Coco',
        year: 2017,
        fileSize: 512 * 1024,
      );

      final destRelPath = p.join('movies', 'Coco (2017)', 'Coco (2017).mkv');
      final partialPath = p.join(
        deviceDir.path,
        '$destRelPath.reelhouse-partial',
      );
      final partialFile = File(partialPath)..parent.createSync(recursive: true);
      partialFile.writeAsBytesSync(Uint8List(512 * 1024));

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job_idem_1',
          mediaType: 'movie',
          mediaId: 'mov_idem',
          sourceMediaSourceId: 'src_mov_idem',
          destinationStorageId: 'local-device',
          destinationRelativePath: destRelPath,
          status: 'VERIFYING',
          totalBytes: BigInt.from(512 * 1024),
          bytesTransferred: drift.Value(BigInt.from(512 * 1024)),
          startedAt: DateTime.now(),
        ),
      );

      // Reconcile pass 1
      final r1 = await transferService.reconcileTransfers();
      expect(r1.length, 1);
      expect(r1.first.state, TransferState.completed);

      // Reconcile pass 2 (should find nothing to reconcile)
      final r2 = await transferService.reconcileTransfers();
      expect(r2.isEmpty, true);

      // Reconcile pass 3
      final r3 = await transferService.reconcileTransfers();
      expect(r3.isEmpty, true);

      // Final destination intact
      final finalFile = File(p.join(deviceDir.path, destRelPath));
      expect(finalFile.existsSync(), true);
      expect(finalFile.lengthSync(), 512 * 1024);
    });
  });

  group('Area L — Orphan Partial File Cleanup', () {
    test('cleanStalePartials removes unreferenced partials while keeping finalized files', () async {
      final orphanPartial = File(
        p.join(
          deviceDir.path,
          'movies',
          'Orphan',
          'Orphan.mkv.reelhouse-partial',
        ),
      )..parent.createSync(recursive: true);
      orphanPartial.writeAsBytesSync(Uint8List(100));

      final finalizedFile = File(
        p.join(deviceDir.path, 'movies', 'Final', 'Final.mkv'),
      )..parent.createSync(recursive: true);
      finalizedFile.writeAsBytesSync(Uint8List(200));

      final cleanedCount = await transferService.cleanStalePartials();
      expect(cleanedCount, 1);
      expect(orphanPartial.existsSync(), false);
      expect(finalizedFile.existsSync(), true);
    });
  });
}
