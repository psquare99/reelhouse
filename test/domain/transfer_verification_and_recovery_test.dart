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
  final Map<String, bool> connectedMap = {};

  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async => 'fs-id';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async => 'Storage';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async {
    return connectedMap[p.normalize(rootUriOrPath)] ?? true;
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
  late Directory tempRootDir;
  late Directory sourceDiskDir;
  late Directory deviceDestDir;
  late FakeDeviceStorageService deviceStorageService;
  late FakeStorageIdentityService storageIdentityService;
  late TransferServiceImpl transferService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    tempRootDir = await Directory.systemTemp.createTemp('reelhouse_m53_test_');
    sourceDiskDir = Directory(p.join(tempRootDir.path, 'source_disk'))
      ..createSync(recursive: true);
    deviceDestDir = Directory(p.join(tempRootDir.path, 'device_dest'))
      ..createSync(recursive: true);

    deviceStorageService = FakeDeviceStorageService(
      rootPath: deviceDestDir.path,
    );
    storageIdentityService = FakeStorageIdentityService();
    storageIdentityService.connectedMap[p.normalize(sourceDiskDir.path)] = true;

    // Register external and internal storages in DB
    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'storage-source-hdd',
            name: 'External HDD',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: '0xHDD1',
            rootUri: sourceDiskDir.path,
            lastSeenAt: DateTime.now(),
            available: const drift.Value(true),
          ),
        );

    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'device-storage-internal',
            name: 'Device Storage',
            storageType: 'LOCAL_APPLICATION',
            filesystemIdentifier: 'internal-app-storage',
            rootUri: deviceDestDir.path,
            lastSeenAt: DateTime.now(),
            available: const drift.Value(true),
          ),
        );

    transferService = TransferServiceImpl(
      database: db,
      deviceStorageService: deviceStorageService,
      storageIdentityService: storageIdentityService,
    );
  });

  tearDown(() async {
    transferService.dispose();
    await db.close();
    if (tempRootDir.existsSync()) {
      try {
        tempRootDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  Future<void> createTestMovie({
    required String id,
    required String title,
    int? year,
    required String relativePath,
    required Uint8List content,
  }) async {
    final now = DateTime.now();
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: id,
            title: drift.Value(title),
            year: year != null ? drift.Value(year) : const drift.Value.absent(),
            detectedTitle: title,
            detectedYear: year != null
                ? drift.Value(year)
                : const drift.Value.absent(),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final physicalFile = File(p.join(sourceDiskDir.path, relativePath));
    physicalFile.parent.createSync(recursive: true);
    physicalFile.writeAsBytesSync(content);

    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'src-$id',
            movieId: drift.Value(id),
            storageId: 'storage-source-hdd',
            sourceType: 'removableStorage',
            relativePath: relativePath,
            filename: p.basename(relativePath),
            extension: p.extension(relativePath).replaceAll('.', ''),
            fileSize: BigInt.from(content.length),
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
          ),
        );
  }

  group('M5.3 — Verification Contract', () {
    test('valid copy passes verification and atomically finalizes', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      await createTestMovie(
        id: 'movie-matrix',
        title: 'The Matrix',
        year: 1999,
        relativePath: 'The Matrix (1999).mkv',
        content: sampleBytes,
      );

      final result = await transferService.transferMovie('movie-matrix');

      expect(result.state, TransferState.completed);
      expect(result.bytesTransferred, 8);
      expect(result.totalBytes, 8);

      final expectedDest = p.normalize(
        p.join(
          deviceDestDir.path,
          'movies',
          'The Matrix (1999)',
          'The Matrix (1999).mkv',
        ),
      );
      final expectedTemp = '$expectedDest.reelhouse-partial';

      // Verified destination file must exist with exact byte content
      final destFile = File(expectedDest);
      expect(destFile.existsSync(), true);
      expect(destFile.lengthSync(), 8);
      expect(destFile.readAsBytesSync(), sampleBytes);

      // Temporary partial artifact must no longer exist after atomic rename
      expect(File(expectedTemp).existsSync(), false);

      // Job in DB must be COMPLETED
      final job = await db.getTransferJobById(result.transferId);
      expect(job, isNotNull);
      expect(job!.status, 'COMPLETED');
      expect(job.completedAt, isNotNull);
    });

    test('smaller-than-expected partial file fails verification', () async {
      final destRel = p.join('movies', 'Inception (2010)', 'Inception.mkv');
      final destPath = p.normalize(p.join(deviceDestDir.path, destRel));
      final tempPath = '$destPath.reelhouse-partial';

      final tempFile = File(tempPath)..parent.createSync(recursive: true);
      tempFile.writeAsBytesSync([1, 2, 3]); // only 3 bytes, expected 10

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-incomplete-size',
          mediaType: 'movie',
          mediaId: 'movie-inception',
          sourceMediaSourceId: 'src-inception',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'VERIFYING',
          totalBytes: BigInt.from(10),
          bytesTransferred: drift.Value(BigInt.from(3)),
          startedAt: DateTime.now(),
        ),
      );

      final reconciled = await transferService.reconcileTransfers();
      expect(reconciled.length, 1);
      expect(reconciled.first.state, TransferState.failed);
      expect(reconciled.first.error, contains('smaller than expected'));

      // Invalid partial file must be safely removed
      expect(tempFile.existsSync(), false);
      expect(File(destPath).existsSync(), false);

      final job = await db.getTransferJobById('job-incomplete-size');
      expect(job!.status, 'FAILED');
    });

    test('larger-than-expected partial file fails verification', () async {
      final destRel = p.join(
        'movies',
        'Interstellar (2014)',
        'Interstellar.mkv',
      );
      final destPath = p.normalize(p.join(deviceDestDir.path, destRel));
      final tempPath = '$destPath.reelhouse-partial';

      final tempFile = File(tempPath)..parent.createSync(recursive: true);
      tempFile.writeAsBytesSync(
        List.generate(20, (i) => i),
      ); // 20 bytes, expected 10

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-oversize',
          mediaType: 'movie',
          mediaId: 'movie-interstellar',
          sourceMediaSourceId: 'src-interstellar',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'VERIFYING',
          totalBytes: BigInt.from(10),
          bytesTransferred: drift.Value(BigInt.from(20)),
          startedAt: DateTime.now(),
        ),
      );

      final reconciled = await transferService.reconcileTransfers();
      expect(reconciled.length, 1);
      expect(reconciled.first.state, TransferState.failed);
      expect(reconciled.first.error, contains('larger than expected'));

      expect(tempFile.existsSync(), false);
      expect(File(destPath).existsSync(), false);
    });

    test('missing partial file during verification fails gracefully', () async {
      final destRel = p.join('movies', 'Memento (2000)', 'Memento.mkv');

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-missing-partial',
          mediaType: 'movie',
          mediaId: 'movie-memento',
          sourceMediaSourceId: 'src-memento',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'VERIFYING',
          totalBytes: BigInt.from(100),
          bytesTransferred: drift.Value(BigInt.from(100)),
          startedAt: DateTime.now(),
        ),
      );

      final reconciled = await transferService.reconcileTransfers();
      expect(reconciled.length, 1);
      expect(reconciled.first.state, TransferState.failed);

      final job = await db.getTransferJobById('job-missing-partial');
      expect(job!.status, 'FAILED');
    });
  });

  group('M5.3 — Atomic Finalization & MediaSource Invariants', () {
    test(
      'final destination is created and source media remains untouched',
      () async {
        final sampleBytes = Uint8List.fromList([10, 20, 30, 40]);
        await createTestMovie(
          id: 'movie-gladiator',
          title: 'Gladiator',
          year: 2000,
          relativePath: 'Gladiator.mkv',
          content: sampleBytes,
        );

        final sourceFile = File(p.join(sourceDiskDir.path, 'Gladiator.mkv'));
        final sourceModifiedBefore = sourceFile.lastModifiedSync();

        final result = await transferService.transferMovie('movie-gladiator');
        expect(result.state, TransferState.completed);

        // Source file must exist and remain completely unmodified
        expect(sourceFile.existsSync(), true);
        expect(sourceFile.readAsBytesSync(), sampleBytes);
        expect(sourceFile.lastModifiedSync(), sourceModifiedBefore);

        // Final destination exists
        final finalFile = File(result.destinationPath!);
        expect(finalFile.existsSync(), true);
        expect(finalFile.readAsBytesSync(), sampleBytes);
      },
    );

    test('INVARIANT: M5.3 does NOT register a new MediaSource in the database', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3]);
      await createTestMovie(
        id: 'movie-alien',
        title: 'Alien',
        year: 1979,
        relativePath: 'Alien.mkv',
        content: sampleBytes,
      );

      // Check sources before transfer: exactly 1 (external HDD)
      final sourcesBefore = await db.getSourcesForMovie('movie-alien');
      expect(sourcesBefore.length, 1);
      expect(sourcesBefore.first.storageId, 'storage-source-hdd');

      final result = await transferService.transferMovie('movie-alien');
      expect(result.state, TransferState.completed);

      // Check sources after transfer: still exactly 1 (M5.4 owns registration)
      final sourcesAfter = await db.getSourcesForMovie('movie-alien');
      expect(sourcesAfter.length, 1);
      expect(sourcesAfter.first.storageId, 'storage-source-hdd');
    });
  });

  group('M5.3 — Destination Collision & Idempotency', () {
    test('recognizes already-finalized destination file and avoids redundant copying', () async {
      final sampleBytes = Uint8List.fromList([5, 10, 15, 20]);
      await createTestMovie(
        id: 'movie-prestige',
        title: 'The Prestige',
        year: 2006,
        relativePath: 'The Prestige.mkv',
        content: sampleBytes,
      );

      // Pre-create valid destination file
      final destRel = p.join(
        'movies',
        'The Prestige (2006)',
        'The Prestige.mkv',
      );
      final destFile = File(p.join(deviceDestDir.path, destRel));
      destFile.parent.createSync(recursive: true);
      destFile.writeAsBytesSync(sampleBytes);

      final result = await transferService.transferMovie('movie-prestige');

      expect(result.state, TransferState.completed);
      expect(result.bytesTransferred, 4);
      expect(result.destinationPath, destFile.path);

      final job = await db.getActiveTransferJobForMedia('movie-prestige');
      expect(job, isNull); // completed job is not active
      final allJobs = await db.getTransferJobsForMedia('movie-prestige');
      expect(allJobs.first.status, 'COMPLETED');
    });

    test('reconcileTransfers is idempotent when called repeatedly', () async {
      final destRel = p.join('movies', 'Psycho (1960)', 'Psycho.mkv');
      final destPath = p.normalize(p.join(deviceDestDir.path, destRel));
      final tempPath = '$destPath.reelhouse-partial';

      final tempFile = File(tempPath)..parent.createSync(recursive: true);
      tempFile.writeAsBytesSync([1, 2, 3, 4]); // 4 bytes

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-psycho',
          mediaType: 'movie',
          mediaId: 'movie-psycho',
          sourceMediaSourceId: 'src-psycho',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'VERIFYING',
          totalBytes: BigInt.from(4),
          bytesTransferred: drift.Value(BigInt.from(4)),
          startedAt: DateTime.now(),
        ),
      );

      // First reconciliation: promotes VERIFYING to COMPLETED
      final firstRun = await transferService.reconcileTransfers();
      expect(firstRun.length, 1);
      expect(firstRun.first.state, TransferState.completed);
      expect(File(destPath).existsSync(), true);

      // Second reconciliation: no pending interrupted jobs remain
      final secondRun = await transferService.reconcileTransfers();
      expect(secondRun, isEmpty);

      final job = await db.getTransferJobById('job-psycho');
      expect(job!.status, 'COMPLETED');
    });
  });

  group('M5.3 — Interrupted Transfer Recovery (Crash / Restart)', () {
    test('interrupted VERIFYING job with valid partial file is recovered to COMPLETED', () async {
      final destRel = p.join('movies', 'Casablanca (1942)', 'Casablanca.mkv');
      final destPath = p.normalize(p.join(deviceDestDir.path, destRel));
      final tempPath = '$destPath.reelhouse-partial';

      final tempFile = File(tempPath)..parent.createSync(recursive: true);
      tempFile.writeAsBytesSync([10, 20, 30, 40, 50]); // 5 bytes

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-casablanca',
          mediaType: 'movie',
          mediaId: 'movie-casablanca',
          sourceMediaSourceId: 'src-casablanca',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'VERIFYING',
          totalBytes: BigInt.from(5),
          bytesTransferred: drift.Value(BigInt.from(5)),
          startedAt: DateTime.now(),
        ),
      );

      final results = await transferService.reconcileTransfers();
      expect(results.length, 1);
      expect(results.first.state, TransferState.completed);
      expect(results.first.destinationPath, destPath);

      expect(File(destPath).existsSync(), true);
      expect(File(destPath).lengthSync(), 5);
      expect(tempFile.existsSync(), false);

      final job = await db.getTransferJobById('job-casablanca');
      expect(job!.status, 'COMPLETED');
    });

    test('interrupted TRANSFERRING job with partial file is marked FAILED and partial cleaned', () async {
      final destRel = p.join('movies', 'Goodfellas (1990)', 'Goodfellas.mkv');
      final destPath = p.normalize(p.join(deviceDestDir.path, destRel));
      final tempPath = '$destPath.reelhouse-partial';

      final tempFile = File(tempPath)..parent.createSync(recursive: true);
      tempFile.writeAsBytesSync([1, 2, 3]); // partial 3 of 100 bytes

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-goodfellas',
          mediaType: 'movie',
          mediaId: 'movie-goodfellas',
          sourceMediaSourceId: 'src-goodfellas',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'TRANSFERRING',
          totalBytes: BigInt.from(100),
          bytesTransferred: drift.Value(BigInt.from(3)),
          startedAt: DateTime.now(),
        ),
      );

      final results = await transferService.reconcileTransfers();
      expect(results.length, 1);
      expect(results.first.state, TransferState.failed);
      expect(results.first.error, contains('interrupted before completion'));

      // Partial file cleaned up so retry starts fresh
      expect(tempFile.existsSync(), false);
      expect(File(destPath).existsSync(), false);

      final job = await db.getTransferJobById('job-goodfellas');
      expect(job!.status, 'FAILED');
    });

    test(
      'interrupted TRANSFERRING job with no partial file is marked FAILED',
      () async {
        final destRel = p.join('movies', 'Scarface (1983)', 'Scarface.mkv');

        await db.upsertTransferJob(
          TransferJobsCompanion.insert(
            id: 'job-scarface',
            mediaType: 'movie',
            mediaId: 'movie-scarface',
            sourceMediaSourceId: 'src-scarface',
            destinationStorageId: 'device-storage-internal',
            destinationRelativePath: destRel,
            status: 'TRANSFERRING',
            totalBytes: BigInt.from(100),
            bytesTransferred: drift.Value(BigInt.zero),
            startedAt: DateTime.now(),
          ),
        );

        final results = await transferService.reconcileTransfers();
        expect(results.length, 1);
        expect(results.first.state, TransferState.failed);

        final job = await db.getTransferJobById('job-scarface');
        expect(job!.status, 'FAILED');
      },
    );

    test('cancelled job in database is NEVER promoted to COMPLETED during recovery', () async {
      final destRel = p.join('movies', 'Heat (1995)', 'Heat.mkv');
      final destPath = p.normalize(p.join(deviceDestDir.path, destRel));
      final tempPath = '$destPath.reelhouse-partial';

      final tempFile = File(tempPath)..parent.createSync(recursive: true);
      tempFile.writeAsBytesSync([1, 2, 3, 4]); // has 4 bytes

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-heat-cancelled',
          mediaType: 'movie',
          mediaId: 'movie-heat',
          sourceMediaSourceId: 'src-heat',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'CANCELLED',
          totalBytes: BigInt.from(4),
          bytesTransferred: drift.Value(BigInt.from(4)),
          error: const drift.Value('User cancelled'),
          startedAt: DateTime.now(),
        ),
      );

      final results = await transferService.reconcileTransfers();
      expect(results, isEmpty);

      final job = await db.getTransferJobById('job-heat-cancelled');
      expect(job!.status, 'CANCELLED');
      expect(File(destPath).existsSync(), false);
    });

    test('source disk disconnection does not prevent finalizing valid local partial in VERIFYING state', () async {
      // Disconnect source disk
      storageIdentityService.connectedMap[p.normalize(sourceDiskDir.path)] =
          false;

      final destRel = p.join('movies', 'Fargo (1996)', 'Fargo.mkv');
      final destPath = p.normalize(p.join(deviceDestDir.path, destRel));
      final tempPath = '$destPath.reelhouse-partial';

      final tempFile = File(tempPath)..parent.createSync(recursive: true);
      tempFile.writeAsBytesSync([1, 2, 3]);

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-fargo',
          mediaType: 'movie',
          mediaId: 'movie-fargo',
          sourceMediaSourceId: 'src-fargo',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'VERIFYING',
          totalBytes: BigInt.from(3),
          bytesTransferred: drift.Value(BigInt.from(3)),
          startedAt: DateTime.now(),
        ),
      );

      final results = await transferService.reconcileTransfers();
      expect(results.length, 1);
      expect(results.first.state, TransferState.completed);
      expect(File(destPath).existsSync(), true);
    });
  });

  group('M5.3 — Stale & Orphan Partials Cleanup', () {
    test(
      'cleanStalePartials removes unowned .reelhouse-partial files',
      () async {
        final orphanFile1 = File(
          p.join(
            deviceDestDir.path,
            'movies',
            'OldMovie (2000)',
            'OldMovie.mkv.reelhouse-partial',
          ),
        )..parent.createSync(recursive: true);
        orphanFile1.writeAsBytesSync([1, 2, 3]);

        final orphanFile2 = File(
          p.join(
            deviceDestDir.path,
            'tv_shows',
            'OldShow',
            'Season 01',
            'S01E01.mkv.reelhouse-partial',
          ),
        )..parent.createSync(recursive: true);
        orphanFile2.writeAsBytesSync([4, 5, 6]);

        expect(orphanFile1.existsSync(), true);
        expect(orphanFile2.existsSync(), true);

        final cleanedCount = await transferService.cleanStalePartials();
        expect(cleanedCount, 2);

        expect(orphanFile1.existsSync(), false);
        expect(orphanFile2.existsSync(), false);
      },
    );
  });
}
