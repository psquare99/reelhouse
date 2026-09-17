import '../../../domain/query/collection_query.dart';
import '../../../domain/query/episode_query.dart';
import '../../../domain/query/library_result.dart';
import '../../../domain/query/movie_query.dart';
import '../../../domain/query/query_projections.dart';
import '../../../domain/query/season_query.dart';
import '../../../domain/query/tv_show_query.dart';
import '../database.dart';
import 'collection_query_engine.dart';
import 'episode_query_engine.dart';
import 'movie_query_engine.dart';
import 'season_query_engine.dart';
import 'tv_show_query_engine.dart';

/// Central database query engine implementing the pure Phase 1E domain contracts
/// against Drift / SQLite persistence.
class DatabaseQueryEngine {
  final AppDatabase db;
  late final MovieQueryEngine _movies;
  late final TvShowQueryEngine _tvShows;
  late final SeasonQueryEngine _seasons;
  late final EpisodeQueryEngine _episodes;
  late final CollectionQueryEngine _collections;

  DatabaseQueryEngine(this.db) {
    _movies = MovieQueryEngine(db);
    _tvShows = TvShowQueryEngine(db);
    _seasons = SeasonQueryEngine(db);
    _episodes = EpisodeQueryEngine(db);
    _collections = CollectionQueryEngine(db);
  }

  // --- Movie Queries ---
  Future<LibraryResult<MovieLibraryItem>> queryMovies(MovieQuery query) =>
      _movies.query(query);

  Stream<LibraryResult<MovieLibraryItem>> watchMovies(MovieQuery query) =>
      _movies.watch(query);

  // --- TV Show Queries ---
  Future<LibraryResult<TvShowLibraryItem>> queryTvShows(TvShowQuery query) =>
      _tvShows.query(query);

  Stream<LibraryResult<TvShowLibraryItem>> watchTvShows(TvShowQuery query) =>
      _tvShows.watch(query);

  // --- Season Queries ---
  Future<LibraryResult<SeasonLibraryItem>> querySeasons(SeasonQuery query) =>
      _seasons.query(query);

  Stream<LibraryResult<SeasonLibraryItem>> watchSeasons(SeasonQuery query) =>
      _seasons.watch(query);

  // --- Episode Queries ---
  Future<LibraryResult<EpisodeLibraryItem>> queryEpisodes(EpisodeQuery query) =>
      _episodes.query(query);

  Stream<LibraryResult<EpisodeLibraryItem>> watchEpisodes(EpisodeQuery query) =>
      _episodes.watch(query);

  // --- Collection Queries ---
  Future<LibraryResult<CollectionLibraryItem>> queryCollections(
    CollectionQuery query,
  ) => _collections.query(query);

  Stream<LibraryResult<CollectionLibraryItem>> watchCollections(
    CollectionQuery query,
  ) => _collections.watch(query);
}
