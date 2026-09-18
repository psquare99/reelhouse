import '../query/query.dart';

/// Application-facing repository boundary for Library queries, read projections,
/// reactive library streams, and controlled user-library state mutations.
///
/// Implements REELHOUSE_LIBRARY_QUERY_DISCOVERY_SPECIFICATION_v1.1 Phase 1E.3.
///
/// Pure domain contract: Free of Drift, SQLite, AppDatabase, Flutter UI, or database rows.
abstract interface class LibraryRepository {
  // --- Movies ---

  /// Executes a [MovieQuery] returning a paginated [LibraryResult] of [MovieLibraryItem].
  Future<LibraryResult<MovieLibraryItem>> queryMovies(MovieQuery query);

  /// Convenience method executing a [MovieQuery] and returning the list of items.
  Future<List<MovieLibraryItem>> getMovies(MovieQuery query);

  /// Streams [MovieQuery] results reactively as library contents and source availabilities change.
  Stream<LibraryResult<MovieLibraryItem>> watchMovies(MovieQuery query);

  /// Retrieves a single movie by its unique canonical [id].
  Future<MovieLibraryItem?> getMovieById(String id);

  /// Streams a single movie reactively by its unique canonical [id].
  Stream<MovieLibraryItem?> watchMovieById(String id);

  /// Streams the total count of movies in the library.
  Stream<int> watchMovieCount();

  // --- TV Shows ---

  /// Executes a [TvShowQuery] returning a paginated [LibraryResult] of [TvShowLibraryItem].
  Future<LibraryResult<TvShowLibraryItem>> queryTvShows(TvShowQuery query);

  /// Convenience method executing a [TvShowQuery] and returning the list of items.
  Future<List<TvShowLibraryItem>> getTvShows(TvShowQuery query);

  /// Streams [TvShowQuery] results reactively with derived watch state and availability.
  Stream<LibraryResult<TvShowLibraryItem>> watchTvShows(TvShowQuery query);

  /// Retrieves a single TV show by its unique canonical [id].
  Future<TvShowLibraryItem?> getTvShowById(String id);

  /// Streams a single TV show reactively by its unique canonical [id].
  Stream<TvShowLibraryItem?> watchTvShowById(String id);

  /// Streams the total count of TV series in the library.
  Stream<int> watchTvShowCount();

  // --- Seasons ---

  /// Executes a [SeasonQuery] returning ordered [SeasonLibraryItem] projections.
  Future<LibraryResult<SeasonLibraryItem>> querySeasons(SeasonQuery query);

  /// Streams [SeasonQuery] results reactively.
  Stream<LibraryResult<SeasonLibraryItem>> watchSeasons(SeasonQuery query);

  /// Retrieves a single season by its unique [id].
  Future<SeasonLibraryItem?> getSeasonById(String id);

  // --- Episodes ---

  /// Executes an [EpisodeQuery] returning paginated [EpisodeLibraryItem] projections.
  Future<LibraryResult<EpisodeLibraryItem>> queryEpisodes(EpisodeQuery query);

  /// Convenience method executing an [EpisodeQuery] and returning the list of items.
  Future<List<EpisodeLibraryItem>> getEpisodes(EpisodeQuery query);

  /// Streams [EpisodeQuery] results reactively.
  Stream<LibraryResult<EpisodeLibraryItem>> watchEpisodes(EpisodeQuery query);

  /// Retrieves a single episode by its unique [id].
  Future<EpisodeLibraryItem?> getEpisodeById(String id);

  /// Streams a single episode reactively by its unique [id].
  Stream<EpisodeLibraryItem?> watchEpisodeById(String id);

  /// Resolves the next episode to watch for a TV show.
  Future<EpisodeLibraryItem?> getNextEpisodeForShow(String showId);

  /// Streams the next episode to watch for a TV show reactively.
  Stream<EpisodeLibraryItem?> watchNextEpisodeForShow(String showId);

  // --- Collections ---

  /// Executes a [CollectionQuery] returning curated collections with item counts.
  Future<LibraryResult<CollectionLibraryItem>> queryCollections(
    CollectionQuery query,
  );

  /// Convenience method executing a [CollectionQuery] and returning the list of items.
  Future<List<CollectionLibraryItem>> getCollections(CollectionQuery query);

  /// Streams [CollectionQuery] results reactively.
  Stream<LibraryResult<CollectionLibraryItem>> watchCollections(
    CollectionQuery query,
  );

  /// Retrieves a single collection by its unique [id].
  Future<CollectionLibraryItem?> getCollectionById(String id);

  /// Streams a single collection reactively by its unique [id].
  Stream<CollectionLibraryItem?> watchCollectionById(String id);

  // --- System Curation & Franchises ---

  /// Retrieves all discovered canonical TMDB franchises / collections.
  Future<List<FranchiseLibraryItem>> getFranchises();

  /// Streams all discovered canonical TMDB franchises / collections reactively.
  Stream<List<FranchiseLibraryItem>> watchFranchises();

  /// Retrieves all discovered canonical genres present across the user's library.
  Future<List<String>> getDiscoveredGenres();

  /// Streams all discovered canonical genres present across the user's library reactively.
  Stream<List<String>> watchDiscoveredGenres();

  // --- Library Diagnostics & Counts ---

  /// Streams total count of unmatched media requiring user verification.
  Stream<int> watchUnmatchedTotalCount();

  // --- User-Library Mutations (Controlled Boundary) ---

  /// Toggles favorite status for a movie.
  Future<void> toggleMovieFavorite(String id, bool isFavorite);

  /// Toggles watchlist status for a movie.
  Future<void> toggleMovieWatchlist(String id, bool isWatchlist);

  /// Updates playback watch state for a movie.
  Future<void> setMovieWatchState(String id, WatchState state);

  /// Toggles favorite status for a TV show.
  Future<void> toggleTvShowFavorite(String id, bool isFavorite);

  /// Toggles watchlist status for a TV show.
  Future<void> toggleTvShowWatchlist(String id, bool isWatchlist);

  /// Updates playback watch state for an episode.
  Future<void> setEpisodeWatchState(String id, WatchState state);

  /// Creates a new user-curated collection.
  Future<String> createCollection({required String name, String? overview});

  /// Deletes a curated collection without modifying media entities.
  Future<void> deleteCollection(String id);

  /// Adds a movie to a curated collection.
  Future<void> addMovieToCollection(String collectionId, String movieId);

  /// Adds a TV show to a curated collection.
  Future<void> addTvShowToCollection(String collectionId, String tvShowId);

  /// Removes an item from a collection.
  Future<void> removeMediaFromCollection(
    String collectionId, {
    String? movieId,
    String? tvShowId,
  });
}
