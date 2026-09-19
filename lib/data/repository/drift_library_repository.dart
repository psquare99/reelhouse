import 'package:drift/drift.dart' as drift;

import '../../domain/query/query.dart';
import '../../domain/repository/library_repository.dart';
import '../../domain/services/next_episode_resolver.dart';
import '../database/database.dart';

/// Drift / SQLite implementation of [LibraryRepository].
///
/// Adapts domain queries and mutations to [DatabaseQueryEngine] and [AppDatabase].
/// Does not replicate query logic or SQL construction.
class DriftLibraryRepository implements LibraryRepository {
  final AppDatabase db;

  const DriftLibraryRepository(this.db);

  // --- Movies ---

  @override
  Future<LibraryResult<MovieLibraryItem>> queryMovies(MovieQuery query) =>
      db.queryMovies(query);

  @override
  Future<List<MovieLibraryItem>> getMovies(MovieQuery query) async {
    final result = await db.queryMovies(query);
    return result.items;
  }

  @override
  Stream<LibraryResult<MovieLibraryItem>> watchMovies(MovieQuery query) =>
      db.watchMovies(query);

  @override
  Future<MovieLibraryItem?> getMovieById(String id) async {
    final result = await db.queryMovies(
      MovieQuery(
        filter: MovieFilter(id: id),
        pagination: const PaginationSpec(limit: 1),
      ),
    );
    return result.items.firstOrNull;
  }

  @override
  Stream<MovieLibraryItem?> watchMovieById(String id) {
    return db
        .watchMovies(
          MovieQuery(
            filter: MovieFilter(id: id),
            pagination: const PaginationSpec(limit: 1),
          ),
        )
        .map((res) => res.items.firstOrNull);
  }

  @override
  Stream<int> watchMovieCount() => db.watchMovieCount();

  // --- TV Shows ---

  @override
  Future<LibraryResult<TvShowLibraryItem>> queryTvShows(TvShowQuery query) =>
      db.queryTvShows(query);

  @override
  Future<List<TvShowLibraryItem>> getTvShows(TvShowQuery query) async {
    final result = await db.queryTvShows(query);
    return result.items;
  }

  @override
  Stream<LibraryResult<TvShowLibraryItem>> watchTvShows(TvShowQuery query) =>
      db.watchTvShows(query);

  @override
  Future<TvShowLibraryItem?> getTvShowById(String id) async {
    final result = await db.queryTvShows(
      TvShowQuery(
        filter: TvShowFilter(id: id),
        pagination: const PaginationSpec(limit: 1),
      ),
    );
    return result.items.firstOrNull;
  }

  @override
  Stream<TvShowLibraryItem?> watchTvShowById(String id) {
    return db
        .watchTvShows(
          TvShowQuery(
            filter: TvShowFilter(id: id),
            pagination: const PaginationSpec(limit: 1),
          ),
        )
        .map((res) => res.items.firstOrNull);
  }

  @override
  Stream<int> watchTvShowCount() => db.watchTvShowCount();

  // --- Seasons ---

  @override
  Future<LibraryResult<SeasonLibraryItem>> querySeasons(SeasonQuery query) =>
      db.querySeasons(query);

  @override
  Stream<LibraryResult<SeasonLibraryItem>> watchSeasons(SeasonQuery query) =>
      db.watchSeasons(query);

  @override
  Future<SeasonLibraryItem?> getSeasonById(String id) async {
    final result = await db.querySeasons(
      SeasonQuery(filter: SeasonFilter(id: id)),
    );
    return result.items.firstOrNull;
  }

  // --- Episodes ---

  @override
  Future<LibraryResult<EpisodeLibraryItem>> queryEpisodes(EpisodeQuery query) =>
      db.queryEpisodes(query);

  @override
  Future<List<EpisodeLibraryItem>> getEpisodes(EpisodeQuery query) async {
    final result = await db.queryEpisodes(query);
    return result.items;
  }

  @override
  Stream<LibraryResult<EpisodeLibraryItem>> watchEpisodes(EpisodeQuery query) =>
      db.watchEpisodes(query);

  @override
  Future<EpisodeLibraryItem?> getEpisodeById(String id) async {
    final result = await db.queryEpisodes(
      EpisodeQuery(
        filter: EpisodeFilter(id: id),
        pagination: const PaginationSpec(limit: 1),
      ),
    );
    return result.items.firstOrNull;
  }

  @override
  Stream<EpisodeLibraryItem?> watchEpisodeById(String id) {
    return db
        .watchEpisodes(
          EpisodeQuery(
            filter: EpisodeFilter(id: id),
            pagination: const PaginationSpec(limit: 1),
          ),
        )
        .map((res) => res.items.firstOrNull);
  }

