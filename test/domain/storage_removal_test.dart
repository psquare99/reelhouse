import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';

void main() {
  late AppDatabase db;
  late DriftLibraryRepository repository;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftLibraryRepository(db);
    tempDir = await Directory.systemTemp.createTemp('reelhouse_storage_test_');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Storage Location Removal Domain Logic', () {
    test('Removes storage, associated media sources, and orphaned single-source movie', () async {
      final storageId = 'ext-hdd-1';
      final movieId = 'movie-matrix-1';

      // Seed external storage
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: storageId,
              name: 'Western Digital 4TB',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'WD-4TB-001',
              rootUri: 'E:\\Movies',
              lastSeenAt: DateTime.now(),
            ),
          );

      // Seed Movie
      final now = DateTime.now();
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: movieId,
              detectedTitle: 'The Matrix',
              title: const drift.Value('The Matrix'),
              year: const drift.Value(1999),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Seed Collection & Collection Item
      final colId = 'col-favorites';
      await db
          .into(db.collections)
          .insert(
            CollectionsCompanion.insert(
              id: colId,
              name: 'Sci-Fi Classics',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.collectionItems)
          .insert(
            CollectionItemsCompanion.insert(
              id: 'ci-1',
              collectionId: colId,
              movieId: drift.Value(movieId),
              addedAt: now,
            ),
          );

      // Seed MediaSource on ext-hdd-1
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-matrix-hdd',
              movieId: drift.Value(movieId),
              storageId: storageId,
              sourceType: 'removableStorage',
              relativePath: 'The Matrix (1999).mp4',
              filename: 'The Matrix (1999).mp4',
              extension: 'mp4',
              fileSize: BigInt.from(1024 * 1024 * 100),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Verify pre-removal state
      expect(await db.getStorageById(storageId), isNotNull);
      expect(await db.getMediaSourceById('src-matrix-hdd'), isNotNull);
      expect(
        await (db.select(
          db.movies,
        )..where((m) => m.id.equals(movieId))).getSingleOrNull(),
        isNotNull,
      );
      expect(
        await (db.select(
          db.collectionItems,
        )..where((ci) => ci.movieId.equals(movieId))).get(),
        isNotEmpty,
      );

      // Execute removal
      await repository.removeStorage(storageId);

      // Verify post-removal state
      expect(await db.getStorageById(storageId), isNull);
      expect(await db.getMediaSourceById('src-matrix-hdd'), isNull);
      expect(
        await (db.select(
          db.movies,
        )..where((m) => m.id.equals(movieId))).getSingleOrNull(),
        isNull,
      );
      expect(
        await (db.select(
          db.collectionItems,
        )..where((ci) => ci.movieId.equals(movieId))).get(),
        isEmpty,
      );
    });

    test('Multi-source movie preservation: retains movie and user state when another source exists', () async {
      final storage1Id = 'ext-hdd-1';
      final movieId = 'movie-inception-1';
      final now = DateTime.now();

      // Seed external storage 1
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: storage1Id,
              name: 'HDD 1',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'HDD-1',
              rootUri: 'E:\\Movies',
              lastSeenAt: now,
            ),
          );

      // Seed Movie with IN_PROGRESS watch state and favorite
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: movieId,
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              year: const drift.Value(2010),
              isFavorite: const drift.Value(true),
              watchState: const drift.Value('IN_PROGRESS'),
              playbackPositionSeconds: const drift.Value(1234),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Seed Source 1 on ext-hdd-1
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-inception-hdd',
              movieId: drift.Value(movieId),
              storageId: storage1Id,
              sourceType: 'removableStorage',
              relativePath: 'Inception (2010).mkv',
              filename: 'Inception (2010).mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1024 * 1024 * 200),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Seed Source 2 on local-device
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-inception-local',
              movieId: drift.Value(movieId),
              storageId: 'local-device',
              sourceType: 'localDevice',
              relativePath: 'offline/Inception (2010).mkv',
              filename: 'Inception (2010).mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1024 * 1024 * 200),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Remove storage 1
      await repository.removeStorage(storage1Id);

      // Verify storage 1 and its source are deleted
      expect(await db.getStorageById(storage1Id), isNull);
      expect(await db.getMediaSourceById('src-inception-hdd'), isNull);

      // Verify local source remains
      expect(await db.getMediaSourceById('src-inception-local'), isNotNull);

      // Verify Movie and user state (isFavorite, watchState, playbackPositionSeconds) remain completely intact
      final movie = await (db.select(
        db.movies,
      )..where((m) => m.id.equals(movieId))).getSingleOrNull();
      expect(movie, isNotNull);
      expect(movie!.title, 'Inception');
      expect(movie.isFavorite, isTrue);
      expect(movie.watchState, 'IN_PROGRESS');
      expect(movie.playbackPositionSeconds, 1234);
    });

    test('TV show cascade: removes orphaned episodes, empty seasons, and empty show', () async {
      final storageId = 'ext-tv-storage';
      final now = DateTime.now();

      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: storageId,
              name: 'TV Shows Drive',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'TV-DRIVE-01',
              rootUri: 'F:\\TV',
              lastSeenAt: now,
            ),
          );

      final showId = 'show-breaking-bad';
      final seasonId = 'season-bb-1';
      final ep1Id = 'ep-bb-s01e01';

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: showId,
              detectedTitle: 'Breaking Bad',
              title: const drift.Value('Breaking Bad'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: seasonId,
              showId: showId,
              seasonNumber: 1,
              name: const drift.Value('Season 1'),
            ),
          );

      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: ep1Id,
              seasonId: seasonId,
              episodeNumber: 1,
              name: const drift.Value('Pilot'),
            ),
          );

      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-bb-s01e01',
              episodeId: drift.Value(ep1Id),
              storageId: storageId,
              sourceType: 'removableStorage',
              relativePath: 'Breaking Bad/S01E01.mkv',
              filename: 'S01E01.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      await repository.removeStorage(storageId);

      expect(
        await (db.select(
          db.episodes,
        )..where((e) => e.id.equals(ep1Id))).getSingleOrNull(),
        isNull,
      );
      expect(
        await (db.select(
          db.seasons,
        )..where((s) => s.id.equals(seasonId))).getSingleOrNull(),
        isNull,
      );
      expect(
        await (db.select(
          db.tvShows,
        )..where((t) => t.id.equals(showId))).getSingleOrNull(),
        isNull,
      );
    });

    test('TV show partial preservation: retains show and season if other episodes exist', () async {
      final storage1Id = 'ext-tv-storage-1';
      final storage2Id = 'ext-tv-storage-2';
      final now = DateTime.now();

      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: storage1Id,
              name: 'TV Drive 1',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'TV-1',
              rootUri: 'F:\\TV1',
              lastSeenAt: now,
            ),
          );
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: storage2Id,
              name: 'TV Drive 2',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'TV-2',
              rootUri: 'F:\\TV2',
              lastSeenAt: now,
            ),
          );

      final showId = 'show-got';
      final seasonId = 'season-got-1';
      final ep1Id = 'ep-got-s01e01';
      final ep2Id = 'ep-got-s01e02';

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: showId,
              detectedTitle: 'Game of Thrones',
              title: const drift.Value('Game of Thrones'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: seasonId,
              showId: showId,
              seasonNumber: 1,
            ),
          );

      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: ep1Id,
              seasonId: seasonId,
              episodeNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: ep2Id,
              seasonId: seasonId,
              episodeNumber: 2,
            ),
          );

      // Ep 1 on storage 1
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-got-ep1',
              episodeId: drift.Value(ep1Id),
              storageId: storage1Id,
              sourceType: 'removableStorage',
              relativePath: 'S01E01.mkv',
              filename: 'S01E01.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Ep 2 on storage 2
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-got-ep2',
              episodeId: drift.Value(ep2Id),
              storageId: storage2Id,
              sourceType: 'removableStorage',
              relativePath: 'S01E02.mkv',
              filename: 'S01E02.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Remove storage 1
      await repository.removeStorage(storage1Id);

      // Ep 1 should be gone
      expect(
        await (db.select(
          db.episodes,
        )..where((e) => e.id.equals(ep1Id))).getSingleOrNull(),
        isNull,
      );
      // Ep 2, Season 1, and Show should remain
      expect(
        await (db.select(
          db.episodes,
        )..where((e) => e.id.equals(ep2Id))).getSingleOrNull(),
        isNotNull,
      );
      expect(
        await (db.select(
          db.seasons,
        )..where((s) => s.id.equals(seasonId))).getSingleOrNull(),
        isNotNull,
      );
      expect(
        await (db.select(
          db.tvShows,
        )..where((t) => t.id.equals(showId))).getSingleOrNull(),
        isNotNull,
      );
    });

    test(
      'Cleans up associated transfer jobs referencing removed storage',
      () async {
        final storageId = 'ext-hdd-jobs';
        final now = DateTime.now();

        await db
            .into(db.storages)
            .insert(
              StoragesCompanion.insert(
                id: storageId,
                name: 'HDD with Jobs',
                storageType: 'REMOVABLE_VOLUME',
                filesystemIdentifier: 'HDD-JOB-1',
                rootUri: 'E:\\Movies',
                lastSeenAt: now,
              ),
            );

        final movieId = 'movie-job-test';
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: movieId,
                detectedTitle: 'Job Movie',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await db
            .into(db.mediaSources)
            .insert(
              MediaSourcesCompanion.insert(
                id: 'src-job-test',
                movieId: drift.Value(movieId),
                storageId: storageId,
                sourceType: 'removableStorage',
                relativePath: 'job.mp4',
                filename: 'job.mp4',
                extension: 'mp4',
                fileSize: BigInt.from(500),
                createdAt: now,
                firstSeenAt: now,
                lastSeenAt: now,
              ),
            );

        await db
            .into(db.transferJobs)
            .insert(
              TransferJobsCompanion.insert(
                id: 'job-1',
                mediaType: 'movie',
                mediaId: movieId,
                sourceMediaSourceId: 'src-job-test',
                destinationStorageId: 'local-device',
                destinationRelativePath: 'offline/job.mp4',
                status: 'DOWNLOADING',
                totalBytes: BigInt.from(500),
                startedAt: now,
              ),
            );

        await repository.removeStorage(storageId);

        expect(await db.getTransferJobById('job-1'), isNull);
      },
    );

    test('Never deletes or modifies physical files on disk', () async {
      final diskMovieFile = File(p.join(tempDir.path, 'PhysicalMovie.mkv'));
      await diskMovieFile.writeAsString('Dummy video file content');
      expect(diskMovieFile.existsSync(), isTrue);

      final storageId = 'ext-physical-test';
      final now = DateTime.now();

      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: storageId,
              name: 'Physical Test Drive',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'PHYS-01',
              rootUri: tempDir.path,
              lastSeenAt: now,
            ),
          );

      final movieId = 'phys-movie-1';
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: movieId,
              detectedTitle: 'Physical Movie',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-phys-1',
              movieId: drift.Value(movieId),
              storageId: storageId,
              sourceType: 'removableStorage',
              relativePath: 'PhysicalMovie.mkv',
              filename: 'PhysicalMovie.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(diskMovieFile.lengthSync()),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Perform removal
      await repository.removeStorage(storageId);

      // Verify DB record removed
      expect(await db.getStorageById(storageId), isNull);

      // Verify physical disk file is STILL COMPLETELY INTACT
      expect(diskMovieFile.existsSync(), isTrue);
      expect(await diskMovieFile.readAsString(), 'Dummy video file content');
    });

    test(
      'Shields DEVICE_LOCAL_STORAGE from removal and throws UnsupportedError',
      () async {
        expect(
          () => repository.removeStorage('local-device'),
          throwsA(isA<UnsupportedError>()),
        );

        // Verify local-device is still in database
        final deviceStorage = await db.getDeviceStorage();
        expect(deviceStorage, isNotNull);
        expect(deviceStorage!.id, 'local-device');
      },
    );

    test('Non-existent storage ID is a safe no-op', () async {
      await repository.removeStorage('non-existent-storage-id');
      // No exceptions thrown
    });
  });
}
