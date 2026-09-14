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

    test(
      'updates and queries user state (favorite, watchlist, watch state)',
      () async {
        final now = DateTime.now();
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-avatar',
                title: 'Avatar',
                year: const drift.Value(2009),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Default state
        var movie = await db.findMovieById('m-avatar');
        expect(movie!.isFavorite, false);
        expect(movie.isWatchlist, false);
        expect(movie.watchState, 'UNWATCHED');

        // Update favorite & watchlist
        await db.toggleMovieFavorite('m-avatar', true);
        await db.toggleMovieWatchlist('m-avatar', true);
        await db.setMovieWatchState(
          'm-avatar',
          'IN_PROGRESS',
          positionSeconds: 1200,
        );

        movie = await db.findMovieById('m-avatar');
        expect(movie!.isFavorite, true);
        expect(movie.isWatchlist, true);
        expect(movie.watchState, 'IN_PROGRESS');
        expect(movie.playbackPositionSeconds, 1200);

        final inProgress = await db.watchContinueWatchingMovies().first;
        expect(inProgress.length, 1);
        expect(inProgress.first.id, 'm-avatar');
      },
    );

    test('manages curated collections and items', () async {
      final now = DateTime.now();
      await db.createCollection(
        CollectionsCompanion.insert(
          id: 'col-scifi',
          name: 'Sci-Fi Classics',
          overview: const drift.Value('Best sci-fi films of all time'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final collections = await db.getAllCollections();
      expect(collections.length, 1);
      expect(collections.first.name, 'Sci-Fi Classics');

      // Add movie reference
      await db.addItemToCollection(
        CollectionItemsCompanion.insert(
          id: 'item-1',
          collectionId: 'col-scifi',
          movieId: const drift.Value('m-avatar'),
          addedAt: now,
        ),
      );

      var items = await db.getItemsForCollection('col-scifi');
      expect(items.length, 1);
      expect(items.first.movieId, 'm-avatar');

      // Remove item
      await db.removeItemFromCollection('col-scifi', movieId: 'm-avatar');
      items = await db.getItemsForCollection('col-scifi');
      expect(items.isEmpty, true);

      // Delete collection
      await db.deleteCollection('col-scifi');
      final remaining = await db.getAllCollections();
      expect(remaining.isEmpty, true);
    });

    test('searches local library across movies and tv shows', () async {
      final now = DateTime.now();
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-matrix',
              title: 'The Matrix',
              overview: const drift.Value(
                'A computer hacker learns about the true nature of reality.',
              ),
              year: const drift.Value(1999),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-dark',
              title: 'Dark',
              overview: const drift.Value(
                'A family saga with a supernatural twist.',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final movieResults = await db.searchMovies('matrix');
      expect(movieResults.length, 1);
      expect(movieResults.first.title, 'The Matrix');

      final showResults = await db.searchTvShows('dark');
      expect(showResults.length, 1);
      expect(showResults.first.title, 'Dark');

      final overviewSearch = await db.searchMovies('hacker');
      expect(overviewSearch.length, 1);
      expect(overviewSearch.first.id, 'm-matrix');
    });
  });
}