  @override
  Future<EpisodeLibraryItem?> getNextEpisodeForShow(String showId) async {
    final result = await db.queryEpisodes(
      EpisodeQuery(
        showId: showId,
        filter: EpisodeFilter(showId: showId),
      ),
    );
    return const NextEpisodeResolver().resolveNextEpisode(result.items);
  }

  @override
  Stream<EpisodeLibraryItem?> watchNextEpisodeForShow(String showId) {
    return db
        .watchEpisodes(
          EpisodeQuery(
            showId: showId,
            filter: EpisodeFilter(showId: showId),
          ),
        )
        .map(
          (res) => const NextEpisodeResolver().resolveNextEpisode(res.items),
        );
  }

  // --- Collections ---

  @override
  Future<LibraryResult<CollectionLibraryItem>> queryCollections(
    CollectionQuery query,
  ) => db.queryCollections(query);

  @override
  Future<List<CollectionLibraryItem>> getCollections(
    CollectionQuery query,
  ) async {
    final result = await db.queryCollections(query);
    return result.items;
  }

  @override
  Stream<LibraryResult<CollectionLibraryItem>> watchCollections(
    CollectionQuery query,
  ) => db.watchCollections(query);

  @override
  Future<CollectionLibraryItem?> getCollectionById(String id) async {
    final result = await db.queryCollections(
      CollectionQuery(
        filter: CollectionFilter(id: id),
        pagination: const PaginationSpec(limit: 1),
      ),
    );
    return result.items.firstOrNull;
  }

  @override
  Stream<CollectionLibraryItem?> watchCollectionById(String id) {
    return db
        .watchCollections(
          CollectionQuery(
            filter: CollectionFilter(id: id),
            pagination: const PaginationSpec(limit: 1),
          ),
        )
        .map((res) => res.items.firstOrNull);
  }

  // --- System Curation & Franchises ---

  @override
  Future<List<FranchiseLibraryItem>> getFranchises() =>
      db.queryEngine.getDiscoveredFranchises();

  @override
  Stream<List<FranchiseLibraryItem>> watchFranchises() =>
      db.queryEngine.watchDiscoveredFranchises();

  @override
  Future<List<String>> getDiscoveredGenres() =>
      db.queryEngine.getDiscoveredGenres();

  @override
  Stream<List<String>> watchDiscoveredGenres() =>
      db.queryEngine.watchDiscoveredGenres();

  // --- Diagnostics & Counts ---

  @override
  Stream<int> watchUnmatchedTotalCount() => db.watchUnmatchedTotalCount();

  // --- Mutations ---

  @override
  Future<void> toggleMovieFavorite(String id, bool isFavorite) =>
      db.toggleMovieFavorite(id, isFavorite);

  @override
  Future<void> toggleMovieWatchlist(String id, bool isWatchlist) =>
      db.toggleMovieWatchlist(id, isWatchlist);

  @override
  Future<void> setMovieWatchState(String id, WatchState state) =>
      db.setMovieWatchState(id, state.toDbString());

  @override
  Future<void> toggleTvShowFavorite(String id, bool isFavorite) =>
      db.toggleTvShowFavorite(id, isFavorite);

  @override
  Future<void> toggleTvShowWatchlist(String id, bool isWatchlist) =>
      db.toggleTvShowWatchlist(id, isWatchlist);

  @override
  Future<void> setEpisodeWatchState(String id, WatchState state) =>
      db.setEpisodeWatchState(id, state.toDbString());

  @override
  Future<String> createCollection({
    required String name,
    String? overview,
  }) async {
    final id = 'col-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    await db.createCollection(
      CollectionsCompanion.insert(
        id: id,
        name: name,
        overview: overview != null && overview.trim().isNotEmpty
            ? drift.Value(overview.trim())
            : const drift.Value.absent(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  @override
  Future<void> deleteCollection(String id) => db.deleteCollection(id);

  @override
  Future<void> addMovieToCollection(String collectionId, String movieId) {
    return db.addItemToCollection(
      CollectionItemsCompanion.insert(
        id: 'ci-${DateTime.now().millisecondsSinceEpoch}',
        collectionId: collectionId,
        movieId: drift.Value(movieId),
        addedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> addTvShowToCollection(String collectionId, String tvShowId) {
    return db.addItemToCollection(
      CollectionItemsCompanion.insert(
        id: 'ci-${DateTime.now().millisecondsSinceEpoch}',
        collectionId: collectionId,
        tvShowId: drift.Value(tvShowId),
        addedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> removeMediaFromCollection(
    String collectionId, {
    String? movieId,
    String? tvShowId,
  }) => db.removeItemFromCollection(
    collectionId,
    movieId: movieId,
    tvShowId: tvShowId,
  );

  @override
  Future<void> removeStorage(String storageId) =>
      db.removeStorageLocation(storageId);
}
