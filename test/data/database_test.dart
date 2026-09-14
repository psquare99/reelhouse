import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory sqlite database for fast, isolated test execution
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Schema & Core Operations', () {
    test('seeds This Device on creation', () async {
      final storages = await db.getAllStorages();
      expect(storages.length, 1);
      final local = storages.first;
      expect(local.id, 'local-device');
      expect(local.name, 'This Device');
      expect(local.storageType, 'DEVICE_LOCAL_STORAGE');
      expect(local.filesystemIdentifier, 'internal-app-storage');
      expect(local.available, true);
    });

    test('supports logical movie with multiple physical media sources (HDD + local copy)', () async {
      // 1. Add external storage
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'hdd-movies',
              name: 'Movies HDD',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: '0x5484AB12',
              rootUri: r'D:\Movies',
              lastSeenAt: DateTime.now(),
              available: const drift.Value(true),
            ),
          );

      // 2. Add movie
      final now = DateTime.now();
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'movie-interstellar',
              title: 'Interstellar',
              year: const drift.Value(2014),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 3. Add physical source A (on external HDD)
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-interstellar-hdd',
              movieId: const drift.Value('movie-interstellar'),
              storageId: 'hdd-movies',
              sourceType: 'removableStorage',
              relativePath: r'Interstellar (2014)\Interstellar.mkv',
              filename: 'Interstellar.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(14000000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // 4. Add physical source B (on local device storage)
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-interstellar-local',
              movieId: const drift.Value('movie-interstellar'),
              storageId: 'local-device',
              sourceType: 'localDevice',
              relativePath: 'interstellar.mkv',
              filename: 'interstellar.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(14000000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      final sources = await db.getSourcesForMovie('movie-interstellar');
      expect(sources.length, 2);

      final hddSource = sources.firstWhere(
        (s) => s.sourceType == 'removableStorage',
      );
      final localSource = sources.firstWhere(
        (s) => s.sourceType == 'localDevice',
      );

      expect(hddSource.storageId, 'hdd-movies');
      expect(localSource.storageId, 'local-device');
    });

    test('records transient TransferJob separately from MediaSource', () async {
      final now = DateTime.now();

      // Ensure storage and dummy source exist for foreign keys
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'usb-1',
              name: 'USB Drive',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: '1234-5678',
              rootUri: r'E:\Media',
              lastSeenAt: now,
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm1',
              title: 'Inception',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-inception-usb',
              movieId: const drift.Value('m1'),
              storageId: 'usb-1',
              sourceType: 'removableStorage',
              relativePath: 'Inception.mkv',
              filename: 'Inception.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(8000000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Create a transfer job
      await db
          .into(db.transferJobs)
          .insert(
            TransferJobsCompanion.insert(
              id: 'job-1',
              mediaType: 'movie',
              mediaId: 'm1',
              sourceMediaSourceId: 'src-inception-usb',
              destinationStorageId: 'local-device',
              destinationRelativePath: 'inception.mkv',
              status: 'DOWNLOADING',
              totalBytes: BigInt.from(8000000000),
              bytesTransferred: drift.Value(BigInt.from(3400000000)),
              startedAt: now,
            ),
          );

      final jobs = await db.select(db.transferJobs).get();
      expect(jobs.length, 1);
      final job = jobs.first;
      expect(job.status, 'DOWNLOADING');
      expect(job.bytesTransferred, BigInt.from(3400000000));
      expect(job.destinationStorageId, 'local-device');
    });
  });
}
