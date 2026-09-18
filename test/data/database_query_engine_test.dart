import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/domain/models/availability_status.dart';
import 'package:reelhouse/domain/query/query.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // Set up standard storages
    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'hdd-storage-1',
            name: 'Passport USB HDD',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: 'VOL_001',
            rootUri: r'E:\Media',
            lastSeenAt: DateTime(2026, 1, 1),
            available: const drift.Value(true),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Database Query Engine — Movie Queries', () {
    test('queryMovies returns all movies with availability projections and pagination', () async {
      final now = DateTime(2026, 1, 1);

      // Insert 3 movies:
      // Movie 1: Inception (local copy only -> availableLocally, watched, favorite)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'movie-inception',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              year: const drift.Value(2010),
              rating: const drift.Value(8.8),
              runtime: const drift.Value(148),
              isFavorite: const drift.Value(true),
              isWatchlist: const drift.Value(false),
              watchState: const drift.Value('WATCHED'),
              playbackPositionSeconds: const drift.Value(0),
              identificationStatus: const drift.Value('IDENTIFIED'),
              createdAt: now.subtract(const Duration(days: 10)),
              updatedAt: now.subtract(const Duration(days: 2)),
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'ms-inception-local',
              movieId: const drift.Value('movie-inception'),
              storageId: 'local-device',
              sourceType: 'localDevice',
              relativePath: 'Inception.2010.mkv',
              filename: 'Inception.2010.mkv',
              extension: '.mkv',
              fileSize: BigInt.from(5000000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // Movie 2: Interstellar (HDD copy + local copy -> availableOnMultipleSources, in_progress, watchlist)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'movie-interstellar',
              detectedTitle: 'Interstellar.2014',
              title: const drift.Value('Interstellar'),
              year: const drift.Value(2014),
              rating: const drift.Value(8.7),
              runtime: const drift.Value(169),
              isFavorite: const drift.Value(false),
              isWatchlist: const drift.Value(true),
              watchState: const drift.Value('IN_PROGRESS'),
              playbackPositionSeconds: const drift.Value(3600),
              identificationStatus: const drift.Value('IDENTIFIED'),
              createdAt: now.subtract(const Duration(days: 5)),
              updatedAt: now.subtract(const Duration(days: 1)),
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'ms-interstellar-local',
              movieId: const drift.Value('movie-interstellar'),
              storageId: 'local-device',
              sourceType: 'localDevice',
              relativePath: 'Interstellar.2014.mkv',
              filename: 'Interstellar.2014.mkv',
              extension: '.mkv',
              fileSize: BigInt.from(6000000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'ms-interstellar-hdd',
              movieId: const drift.Value('movie-interstellar'),
              storageId: 'hdd-storage-1',
              sourceType: 'removableStorage',
              relativePath: 'Interstellar.2014.mkv',
              filename: 'Interstellar.2014.mkv',
              extension: '.mkv',
              fileSize: BigInt.from(6000000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // Movie 3: Dunkirk (HDD copy only -> availableOnRemovableStorage, unwatched, unidentified)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'movie-dunkirk',
              detectedTitle: 'Dunkirk 2017',
              detectedYear: const drift.Value(2017),
              title: const drift.Value(null),
              isFavorite: const drift.Value(false),
              isWatchlist: const drift.Value(false),
              watchState: const drift.Value('UNWATCHED'),
              playbackPositionSeconds: const drift.Value(0),
              identificationStatus: const drift.Value('PENDING'),
              createdAt: now.subtract(const Duration(days: 1)),
              updatedAt: now.subtract(const Duration(days: 1)),
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'ms-dunkirk-hdd',
              movieId: const drift.Value('movie-dunkirk'),
              storageId: 'hdd-storage-1',
              sourceType: 'removableStorage',
              relativePath: 'Dunkirk.2017.mkv',
              filename: 'Dunkirk.2017.mkv',
              extension: '.mkv',
              fileSize: BigInt.from(4000000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // Query all (alphabetical by title asc)
      final allResult = await db.queryMovies(MovieQuery.all());
      expect(allResult.totalCount, equals(3));
      expect(allResult.items.length, equals(3));
      expect(allResult.items[0].displayTitle, equals('Dunkirk 2017'));
      expect(allResult.items[0].displayYear, equals(2017));
      expect(
        allResult.items[0].availability,
        equals(AvailabilityStatus.availableOnRemovableStorage),
      );
      expect(allResult.items[1].displayTitle, equals('Inception'));
      expect(
        allResult.items[1].availability,
        equals(AvailabilityStatus.availableLocally),
      );
      expect(allResult.items[2].displayTitle, equals('Interstellar'));
      expect(
        allResult.items[2].availability,
        equals(AvailabilityStatus.availableOnMultipleSources),
      );
    });

    test(
      'queryMovies pagination (limit, offset, hasMore, deterministic ordering)',
      () async {
        final now = DateTime(2026, 1, 1);
        for (var i = 1; i <= 5; i++) {
          await db
              .into(db.movies)
              .insert(
                MoviesCompanion.insert(
                  id: 'movie-$i',
                  detectedTitle: 'Film $i',
                  title: drift.Value('Film $i'),
                  year: drift.Value(2020 + i),
                  createdAt: now.subtract(Duration(days: i)),
                  updatedAt: now.subtract(Duration(days: i)),
                ),
              );
        }

        // Page 1: limit 2, offset 0
        final page1 = await db.queryMovies(
          MovieQuery.all(pagination: const PaginationSpec(limit: 2, offset: 0)),
        );
        expect(page1.totalCount, equals(5));
        expect(page1.items.length, equals(2));
        expect(page1.hasMore, isTrue);
        expect(page1.items[0].displayTitle, equals('Film 1'));
        expect(page1.items[1].displayTitle, equals('Film 2'));

        // Page 2: limit 2, offset 2
        final page2 = await db.queryMovies(
          MovieQuery.all(pagination: page1.pagination!.nextPage()),
        );
        expect(page2.totalCount, equals(5));
        expect(page2.items.length, equals(2));
        expect(page2.hasMore, isTrue);
        expect(page2.items[0].displayTitle, equals('Film 3'));
        expect(page2.items[1].displayTitle, equals('Film 4'));

        // Page 3: limit 2, offset 4
        final page3 = await db.queryMovies(
          MovieQuery.all(pagination: page2.pagination!.nextPage()),
        );
        expect(page3.totalCount, equals(5));
        expect(page3.items.length, equals(1));
        expect(page3.hasMore, isFalse);
        expect(page3.items[0].displayTitle, equals('Film 5'));
      },
    );

    test(
      'queryMovies Smart Views factories work through standard engine',
      () async {
        final now = DateTime(2026, 1, 1);

        // In-progress movie
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-progress',
                detectedTitle: 'Progress Movie',
                title: const drift.Value('Progress Movie'),
                watchState: const drift.Value('IN_PROGRESS'),
                playbackPositionSeconds: const drift.Value(1200),
                createdAt: now.subtract(const Duration(days: 10)),
                updatedAt: now.subtract(const Duration(hours: 1)),
              ),
            );

        // Unwatched movie
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-unwatched',
                detectedTitle: 'Unwatched Movie',
                title: const drift.Value('Unwatched Movie'),
                watchState: const drift.Value('UNWATCHED'),
                createdAt: now.subtract(const Duration(days: 2)),
                updatedAt: now.subtract(const Duration(days: 2)),
              ),
            );

        // Favorite movie
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-fav',
                detectedTitle: 'Fav Movie',
                title: const drift.Value('Fav Movie'),
                isFavorite: const drift.Value(true),
                createdAt: now.subtract(const Duration(days: 1)),
                updatedAt: now.subtract(const Duration(days: 1)),
              ),
            );

        // Test Continue Watching Smart View
        final continueWatching = await db.queryMovies(
          MovieQuery.continueWatching(),
        );
        expect(continueWatching.totalCount, equals(1));
        expect(continueWatching.items.first.id, equals('m-progress'));

        // Test Unwatched Smart View
        final unwatched = await db.queryMovies(MovieQuery.unwatched());
        expect(unwatched.items.any((m) => m.id == 'm-unwatched'), isTrue);
        expect(unwatched.items.any((m) => m.id == 'm-progress'), isFalse);

        // Test Favorites Smart View
        final favorites = await db.queryMovies(MovieQuery.favorites());
        expect(favorites.totalCount, equals(1));
        expect(favorites.items.first.id, equals('m-fav'));
      },
    );

    test('queryMovies filtering by collection membership', () async {
      final now = DateTime(2026, 1, 1);

      await db
          .into(db.collections)
          .insert(
            CollectionsCompanion.insert(
              id: 'col-marvel',
              name: 'Marvel Cinematic Universe',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-ironman',
              detectedTitle: 'Iron Man',
              title: const drift.Value('Iron Man'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-batman',
              detectedTitle: 'The Batman',
              title: const drift.Value('The Batman'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.collectionItems)
          .insert(
            CollectionItemsCompanion.insert(
              id: 'ci-1',
              collectionId: 'col-marvel',
              movieId: const drift.Value('m-ironman'),
              addedAt: now,
            ),
          );

      final result = await db.queryMovies(
        MovieQuery.forCollection('col-marvel'),
      );
      expect(result.totalCount, equals(1));
      expect(result.items.first.id, equals('m-ironman'));
    });

    test(
      'queryMovies filtering by genre and TMDB franchise collection',
      () async {
        final now = DateTime(2026, 1, 1);

        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-sw4',
                detectedTitle: 'Star Wars A New Hope',
                title: const drift.Value('Star Wars: A New Hope'),
                genres: const drift.Value('Action, Adventure, Science Fiction'),
                tmdbCollectionId: const drift.Value(10),
                tmdbCollectionName: const drift.Value('Star Wars Collection'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-godfather',
                detectedTitle: 'The Godfather',
                title: const drift.Value('The Godfather'),
                genres: const drift.Value('Crime, Drama'),
                tmdbCollectionId: const drift.Value(230),
                tmdbCollectionName: const drift.Value(
                  'The Godfather Collection',
                ),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Filter by genre 'Science Fiction'
        final sciFiResult = await db.queryMovies(
          const MovieQuery(filter: MovieFilter(genre: 'Science Fiction')),
        );
        expect(sciFiResult.totalCount, equals(1));
        expect(sciFiResult.items.first.id, equals('m-sw4'));
        expect(sciFiResult.items.first.genres, contains('Science Fiction'));

        // Filter by tmdbCollectionId 10
        final swResult = await db.queryMovies(
          const MovieQuery(filter: MovieFilter(tmdbCollectionId: 10)),
        );
        expect(swResult.totalCount, equals(1));
        expect(swResult.items.first.id, equals('m-sw4'));
        expect(
          swResult.items.first.tmdbCollectionName,
          equals('Star Wars Collection'),
        );
      },
    );

    test('queryMovies search (title mode and all mode)', () async {
      final now = DateTime(2026, 1, 1);

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-1',
              detectedTitle: 'Blade Runner 1982',
              title: const drift.Value('Blade Runner'),
              originalTitle: const drift.Value('Blade Runner Final Cut'),
              overview: const drift.Value(
                'A blade runner must pursue replicants.',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Search title mode: matches title
      final titleSearch = await db.queryMovies(MovieQuery.search('blade'));
      expect(titleSearch.totalCount, equals(1));
      expect(titleSearch.items.first.id, equals('m-1'));

      // Search title mode: searching overview text returns 0
      final titleSearchOverview = await db.queryMovies(
        MovieQuery.search('replicants', mode: SearchMode.title),
      );
      expect(titleSearchOverview.totalCount, equals(0));

      // Search all mode: searching overview text returns 1
      final allSearchOverview = await db.queryMovies(
        MovieQuery.search('replicants', mode: SearchMode.all),
      );
      expect(allSearchOverview.totalCount, equals(1));
      expect(allSearchOverview.items.first.id, equals('m-1'));
    });

    test('watchMovies streams reactive updates when library changes', () async {
      final stream = db.watchMovies(MovieQuery.all());

      // Initial state
      final firstEmission = await stream.first;
      expect(firstEmission.totalCount, equals(0));

      // Insert movie
      final now = DateTime(2026, 1, 1);
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-reactive',
              detectedTitle: 'Reactive Movie',
              title: const drift.Value('Reactive Movie'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Wait for next emission
      final secondEmission = await stream.firstWhere((r) => r.totalCount == 1);
      expect(secondEmission.items.first.id, equals('m-reactive'));
    });
  });

  group('Database Query Engine — TV Show Queries', () {
    test('queryTvShows computes derived watch state correctly', () async {
      final now = DateTime(2026, 1, 1);

      // TV Show 1: Fully Watched show (2 seasons, 3 episodes, all WATCHED)
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-breaking-bad',
              detectedTitle: 'Breaking Bad',
              title: const drift.Value('Breaking Bad'),
              firstAirDate: drift.Value(DateTime(2008, 1, 20)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 's-bb-1',
              showId: 'tv-breaking-bad',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-bb-1',
              seasonId: 's-bb-1',
              episodeNumber: 1,
              watchState: const drift.Value('WATCHED'),
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-bb-2',
              seasonId: 's-bb-1',
              episodeNumber: 2,
              watchState: const drift.Value('WATCHED'),
            ),
          );

      // TV Show 2: In-Progress show (1 season, 2 episodes, 1 WATCHED, 1 UNWATCHED)
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-severance',
              detectedTitle: 'Severance',
              title: const drift.Value('Severance'),
              firstAirDate: drift.Value(DateTime(2022, 2, 18)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 's-sev-1',
              showId: 'tv-severance',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-sev-1',
              seasonId: 's-sev-1',
              episodeNumber: 1,
              watchState: const drift.Value('WATCHED'),
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-sev-2',
              seasonId: 's-sev-1',
              episodeNumber: 2,
              watchState: const drift.Value('UNWATCHED'),
            ),
          );

      // TV Show 3: Unwatched show (1 season, 1 episode, UNWATCHED)
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-dark',
              detectedTitle: 'Dark',
              title: const drift.Value('Dark'),
              firstAirDate: drift.Value(DateTime(2017, 12, 1)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 's-dark-1',
              showId: 'tv-dark',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-dark-1',
              seasonId: 's-dark-1',
              episodeNumber: 1,
              watchState: const drift.Value('UNWATCHED'),
            ),
          );

      // Query all TV shows
      final allResult = await db.queryTvShows(TvShowQuery.all());
      expect(allResult.totalCount, equals(3));

      final bb = allResult.items.firstWhere((t) => t.id == 'tv-breaking-bad');
      expect(bb.derivedWatchState, equals(WatchState.watched));
      expect(bb.totalEpisodes, equals(2));
      expect(bb.totalSeasons, equals(1));

      final sev = allResult.items.firstWhere((t) => t.id == 'tv-severance');
      expect(sev.derivedWatchState, equals(WatchState.inProgress));

      final dark = allResult.items.firstWhere((t) => t.id == 'tv-dark');
      expect(dark.derivedWatchState, equals(WatchState.unwatched));

      // Filter by unwatched derived state
      final unwatchedResult = await db.queryTvShows(TvShowQuery.unwatched());
      expect(unwatchedResult.totalCount, equals(1));
      expect(unwatchedResult.items.first.id, equals('tv-dark'));
    });

    test('queryTvShows ignores extras (season_number < 0) for watch state aggregation and episode counts', () async {
      final now = DateTime(2026, 1, 1);

      // TV Show: 1 regular season with 1 WATCHED episode, and 1 Extras season (seasonNumber: -1) with 1 UNWATCHED episode
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-show-with-extras',
              detectedTitle: 'Show With Extras',
              title: const drift.Value('Show With Extras'),
              firstAirDate: drift.Value(DateTime(2020, 1, 1)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 's-swe-1',
              showId: 'tv-show-with-extras',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-swe-1',
              seasonId: 's-swe-1',
              episodeNumber: 1,
              watchState: const drift.Value('WATCHED'),
            ),
          );
      // Extras season (-1)
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 's-swe-extras',
              showId: 'tv-show-with-extras',
              seasonNumber: -1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-swe-extra-1',
              seasonId: 's-swe-extras',
              episodeNumber: 1,
              watchState: const drift.Value('UNWATCHED'),
            ),
          );

      final result = await db.queryTvShows(
        const TvShowQuery(
          filter: TvShowFilter(id: 'tv-show-with-extras'),
        ),
      );

      expect(result.totalCount, equals(1));
      final item = result.items.first;
      expect(item.totalSeasons, equals(1)); // Only season 1, not -1
      expect(item.totalEpisodes, equals(1)); // Only episode 1, not extra
      expect(item.derivedWatchState, equals(WatchState.watched)); // Derived as watched because all regular episodes are watched

      // Verify watch state filter
      final watchedFilterResult = await db.queryTvShows(
        const TvShowQuery(
          filter: TvShowFilter(
            id: 'tv-show-with-extras',
            watchStates: {WatchState.watched},
          ),
        ),
      );
      expect(watchedFilterResult.totalCount, equals(1));

      final unwatchedFilterResult = await db.queryTvShows(
        const TvShowQuery(
          filter: TvShowFilter(
            id: 'tv-show-with-extras',
            watchStates: {WatchState.unwatched},
          ),
        ),
      );
      expect(unwatchedFilterResult.totalCount, equals(0));
    });

    test('queryTvShows filtering by premiere year range', () async {
      final now = DateTime(2026, 1, 1);

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-old',
              detectedTitle: 'Old Show',
              title: const drift.Value('Old Show'),
              firstAirDate: drift.Value(DateTime(1995, 5, 1)),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-new',
              detectedTitle: 'New Show',
              title: const drift.Value('New Show'),
              firstAirDate: drift.Value(DateTime(2023, 10, 1)),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final result = await db.queryTvShows(
        const TvShowQuery(
          filter: TvShowFilter(yearRange: YearRange.since(2020)),
        ),
      );
      expect(result.totalCount, equals(1));
      expect(result.items.first.id, equals('tv-new'));
    });

    test('queryTvShows filtering by genre', () async {
      final now = DateTime(2026, 1, 1);

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-sci',
              detectedTitle: 'Severance',
              title: const drift.Value('Severance'),
              genres: const drift.Value('Drama, Mystery, Science Fiction'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-com',
              detectedTitle: 'Ted Lasso',
              title: const drift.Value('Ted Lasso'),
              genres: const drift.Value('Comedy, Drama'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final mysteryResult = await db.queryTvShows(
        const TvShowQuery(filter: TvShowFilter(genre: 'Mystery')),
      );
      expect(mysteryResult.totalCount, equals(1));
      expect(mysteryResult.items.first.id, equals('tv-sci'));
      expect(mysteryResult.items.first.genres, contains('Mystery'));

      final comedyResult = await db.queryTvShows(
        const TvShowQuery(filter: TvShowFilter(genre: 'Comedy')),
      );
      expect(comedyResult.totalCount, equals(1));
      expect(comedyResult.items.first.id, equals('tv-com'));
    });

    test('queryTvShows Title mode searches title identity only while All Fields includes overview', () async {
      final now = DateTime(2026, 1, 1);

      // Show 1: 'From'
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-from',
              detectedTitle: 'From',
              title: const drift.Value('From'),
              overview: const drift.Value(
                'Unravel the mystery of a nightmarish town.',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Show 2: 'Friends' (overview contains 'from')
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-friends',
              detectedTitle: 'Friends',
              title: const drift.Value('Friends'),
              overview: const drift.Value(
                'Six friends navigate life from their Manhattan apartment.',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Show 3: 'Spartacus' (overview contains 'from')
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-spartacus',
              detectedTitle: 'Spartacus',
              title: const drift.Value('Spartacus'),
              overview: const drift.Value(
                'A Thracian gladiator leads a rebellion from slavery.',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Show 4: 'The Walking Dead' (overview contains 'from')
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-twd',
              detectedTitle: 'The Walking Dead',
              title: const drift.Value('The Walking Dead'),
              overview: const drift.Value(
                'Survivors struggle to stay safe from walkers.',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 1. Title mode (default): searching 'from' returns ONLY 'From'
      final titleSearch = await db.queryTvShows(
        TvShowQuery.search('from', mode: SearchMode.title),
      );
      expect(titleSearch.totalCount, equals(1));
      expect(titleSearch.items.first.id, equals('tv-from'));

      // 2. Default factory also uses Title mode:
      final defaultSearch = await db.queryTvShows(TvShowQuery.search('from'));
      expect(defaultSearch.totalCount, equals(1));
      expect(defaultSearch.items.first.id, equals('tv-from'));

      // 3. All Fields mode: searching 'from' broadens and matches all 4 shows
      final allSearch = await db.queryTvShows(
        TvShowQuery.search('from', mode: SearchMode.all),
      );
      expect(allSearch.totalCount, equals(4));
      final allIds = allSearch.items.map((i) => i.id).toSet();
      expect(
        allIds,
        containsAll({'tv-from', 'tv-friends', 'tv-spartacus', 'tv-twd'}),
      );
    });
  });

  group('Database Query Engine — Season & Episode Queries', () {
    test(
      'querySeasons and queryEpisodes return ordered items for a show',
      () async {
        final now = DateTime(2026, 1, 1);

        await db
            .into(db.tvShows)
            .insert(
              TvShowsCompanion.insert(
                id: 'tv-show-1',
                detectedTitle: 'Test Show',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await db
            .into(db.seasons)
            .insert(
              SeasonsCompanion.insert(
                id: 's-2',
                showId: 'tv-show-1',
                seasonNumber: 2,
                name: const drift.Value('Season 2'),
              ),
            );
        await db
            .into(db.seasons)
            .insert(
              SeasonsCompanion.insert(
                id: 's-1',
                showId: 'tv-show-1',
                seasonNumber: 1,
                name: const drift.Value('Season 1'),
              ),
            );

        await db
            .into(db.episodes)
            .insert(
              EpisodesCompanion.insert(
                id: 'ep-2',
                seasonId: 's-1',
                episodeNumber: 2,
                name: const drift.Value('Episode 2'),
                watchState: const drift.Value('IN_PROGRESS'),
                playbackPositionSeconds: const drift.Value(450),
              ),
            );
        await db
            .into(db.episodes)
            .insert(
              EpisodesCompanion.insert(
                id: 'ep-1',
                seasonId: 's-1',
                episodeNumber: 1,
                name: const drift.Value('Episode 1'),
                watchState: const drift.Value('WATCHED'),
              ),
            );

        // Query seasons
        final seasonsResult = await db.querySeasons(
          SeasonQuery.forShow('tv-show-1'),
        );
        expect(seasonsResult.totalCount, equals(2));
        expect(seasonsResult.items[0].seasonNumber, equals(1));
        expect(seasonsResult.items[1].seasonNumber, equals(2));

        // Query episodes for season 1
        final episodesResult = await db.queryEpisodes(
          EpisodeQuery.forSeason('s-1'),
        );
        expect(episodesResult.totalCount, equals(2));
        expect(episodesResult.items[0].episodeNumber, equals(1));
        expect(episodesResult.items[1].episodeNumber, equals(2));
        expect(
          episodesResult.items[1].watchState,
          equals(WatchState.inProgress),
        );
        expect(episodesResult.items[1].playbackPositionSeconds, equals(450));

        // Query continue watching episodes
        final contEpisodes = await db.queryEpisodes(
          EpisodeQuery.continueWatching(),
        );
        expect(contEpisodes.totalCount, equals(1));
        expect(contEpisodes.items.first.id, equals('ep-2'));
      },
    );
  });

  group('Database Query Engine — Collection Queries', () {
    test(
      'queryCollections returns sorted collections and supports search',
      () async {
        final now = DateTime(2026, 1, 1);

        await db
            .into(db.collections)
            .insert(
              CollectionsCompanion.insert(
                id: 'c-sci-fi',
                name: 'Sci-Fi Universe',
                overview: const drift.Value('Science fiction collection'),
                createdAt: now.subtract(const Duration(days: 2)),
                updatedAt: now.subtract(const Duration(days: 2)),
              ),
            );

        await db
            .into(db.collections)
            .insert(
              CollectionsCompanion.insert(
                id: 'c-animation',
                name: 'Animation Gems',
                overview: const drift.Value('Animated movies and series'),
                createdAt: now.subtract(const Duration(days: 1)),
                updatedAt: now.subtract(const Duration(days: 1)),
              ),
            );

        // All collections (alphabetical)
        final all = await db.queryCollections(CollectionQuery.all());
        expect(all.totalCount, equals(2));
        expect(all.items[0].name, equals('Animation Gems'));
        expect(all.items[1].name, equals('Sci-Fi Universe'));

        // Search collections
        final search = await db.queryCollections(
          CollectionQuery.search('Universe'),
        );
        expect(search.totalCount, equals(1));
        expect(search.items.first.id, equals('c-sci-fi'));
      },
    );
  });

  group('Database Query Engine — Token-Safe Genre Matching', () {
    test('movie genre filter matches exact tokens case-insensitively without substring collisions', () async {
      final now = DateTime(2026, 1, 1);

      // Movie 1: 'War, Drama' (has War)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-war-1',
              detectedTitle: 'Platoon',
              title: const drift.Value('Platoon'),
              genres: const drift.Value('War, Drama'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Movie 2: 'Action, Star Wars, Sci-Fi' (has Star Wars, NOT War)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-sw',
              detectedTitle: 'Star Wars: A New Hope',
              title: const drift.Value('Star Wars: A New Hope'),
              genres: const drift.Value('Action, Star Wars, Sci-Fi'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Movie 3: 'Martial Arts, Action' (has Martial Arts, NOT Art)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-ma',
              detectedTitle: 'Ip Man',
              title: const drift.Value('Ip Man'),
              genres: const drift.Value('Martial Arts, Action'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Movie 4: 'Art, Documentary' (has Art)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-art',
              detectedTitle: 'The Art of Flight',
              title: const drift.Value('The Art of Flight'),
              genres: const drift.Value('Art, Documentary'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Filter by 'War' -> should match Platoon ('m-war-1'), NOT Star Wars ('m-sw')
      final warResult = await db.queryMovies(
        MovieQuery(filter: const MovieFilter(genre: 'War')),
      );
      expect(warResult.totalCount, equals(1));
      expect(warResult.items.first.id, equals('m-war-1'));

      // Filter by 'war' (lowercase) -> case-insensitive match
      final warLowerResult = await db.queryMovies(
        MovieQuery(filter: const MovieFilter(genre: 'war')),
      );
      expect(warLowerResult.totalCount, equals(1));
      expect(warLowerResult.items.first.id, equals('m-war-1'));

      // Filter by 'Art' -> should match The Art of Flight ('m-art'), NOT Ip Man ('m-ma')
      final artResult = await db.queryMovies(
        MovieQuery(filter: const MovieFilter(genre: 'Art')),
      );
      expect(artResult.totalCount, equals(1));
      expect(artResult.items.first.id, equals('m-art'));

      // Filter by 'Star Wars' -> should match Star Wars ('m-sw')
      final swResult = await db.queryMovies(
        MovieQuery(filter: const MovieFilter(genre: 'Star Wars')),
      );
      expect(swResult.totalCount, equals(1));
      expect(swResult.items.first.id, equals('m-sw'));
    });

    test('tv show genre filter matches exact tokens case-insensitively without substring collisions', () async {
      final now = DateTime(2026, 1, 1);

      // Show 1: 'War & Politics, Drama'
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-war-1',
              detectedTitle: 'Band of Brothers',
              title: const drift.Value('Band of Brothers'),
              genres: const drift.Value('War & Politics, Drama'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Show 2: 'War, Action'
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-war-2',
              detectedTitle: 'The Pacific',
              title: const drift.Value('The Pacific'),
              genres: const drift.Value('War, Action'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Show 3: 'Star Wars: The Clone Wars' with genres 'Action, Sci-Fi'
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-sw',
              detectedTitle: 'The Clone Wars',
              title: const drift.Value('The Clone Wars'),
              genres: const drift.Value('Action, Sci-Fi'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Filter TV shows by 'War' -> should match 'tv-war-2', NOT 'tv-war-1' ('War & Politics') or 'tv-sw'
      final warResult = await db.queryTvShows(
        TvShowQuery(filter: const TvShowFilter(genre: 'War')),
      );
      expect(warResult.totalCount, equals(1));
      expect(warResult.items.first.id, equals('tv-war-2'));
    });
  });

  group('Database Query Engine — System Curation Queries', () {
    test('getDiscoveredGenres and watchDiscoveredGenres aggregate and sort genres across movies and shows', () async {
      final now = DateTime(2026, 1, 1);

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-1',
              detectedTitle: 'Movie 1',
              genres: const drift.Value('Action, Sci-Fi'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-1',
              detectedTitle: 'Show 1',
              genres: const drift.Value('Comedy, Action, Drama'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final genres = await db.queryEngine.getDiscoveredGenres();
      expect(genres, equals(['Action', 'Comedy', 'Drama', 'Sci-Fi']));

      expect(
        db.queryEngine.watchDiscoveredGenres(),
        emits(equals(['Action', 'Comedy', 'Drama', 'Sci-Fi'])),
      );
    });

    test('getDiscoveredFranchises and watchDiscoveredFranchises aggregate TMDB collections with counts', () async {
      final now = DateTime(2026, 1, 1);

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-dune-1',
              detectedTitle: 'Dune: Part One',
              tmdbCollectionId: const drift.Value(726871),
              tmdbCollectionName: const drift.Value('Dune Collection'),
              tmdbCollectionPosterPath: const drift.Value('/dune_col.jpg'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'ms-dune-1',
              movieId: const drift.Value('m-dune-1'),
              storageId: 'local-device',
              sourceType: 'localDevice',
              relativePath: 'Dune.mkv',
              filename: 'Dune.mkv',
              extension: '.mkv',
              fileSize: BigInt.from(1000),
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
              id: 'm-dune-2',
              detectedTitle: 'Dune: Part Two',
              tmdbCollectionId: const drift.Value(726871),
              tmdbCollectionName: const drift.Value('Dune Collection'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final franchises = await db.queryEngine.getDiscoveredFranchises();
      expect(franchises.length, equals(1));
      expect(franchises.first.id, equals(726871));
      expect(franchises.first.name, equals('Dune Collection'));
      expect(franchises.first.movieCount, equals(2));
      expect(franchises.first.availableMovieCount, equals(1));

      expect(
        db.queryEngine.watchDiscoveredFranchises(),
        emits(
          predicate<List<FranchiseLibraryItem>>(
            (list) =>
                list.length == 1 &&
                list.first.name == 'Dune Collection' &&
                list.first.movieCount == 2,
          ),
        ),
      );
    });
  });
}
