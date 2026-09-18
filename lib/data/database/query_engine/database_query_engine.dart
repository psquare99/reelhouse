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

  // --- System Curation & Franchises Queries ---

  /// Streams distinct canonical genres discovered across movies and TV shows in the user's library.
  Stream<List<String>> watchDiscoveredGenres() {
    return db
        .customSelect(
          '''
SELECT DISTINCT genres FROM movies WHERE genres IS NOT NULL AND genres != ''
UNION
SELECT DISTINCT genres FROM tv_shows WHERE genres IS NOT NULL AND genres != ''
''',
          readsFrom: {db.movies, db.tvShows},
        )
        .watch()
        .map((rows) {
          final genreSet = <String>{};
          for (final row in rows) {
            final raw = row.read<String>('genres');
            final parts = raw
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty);
            genreSet.addAll(parts);
          }
          final sorted = genreSet.toList()..sort();
          return sorted;
        });
  }

  /// Gets distinct canonical genres discovered across movies and TV shows in the user's library.
  Future<List<String>> getDiscoveredGenres() async {
    final rows = await db
        .customSelect(
          '''
SELECT DISTINCT genres FROM movies WHERE genres IS NOT NULL AND genres != ''
UNION
SELECT DISTINCT genres FROM tv_shows WHERE genres IS NOT NULL AND genres != ''
''',
          readsFrom: {db.movies, db.tvShows},
        )
        .get();

    final genreSet = <String>{};
    for (final row in rows) {
      final raw = row.read<String>('genres');
      final parts = raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      genreSet.addAll(parts);
    }
    final sorted = genreSet.toList()..sort();
    return sorted;
  }

  /// Streams TMDB collections / franchises grouped across movies in the user's library.
  Stream<List<FranchiseLibraryItem>> watchDiscoveredFranchises() {
    return db
        .customSelect(
          '''
SELECT 
  m.tmdb_collection_id AS id,
  m.tmdb_collection_name AS name,
  MAX(m.tmdb_collection_poster_path) AS poster_path,
  MAX(m.tmdb_collection_backdrop_path) AS backdrop_path,
  COUNT(DISTINCT m.id) AS movie_count,
  COUNT(DISTINCT CASE WHEN ms.available = 1 AND (ms.source_type = 'localDevice' OR st.available = 1) THEN m.id ELSE NULL END) AS available_movie_count
FROM movies m
LEFT JOIN media_sources ms ON ms.movie_id = m.id
LEFT JOIN storages st ON st.id = ms.storage_id
WHERE m.tmdb_collection_id IS NOT NULL AND m.tmdb_collection_name IS NOT NULL
GROUP BY m.tmdb_collection_id, m.tmdb_collection_name
ORDER BY m.tmdb_collection_name ASC
''',
          readsFrom: {db.movies, db.mediaSources, db.storages},
        )
        .watch()
        .map((rows) {
          return rows.map((row) {
            return FranchiseLibraryItem(
              id: row.read<int>('id'),
              name: row.read<String>('name'),
              posterPath: row.readNullable<String>('poster_path'),
              backdropPath: row.readNullable<String>('backdrop_path'),
              movieCount: row.read<int>('movie_count'),
              availableMovieCount: row.read<int>('available_movie_count'),
            );
          }).toList();
        });
  }

  /// Gets TMDB collections / franchises grouped across movies in the user's library.
  Future<List<FranchiseLibraryItem>> getDiscoveredFranchises() async {
    final rows = await db
        .customSelect(
          '''
SELECT 
  m.tmdb_collection_id AS id,
  m.tmdb_collection_name AS name,
  MAX(m.tmdb_collection_poster_path) AS poster_path,
  MAX(m.tmdb_collection_backdrop_path) AS backdrop_path,
  COUNT(DISTINCT m.id) AS movie_count,
  COUNT(DISTINCT CASE WHEN ms.available = 1 AND (ms.source_type = 'localDevice' OR st.available = 1) THEN m.id ELSE NULL END) AS available_movie_count
FROM movies m
LEFT JOIN media_sources ms ON ms.movie_id = m.id
LEFT JOIN storages st ON st.id = ms.storage_id
WHERE m.tmdb_collection_id IS NOT NULL AND m.tmdb_collection_name IS NOT NULL
GROUP BY m.tmdb_collection_id, m.tmdb_collection_name
ORDER BY m.tmdb_collection_name ASC
''',
          readsFrom: {db.movies, db.mediaSources, db.storages},
        )
        .get();

    return rows.map((row) {
      return FranchiseLibraryItem(
        id: row.read<int>('id'),
        name: row.read<String>('name'),
        posterPath: row.readNullable<String>('poster_path'),
        backdropPath: row.readNullable<String>('backdrop_path'),
        movieCount: row.read<int>('movie_count'),
        availableMovieCount: row.read<int>('available_movie_count'),
      );
    }).toList();
  }
}
