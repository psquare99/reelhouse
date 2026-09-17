import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/domain/query/query.dart';
import 'package:reelhouse/domain/repository/library_repository.dart';

void main() {
  late AppDatabase db;
  late LibraryRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftLibraryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftLibraryRepository — Movie Operations', () {
    test('queryMovies, getMovies, watchMovies, getMovieById, watchMovieById, watchMovieCount', () async {
      final now = DateTime(2026, 1, 1);

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-1',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              year: const drift.Value(2010),
              isFavorite: const drift.Value(false),
              isWatchlist: const drift.Value(false),
              watchState: const drift.Value('UNWATCHED'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // queryMovies
      final queryRes = await repository.queryMovies(MovieQuery.all());
      expect(queryRes.totalCount, equals(1));
      expect(queryRes.items.first.id, equals('m-1'));

      // getMovies
      final listRes = await repository.getMovies(MovieQuery.all());
      expect(listRes.length, equals(1));
      expect(listRes.first.displayTitle, equals('Inception'));

      // getMovieById
      final singleMovie = await repository.getMovieById('m-1');
      expect(singleMovie, isNotNull);
      expect(singleMovie!.id, equals('m-1'));
      expect(singleMovie.displayYear, equals(2010));

      final nullMovie = await repository.getMovieById('non-existent');
      expect(nullMovie, isNull);

      // watchMovies
      expect(
        repository.watchMovies(MovieQuery.all()),
        emits(
          predicate<LibraryResult<MovieLibraryItem>>((r) => r.totalCount == 1),
        ),
      );

      // watchMovieById
      expect(
        repository.watchMovieById('m-1'),
        emits(predicate<MovieLibraryItem?>((m) => m?.id == 'm-1')),
      );

      // watchMovieCount
      expect(repository.watchMovieCount(), emits(1));
    });

    test(
      'movie mutations: toggleFavorite, toggleWatchlist, setWatchState',
      () async {
        final now = DateTime(2026, 1, 1);

        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-mut',
                detectedTitle: 'Interstellar',
                isFavorite: const drift.Value(false),
                isWatchlist: const drift.Value(false),
                watchState: const drift.Value('UNWATCHED'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Toggle favorite
        await repository.toggleMovieFavorite('m-mut', true);
        var m = await repository.getMovieById('m-mut');
        expect(m!.isFavorite, isTrue);

        await repository.toggleMovieFavorite('m-mut', false);
        m = await repository.getMovieById('m-mut');
        expect(m!.isFavorite, isFalse);

        // Toggle watchlist
        await repository.toggleMovieWatchlist('m-mut', true);
        m = await repository.getMovieById('m-mut');
        expect(m!.isWatchlist, isTrue);

        // Set watch state
        await repository.setMovieWatchState('m-mut', WatchState.inProgress);
        m = await repository.getMovieById('m-mut');
        expect(m!.watchState, equals(WatchState.inProgress));

        await repository.setMovieWatchState('m-mut', WatchState.watched);
        m = await repository.getMovieById('m-mut');
        expect(m!.watchState, equals(WatchState.watched));
      },
    );
  });

  group('DriftLibraryRepository — TV Show & Season & Episode Operations', () {
    test('queryTvShows, getTvShows, watchTvShows, getTvShowById, watchTvShowById, watchTvShowCount', () async {
      final now = DateTime(2026, 1, 1);

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-1',
              detectedTitle: 'Severance',
              title: const drift.Value('Severance'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 's-1',
              showId: 'tv-1',
              seasonNumber: 1,
              name: const drift.Value('Season 1'),
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-1',
              seasonId: 's-1',
              episodeNumber: 1,
              name: const drift.Value('Good News About Hell'),
              watchState: const drift.Value('WATCHED'),
            ),
          );

      // queryTvShows
      final queryRes = await repository.queryTvShows(TvShowQuery.all());
      expect(queryRes.totalCount, equals(1));
      expect(queryRes.items.first.totalSeasons, equals(1));
      expect(queryRes.items.first.totalEpisodes, equals(1));
      expect(
        queryRes.items.first.derivedWatchState,
        equals(WatchState.watched),
      );

      // getTvShows
      final listRes = await repository.getTvShows(TvShowQuery.all());
      expect(listRes.length, equals(1));

      // getTvShowById
      final show = await repository.getTvShowById('tv-1');
      expect(show, isNotNull);
      expect(show!.id, equals('tv-1'));

      // watchTvShows
      expect(
        repository.watchTvShows(TvShowQuery.all()),
        emits(
          predicate<LibraryResult<TvShowLibraryItem>>((r) => r.totalCount == 1),
        ),
      );

      // watchTvShowById
      expect(
        repository.watchTvShowById('tv-1'),
        emits(predicate<TvShowLibraryItem?>((s) => s?.id == 'tv-1')),
      );

      // watchTvShowCount
      expect(repository.watchTvShowCount(), emits(1));

      // querySeasons
      final seasonsRes = await repository.querySeasons(
        SeasonQuery.forShow('tv-1'),
      );
      expect(seasonsRes.items.length, equals(1));
      expect(seasonsRes.items.first.seasonNumber, equals(1));

      // watchSeasons
      expect(
        repository.watchSeasons(SeasonQuery.forShow('tv-1')),
        emits(
          predicate<LibraryResult<SeasonLibraryItem>>((r) => r.totalCount == 1),
        ),
      );

      // queryEpisodes & getEpisodes
      final episodes = await repository.getEpisodes(
        EpisodeQuery.forSeason('s-1'),
      );
      expect(episodes.length, equals(1));
      expect(episodes.first.name, equals('Good News About Hell'));

      // getEpisodeById
      final ep = await repository.getEpisodeById('ep-1');
      expect(ep, isNotNull);
      expect(ep!.id, equals('ep-1'));

      // watchEpisodeById
      expect(
        repository.watchEpisodeById('ep-1'),
        emits(predicate<EpisodeLibraryItem?>((e) => e?.id == 'ep-1')),
      );

      // watchEpisodes
      expect(
        repository.watchEpisodes(EpisodeQuery.forSeason('s-1')),
        emits(
          predicate<LibraryResult<EpisodeLibraryItem>>(
            (r) => r.totalCount == 1,
          ),
        ),
      );
    });

    test(
      'tv mutations: toggleFavorite, toggleWatchlist, setEpisodeWatchState',
      () async {
        final now = DateTime(2026, 1, 1);

        await db
            .into(db.tvShows)
            .insert(
              TvShowsCompanion.insert(
                id: 'tv-mut',
                detectedTitle: 'Dark',
                isFavorite: const drift.Value(false),
                isWatchlist: const drift.Value(false),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.seasons)
            .insert(
              SeasonsCompanion.insert(
                id: 's-dark-1',
                showId: 'tv-mut',
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

        // Favorite toggle
        await repository.toggleTvShowFavorite('tv-mut', true);
        var show = await repository.getTvShowById('tv-mut');
        expect(show!.isFavorite, isTrue);

        // Watchlist toggle
        await repository.toggleTvShowWatchlist('tv-mut', true);
        show = await repository.getTvShowById('tv-mut');
        expect(show!.isWatchlist, isTrue);

        // Set episode watch state
        await repository.setEpisodeWatchState(
          'ep-dark-1',
          WatchState.inProgress,
        );
        var ep = await repository.getEpisodeById('ep-dark-1');
        expect(ep!.watchState, equals(WatchState.inProgress));

        await repository.setEpisodeWatchState('ep-dark-1', WatchState.watched);
        ep = await repository.getEpisodeById('ep-dark-1');
        expect(ep!.watchState, equals(WatchState.watched));
      },
    );
  });

  group('DriftLibraryRepository — Collection Operations', () {
    test('queryCollections, getCollections, watchCollections, getCollectionById, mutations', () async {
      final now = DateTime(2026, 1, 1);

      // Create collection
      final colId = await repository.createCollection(
        name: 'Sci-Fi Classics',
        overview: 'Best sci-fi movies and shows',
      );
      expect(colId, isNotEmpty);

      final col = await repository.getCollectionById(colId);
      expect(col, isNotNull);
      expect(col!.name, equals('Sci-Fi Classics'));
      expect(col.itemCount, equals(0));

      // Query collections
      final queryRes = await repository.queryCollections(CollectionQuery.all());
      expect(queryRes.totalCount, equals(1));
      expect(queryRes.items.first.id, equals(colId));

      // Get collections
      final listRes = await repository.getCollections(CollectionQuery.all());
      expect(listRes.length, equals(1));

      // Get collection by id
      final fetchedCol = await repository.getCollectionById(colId);
      expect(fetchedCol, isNotNull);
      expect(fetchedCol!.name, equals('Sci-Fi Classics'));

      // Insert movie & show
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-blade',
              detectedTitle: 'Blade Runner',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-expanse',
              detectedTitle: 'The Expanse',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Add movie and tv show to collection
      await repository.addMovieToCollection(colId, 'm-blade');
      await repository.addTvShowToCollection(colId, 'tv-expanse');

      // Verify item count updated in projection
      final updatedCol = await repository.getCollectionById(colId);
      expect(updatedCol!.itemCount, equals(2));

      // Remove movie from collection
      await repository.removeMediaFromCollection(colId, movieId: 'm-blade');
      final afterRemove = await repository.getCollectionById(colId);
      expect(afterRemove!.itemCount, equals(1));

      // Delete collection
      await repository.deleteCollection(colId);
      final deletedCol = await repository.getCollectionById(colId);
      expect(deletedCol, isNull);
    });
  });

  group('DriftLibraryRepository — Global Count Streams', () {
    test('watchUnmatchedTotalCount', () async {
      final now = DateTime(2026, 1, 1);

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-pending',
              detectedTitle: 'Unmatched 1',
              identificationStatus: const drift.Value('PENDING'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-verify',
              detectedTitle: 'Ambiguous 1',
              identificationStatus: const drift.Value('NEEDS_VERIFICATION'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // watchUnmatchedTotalCount = PENDING + NEEDS_VERIFICATION = 2
      expect(repository.watchUnmatchedTotalCount(), emits(2));
    });
  });
}
