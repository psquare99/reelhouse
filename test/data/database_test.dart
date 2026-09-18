import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/domain/models/identification_status.dart';

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
              detectedTitle: 'Interstellar',
              title: const drift.Value('Interstellar'),
              year: const drift.Value(2014),
              detectedYear: const drift.Value(2014),
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
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
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
                detectedTitle: 'Avatar',
                title: const drift.Value('Avatar'),
                year: const drift.Value(2009),
                detectedYear: const drift.Value(2009),
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
              detectedTitle: 'The Matrix',
              title: const drift.Value('The Matrix'),
              overview: const drift.Value(
                'A computer hacker learns about the true nature of reality.',
              ),
              year: const drift.Value(1999),
              detectedYear: const drift.Value(1999),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-dark',
              detectedTitle: 'Dark',
              title: const drift.Value('Dark'),
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

    test('watchOfflineMovies and watchOfflineTvShows reflect only available device-local copies', () async {
      final now = DateTime.now();

      // 1. Storage: external HDD and local device
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'hdd-ext',
              name: 'External HDD',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'HDD-01',
              rootUri: r'D:\Movies',
              lastSeenAt: now,
            ),
          );

      // 2. Movie 1: only on external HDD (should NOT be offline)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-external-only',
              detectedTitle: 'Gladiator',
              title: const drift.Value('Gladiator'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-glad-hdd',
              movieId: const drift.Value('m-external-only'),
              storageId: 'hdd-ext',
              sourceType: 'removableStorage',
              relativePath: 'Gladiator.mkv',
              filename: 'Gladiator.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // 3. Movie 2: has device-local copy (SHOULD be offline)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-local-copy',
              detectedTitle: 'Blade Runner',
              title: const drift.Value('Blade Runner'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-br-local',
              movieId: const drift.Value('m-local-copy'),
              storageId: 'local-device',
              sourceType: 'localDevice',
              relativePath: 'Blade Runner.mkv',
              filename: 'Blade Runner.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(2000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // Verify watchOfflineMovies
      final offlineMovies = await db.watchOfflineMovies().first;
      expect(offlineMovies.length, 1);
      expect(offlineMovies.first.id, 'm-local-copy');
      expect(offlineMovies.first.title, 'Blade Runner');

      // Test metadata provenance storage & retrieval
      await db.updateMovieMetadata(
        'm-local-copy',
        tmdbId: 78,
        metadataProvider: 'TMDB',
        providerItemId: '78',
        metadataUpdatedAt: now,
      );

      final updatedMovie = await db.findMovieById('m-local-copy');
      expect(updatedMovie!.metadataProvider, 'TMDB');
      expect(updatedMovie.providerItemId, '78');
      expect(updatedMovie.metadataUpdatedAt, isNotNull);

      // 4. Test offline TV show
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-chernobyl',
              detectedTitle: 'Chernobyl',
              title: const drift.Value('Chernobyl'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 'season-chern-1',
              showId: 'tv-chernobyl',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-chern-1',
              seasonId: 'season-chern-1',
              episodeNumber: 1,
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-chern-local',
              episodeId: const drift.Value('ep-chern-1'),
              storageId: 'local-device',
              sourceType: 'localDevice',
              relativePath: 'Chernobyl S01E01.mkv',
              filename: 'Chernobyl S01E01.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1500000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      final offlineShows = await db.watchOfflineTvShows().first;
      expect(offlineShows.length, 1);
      expect(offlineShows.first.id, 'tv-chernobyl');
    });
  });

  group('Schema Version 6 & Canonical Media Identity & Curation', () {
    test('current schema version is 6', () {
      expect(db.schemaVersion, 6);
    });

    test('supports movie and TV show with NULL canonical title (unidentified item)', () async {
      final now = DateTime.now();

      // Movie with NULL canonical title, valid detectedTitle & detectedYear, PENDING status
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-unidentified',
              detectedTitle: 'Alien (1979) [1080p Remux]',
              detectedYear: const drift.Value(1979),
              title: const drift.Value(null),
              year: const drift.Value(null),
              identificationStatus: const drift.Value('PENDING'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // TV show with NULL canonical title, valid detectedTitle, PENDING status
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-unidentified',
              detectedTitle: 'Breaking Bad Season 1',
              title: const drift.Value(null),
              identificationStatus: const drift.Value('PENDING'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final movie = await db.findMovieById('m-unidentified');
      expect(movie, isNotNull);
      expect(movie!.title, isNull);
      expect(movie.year, isNull);
      expect(movie.detectedTitle, 'Alien (1979) [1080p Remux]');
      expect(movie.detectedYear, 1979);
      expect(movie.identificationStatus, 'PENDING');

      final show = await db.findTvShowById('tv-unidentified');
      expect(show, isNotNull);
      expect(show!.title, isNull);
      expect(show.detectedTitle, 'Breaking Bad Season 1');
      expect(show.identificationStatus, 'PENDING');
    });

    test('IdentificationStatus domain enum serialization and parsing', () {
      expect(
        IdentificationStatus.fromString('PENDING'),
        IdentificationStatus.pending,
      );
      expect(
        IdentificationStatus.fromString('IDENTIFIED'),
        IdentificationStatus.identified,
      );
      expect(
        IdentificationStatus.fromString('NEEDS_VERIFICATION'),
        IdentificationStatus.needsVerification,
      );
      expect(
        IdentificationStatus.fromString('UNKNOWN_FALLBACK'),
        IdentificationStatus.pending,
      );

      expect(IdentificationStatus.pending.toDbString(), 'PENDING');
      expect(IdentificationStatus.identified.toDbString(), 'IDENTIFIED');
      expect(
        IdentificationStatus.needsVerification.toDbString(),
        'NEEDS_VERIFICATION',
      );
    });

    test('migrates schema version 3 database to version 4 with legacy identity preservation', () async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final executor = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA user_version = 3;');
          rawDb.execute('''
              CREATE TABLE storages (
                id TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                storage_type TEXT NOT NULL,
                filesystem_identifier TEXT NOT NULL,
                root_uri TEXT NOT NULL,
                last_seen_at INTEGER NOT NULL,
                available INTEGER NOT NULL DEFAULT 1 CHECK ("available" IN (0, 1))
              );
              CREATE TABLE movies (
                id TEXT NOT NULL PRIMARY KEY,
                metadata_id TEXT,
                title TEXT NOT NULL,
                original_title TEXT,
                year INTEGER,
                overview TEXT,
                runtime INTEGER,
                release_date INTEGER,
                poster_path TEXT,
                backdrop_path TEXT,
                rating REAL,
                vote_count INTEGER,
                imdb_id TEXT,
                tmdb_id INTEGER,
                metadata_provider TEXT,
                provider_item_id TEXT,
                metadata_updated_at INTEGER,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                is_favorite INTEGER NOT NULL DEFAULT 0 CHECK ("is_favorite" IN (0, 1)),
                is_watchlist INTEGER NOT NULL DEFAULT 0 CHECK ("is_watchlist" IN (0, 1)),
                watch_state TEXT NOT NULL DEFAULT 'UNWATCHED',
                playback_position_seconds INTEGER NOT NULL DEFAULT 0
              );
              CREATE TABLE tv_shows (
                id TEXT NOT NULL PRIMARY KEY,
                metadata_id TEXT,
                title TEXT NOT NULL,
                original_title TEXT,
                overview TEXT,
                first_air_date INTEGER,
                poster_path TEXT,
                backdrop_path TEXT,
                rating REAL,
                tmdb_id INTEGER,
                imdb_id TEXT,
                metadata_provider TEXT,
                provider_item_id TEXT,
                metadata_updated_at INTEGER,
                is_favorite INTEGER NOT NULL DEFAULT 0 CHECK ("is_favorite" IN (0, 1)),
                is_watchlist INTEGER NOT NULL DEFAULT 0 CHECK ("is_watchlist" IN (0, 1)),
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              );
              CREATE TABLE seasons (
                id TEXT NOT NULL PRIMARY KEY,
                show_id TEXT NOT NULL REFERENCES tv_shows (id),
                season_number INTEGER NOT NULL,
                name TEXT,
                overview TEXT,
                poster_path TEXT,
                air_date INTEGER,
                tmdb_id INTEGER
              );
              CREATE TABLE episodes (
                id TEXT NOT NULL PRIMARY KEY,
                season_id TEXT NOT NULL REFERENCES seasons (id),
                episode_number INTEGER NOT NULL,
                name TEXT,
                overview TEXT,
                air_date INTEGER,
                runtime INTEGER,
                still_path TEXT,
                rating REAL,
                tmdb_id INTEGER,
                watch_state TEXT NOT NULL DEFAULT 'UNWATCHED',
                playback_position_seconds INTEGER NOT NULL DEFAULT 0
              );
              CREATE TABLE media_sources (
                id TEXT NOT NULL PRIMARY KEY,
                movie_id TEXT REFERENCES movies (id),
                episode_id TEXT REFERENCES episodes (id),
                storage_id TEXT NOT NULL REFERENCES storages (id),
                source_type TEXT NOT NULL,
                relative_path TEXT NOT NULL,
                filename TEXT NOT NULL,
                extension TEXT NOT NULL,
                file_size INTEGER NOT NULL,
                duration INTEGER,
                video_codec TEXT,
                audio_codec TEXT,
                resolution TEXT,
                audio_channels TEXT,
                subtitle_information TEXT,
                fingerprint TEXT,
                created_at INTEGER NOT NULL,
                first_seen_at INTEGER NOT NULL,
                last_seen_at INTEGER NOT NULL,
                available INTEGER NOT NULL DEFAULT 1 CHECK ("available" IN (0, 1))
              );
              CREATE TABLE collections (
                id TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                overview TEXT,
                poster_path TEXT,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              );
              CREATE TABLE collection_items (
                id TEXT NOT NULL PRIMARY KEY,
                collection_id TEXT NOT NULL REFERENCES collections (id),
                movie_id TEXT REFERENCES movies (id),
                tv_show_id TEXT REFERENCES tv_shows (id),
                display_order INTEGER NOT NULL DEFAULT 0,
                added_at INTEGER NOT NULL
              );
              CREATE TABLE transfer_jobs (
                id TEXT NOT NULL PRIMARY KEY,
                media_type TEXT NOT NULL,
                media_id TEXT NOT NULL,
                source_media_source_id TEXT NOT NULL REFERENCES media_sources (id),
                destination_storage_id TEXT NOT NULL REFERENCES storages (id),
                destination_relative_path TEXT NOT NULL,
                status TEXT NOT NULL,
                bytes_transferred INTEGER NOT NULL DEFAULT 0,
                total_bytes INTEGER NOT NULL,
                error TEXT,
                started_at INTEGER NOT NULL,
                completed_at INTEGER
              );
            ''');

          // Insert legacy test rows
          rawDb.execute('''
              INSERT INTO storages (id, name, storage_type, filesystem_identifier, root_uri, last_seen_at, available)
              VALUES ('storage-ext', 'USB Drive', 'REMOVABLE_VOLUME', 'USB-999', 'D:\\\\Movies', $nowMs, 1);

              INSERT INTO movies (id, title, year, tmdb_id, created_at, updated_at)
              VALUES ('m-matched-legacy', 'Inception', 2010, 27205, $nowMs, $nowMs);

              INSERT INTO movies (id, title, year, tmdb_id, created_at, updated_at)
              VALUES ('m-unmatched-legacy', 'Some.Raw.Rip.2021', 2021, NULL, $nowMs, $nowMs);

              INSERT INTO tv_shows (id, title, tmdb_id, created_at, updated_at)
              VALUES ('tv-matched-legacy', 'Breaking Bad', 1396, $nowMs, $nowMs);

              INSERT INTO tv_shows (id, title, tmdb_id, created_at, updated_at)
              VALUES ('tv-unmatched-legacy', 'Unknown.Series.S01', NULL, $nowMs, $nowMs);

              INSERT INTO media_sources (id, movie_id, storage_id, source_type, relative_path, filename, extension, file_size, created_at, first_seen_at, last_seen_at, available)
              VALUES ('src-legacy-1', 'm-matched-legacy', 'storage-ext', 'removableStorage', 'Inception (2010).mkv', 'Inception (2010).mkv', 'mkv', 5000000000, $nowMs, $nowMs, $nowMs, 1);
            ''');
        },
      );

      // Open via Drift AppDatabase — this triggers onUpgrade(from: 3, to: 4)
      final migratedDb = AppDatabase(executor);

      // 1. Verify legacy movie with tmdbId -> IDENTIFIED
      final matchedMovie = await migratedDb.findMovieById('m-matched-legacy');
      expect(matchedMovie, isNotNull);
      expect(matchedMovie!.title, 'Inception');
      expect(matchedMovie.year, 2010);
      expect(matchedMovie.detectedTitle, 'Inception');
      expect(matchedMovie.detectedYear, 2010);
      expect(matchedMovie.identificationStatus, 'IDENTIFIED');

      // 2. Verify legacy movie without tmdbId -> PENDING
      final unmatchedMovie = await migratedDb.findMovieById(
        'm-unmatched-legacy',
      );
      expect(unmatchedMovie, isNotNull);
      expect(unmatchedMovie!.title, 'Some.Raw.Rip.2021');
      expect(unmatchedMovie.year, 2021);
      expect(unmatchedMovie.detectedTitle, 'Some.Raw.Rip.2021');
      expect(unmatchedMovie.detectedYear, 2021);
      expect(unmatchedMovie.identificationStatus, 'PENDING');

      // 3. Verify legacy TV show with tmdbId -> IDENTIFIED
      final matchedShow = await migratedDb.findTvShowById('tv-matched-legacy');
      expect(matchedShow, isNotNull);
      expect(matchedShow!.title, 'Breaking Bad');
      expect(matchedShow.detectedTitle, 'Breaking Bad');
      expect(matchedShow.identificationStatus, 'IDENTIFIED');

      // 4. Verify legacy TV show without tmdbId -> PENDING
      final unmatchedShow = await migratedDb.findTvShowById(
        'tv-unmatched-legacy',
      );
      expect(unmatchedShow, isNotNull);
      expect(unmatchedShow!.title, 'Unknown.Series.S01');
      expect(unmatchedShow.detectedTitle, 'Unknown.Series.S01');
      expect(unmatchedShow.identificationStatus, 'PENDING');

      // 5. Verify media source relationship preserved
      final sources = await migratedDb.getSourcesForMovie('m-matched-legacy');
      expect(sources.length, 1);
      expect(sources.first.id, 'src-legacy-1');
      expect(sources.first.storageId, 'storage-ext');

      await migratedDb.close();
    });

    test('System Curation: discovered genres and franchises queries', () async {
      final now = DateTime.now();

      // Movie 1: Sci-Fi, Action, belongs to Star Wars collection
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-sw4',
              detectedTitle: 'Star Wars A New Hope',
              title: const drift.Value('Star Wars: A New Hope'),
              year: const drift.Value(1977),
              genres: const drift.Value('Action, Adventure, Science Fiction'),
              tmdbCollectionId: const drift.Value(10),
              tmdbCollectionName: const drift.Value('Star Wars Collection'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Movie 2: Sci-Fi, Adventure, belongs to Star Wars collection
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-sw5',
              detectedTitle: 'Star Wars Empire Strikes Back',
              title: const drift.Value('The Empire Strikes Back'),
              year: const drift.Value(1980),
              genres: const drift.Value('Action, Adventure, Science Fiction'),
              tmdbCollectionId: const drift.Value(10),
              tmdbCollectionName: const drift.Value('Star Wars Collection'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // TV Show: Sci-Fi, Drama
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-andor',
              detectedTitle: 'Andor',
              title: const drift.Value('Andor'),
              genres: const drift.Value('Drama, Science Fiction'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 1. Test getDiscoveredGenres
      final genres = await db.getDiscoveredGenres();
      expect(
        genres,
        containsAll(['Action', 'Adventure', 'Drama', 'Science Fiction']),
      );
      // Verify sorted alphabetically
      expect(genres, ['Action', 'Adventure', 'Drama', 'Science Fiction']);

      // 2. Test getDiscoveredFranchises
      final franchises = await db.getDiscoveredFranchises();
      expect(franchises.length, 1);
      expect(franchises.first.id, 10);
      expect(franchises.first.name, 'Star Wars Collection');
      expect(franchises.first.movieCount, 2);
    });

    test('recordMoviePlaybackLaunch updates lastPlayedAt and transitions unwatched to inProgress', () async {
      final now = DateTime(2026, 1, 1);
      final playedAt = DateTime(2026, 1, 2, 15, 30);

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-launch-test',
              detectedTitle: 'Launch Test',
              watchState: const drift.Value('UNWATCHED'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.recordMoviePlaybackLaunch('m-launch-test', playedAt: playedAt);

      final updated = await db.findMovieById('m-launch-test');
      expect(updated, isNotNull);
      expect(updated!.watchState, 'IN_PROGRESS');
      expect(updated.lastPlayedAt, playedAt);
      expect(updated.updatedAt, playedAt);

      // Now launch again on already in-progress movie — watchState should stay inProgress, lastPlayedAt should update
      final playedAt2 = DateTime(2026, 1, 3, 20, 0);
      await db.recordMoviePlaybackLaunch('m-launch-test', playedAt: playedAt2);

      final updated2 = await db.findMovieById('m-launch-test');
      expect(updated2!.watchState, 'IN_PROGRESS');
      expect(updated2.lastPlayedAt, playedAt2);
    });

    test('recordEpisodePlaybackLaunch updates lastPlayedAt and transitions unwatched to inProgress', () async {
      final now = DateTime(2026, 1, 1);
      final playedAt = DateTime(2026, 1, 2, 16, 45);

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-launch-show',
              detectedTitle: 'Launch Show',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 's-launch-1',
              showId: 'tv-launch-show',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-launch-test',
              seasonId: 's-launch-1',
              episodeNumber: 1,
              watchState: const drift.Value('UNWATCHED'),
            ),
          );

      await db.recordEpisodePlaybackLaunch('ep-launch-test', playedAt: playedAt);

      final updated = await db.findEpisodeById('ep-launch-test');
      expect(updated, isNotNull);
      expect(updated!.watchState, 'IN_PROGRESS');
      expect(updated.lastPlayedAt, playedAt);
    });
  });
}
