import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Storages,
    Movies,
    TvShows,
    Seasons,
    Episodes,
    MediaSources,
    TransferJobs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? connect());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      // Automatically seed the built-in storage record for device-local offline media.
      await into(storages).insert(
        StoragesCompanion.insert(
          id: 'local-device',
          name: 'This Device',
          storageType: 'DEVICE_LOCAL_STORAGE',
          filesystemIdentifier: 'internal-app-storage',
          rootUri: '',
          lastSeenAt: DateTime.now(),
          available: const Value(true),
        ),
      );
    },
  );

  // --- Convenience queries for Milestone 1 ---

  /// Stream all registered storages (external disks + local device).
  Stream<List<Storage>> watchAllStorages() => select(storages).watch();

  /// Get all registered storages.
  Future<List<Storage>> getAllStorages() => select(storages).get();

  /// Insert or update a storage location.
  Future<int> upsertStorage(StoragesCompanion storage) =>
      into(storages).insertOnConflictUpdate(storage);

  /// Find a storage by its persistent hardware filesystem identifier.
  Future<Storage?> findStorageByIdentifier(String identifier) => (select(
    storages,
  )..where((s) => s.filesystemIdentifier.equals(identifier))).getSingleOrNull();

  /// Get all active media sources for a movie.
  Future<List<MediaSource>> getSourcesForMovie(String movieId) =>
      (select(mediaSources)..where((s) => s.movieId.equals(movieId))).get();

  /// Get all active media sources for an episode.
  Future<List<MediaSource>> getSourcesForEpisode(String episodeId) =>
      (select(mediaSources)..where((s) => s.episodeId.equals(episodeId))).get();

  /// Stream count of movies.
  Stream<int> watchMovieCount() {
    final countExpr = countAll();
    final query = selectOnly(movies)..addColumns([countExpr]);
    return query.map((row) => row.read(countExpr) ?? 0).watchSingle();
  }

  /// Stream count of TV shows.
  Stream<int> watchTvShowCount() {
    final countExpr = countAll();
    final query = selectOnly(tvShows)..addColumns([countExpr]);
    return query.map((row) => row.read(countExpr) ?? 0).watchSingle();
  }

  // --- Milestone 2: Scanner & Availability Queries ---

  /// Get all media sources registered for a given storage location.
  Future<List<MediaSource>> getSourcesForStorage(String storageId) =>
      (select(mediaSources)..where((s) => s.storageId.equals(storageId))).get();

  /// Find an existing movie by title and optional year (case-insensitive title match).
  Future<Movie?> findMovieByTitleAndYear(String title, int? year) {
    final q = select(movies)
      ..where((m) => m.title.collate(Collate.noCase).equals(title));
    if (year != null) {
      q.where((m) => m.year.equals(year));
    }
    return q.getSingleOrNull();
  }

  /// Find an existing TV show by title (case-insensitive match).
  Future<TvShow?> findTvShowByTitle(String title) =>
      (select(tvShows)
            ..where((t) => t.title.collate(Collate.noCase).equals(title)))
          .getSingleOrNull();

  /// Find a season by show ID and season number.
  Future<Season?> findSeason(String showId, int seasonNumber) =>
      (select(seasons)..where(
            (s) =>
                s.showId.equals(showId) & s.seasonNumber.equals(seasonNumber),
          ))
          .getSingleOrNull();

  /// Find an episode by season ID and episode number.
  Future<Episode?> findEpisode(String seasonId, int episodeNumber) =>
      (select(episodes)..where(
            (e) =>
                e.seasonId.equals(seasonId) &
                e.episodeNumber.equals(episodeNumber),
          ))
          .getSingleOrNull();

  /// Update availability status of a single media source.
  Future<int> updateSourceAvailability(
    String sourceId, {
    required bool available,
    DateTime? lastSeenAt,
  }) {
    return (update(mediaSources)..where((s) => s.id.equals(sourceId))).write(
      MediaSourcesCompanion(
        available: Value(available),
        lastSeenAt: lastSeenAt != null
            ? Value(lastSeenAt)
            : const Value.absent(),
      ),
    );
  }

  /// Batch update availability for all media sources on a storage device.
  Future<int> setAllSourcesAvailableForStorage(
    String storageId,
    bool available,
  ) {
    return (update(mediaSources)..where((s) => s.storageId.equals(storageId)))
        .write(MediaSourcesCompanion(available: Value(available)));
  }

  /// Update storage availability and last seen timestamp.
  Future<int> updateStorageStatus(
    String storageId, {
    required bool available,
    required DateTime lastSeenAt,
  }) {
    return (update(storages)..where((s) => s.id.equals(storageId))).write(
      StoragesCompanion(
        available: Value(available),
        lastSeenAt: Value(lastSeenAt),
      ),
    );
  }

  /// Get all movies.
  Future<List<Movie>> getAllMovies() => select(movies).get();

  /// Get all TV shows.
  Future<List<TvShow>> getAllTvShows() => select(tvShows).get();

  // --- Milestone 3: Metadata Pipeline Queries ---

  /// Get all movies currently lacking TMDB identification.
  Future<List<Movie>> getUnmatchedMovies() =>
      (select(movies)..where((m) => m.tmdbId.isNull())).get();

  /// Get all TV shows currently lacking TMDB identification.
  Future<List<TvShow>> getUnmatchedTvShows() =>
      (select(tvShows)..where((t) => t.tmdbId.isNull())).get();

  /// Watch count of movies currently in the Needs Verification / Unmatched queue.
  Stream<int> watchUnmatchedMovieCount() {
    final movieCount = countAll();
    final mQuery = selectOnly(movies)
      ..addColumns([movieCount])
      ..where(movies.tmdbId.isNull());

    return mQuery.map((row) => row.read(movieCount) ?? 0).watchSingle();
  }

  /// Watch count of TV shows currently in the Needs Verification / Unmatched queue.
  Stream<int> watchUnmatchedTvShowCount() {
    final tvCount = countAll();
    final tvQuery = selectOnly(tvShows)
      ..addColumns([tvCount])
      ..where(tvShows.tmdbId.isNull());

    return tvQuery.map((row) => row.read(tvCount) ?? 0).watchSingle();
  }

  /// Watch total count of media items (movies + tv shows) in the Needs Verification / Unmatched queue.
  Stream<int> watchUnmatchedTotalCount() {
    return customSelect(
      'SELECT (SELECT COUNT(*) FROM movies WHERE tmdb_id IS NULL) + (SELECT COUNT(*) FROM tv_shows WHERE tmdb_id IS NULL) AS total',
      readsFrom: {movies, tvShows},
    ).map((row) => row.read<int>('total')).watchSingle();
  }

  /// Get all media sources registered for a TV show's episodes.
  Future<List<MediaSource>> getSourcesForTvShow(String showId) {
    final query = select(mediaSources).join([
      innerJoin(episodes, episodes.id.equalsExp(mediaSources.episodeId)),
      innerJoin(seasons, seasons.id.equalsExp(episodes.seasonId)),
    ])..where(seasons.showId.equals(showId));

    return query.map((row) => row.readTable(mediaSources)).get();
  }

  /// Update movie record with fetched TMDB metadata.
  Future<int> updateMovieMetadata(
    String movieId, {
    required int tmdbId,
    String? imdbId,
    String? originalTitle,
    String? overview,
    int? runtime,
    DateTime? releaseDate,
    String? posterPath,
    String? backdropPath,
    double? rating,
    int? voteCount,
    String? metadataId,
  }) {
    return (update(movies)..where((m) => m.id.equals(movieId))).write(
      MoviesCompanion(
        tmdbId: Value(tmdbId),
        imdbId: imdbId != null ? Value(imdbId) : const Value.absent(),
        originalTitle: originalTitle != null
            ? Value(originalTitle)
            : const Value.absent(),
        overview: overview != null ? Value(overview) : const Value.absent(),
        runtime: runtime != null ? Value(runtime) : const Value.absent(),
        releaseDate: releaseDate != null
            ? Value(releaseDate)
            : const Value.absent(),
        posterPath: posterPath != null
            ? Value(posterPath)
            : const Value.absent(),
        backdropPath: backdropPath != null
            ? Value(backdropPath)
            : const Value.absent(),
        rating: rating != null ? Value(rating) : const Value.absent(),
        voteCount: voteCount != null ? Value(voteCount) : const Value.absent(),
        metadataId: metadataId != null
            ? Value(metadataId)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update TV show record with fetched TMDB metadata.
  Future<int> updateTvShowMetadata(
    String showId, {
    required int tmdbId,
    String? imdbId,
    String? originalTitle,
    String? overview,
    DateTime? firstAirDate,
    String? posterPath,
    String? backdropPath,
    double? rating,
    String? metadataId,
  }) {
    return (update(tvShows)..where((t) => t.id.equals(showId))).write(
      TvShowsCompanion(
        tmdbId: Value(tmdbId),
        imdbId: imdbId != null ? Value(imdbId) : const Value.absent(),
        originalTitle: originalTitle != null
            ? Value(originalTitle)
            : const Value.absent(),
        overview: overview != null ? Value(overview) : const Value.absent(),
        firstAirDate: firstAirDate != null
            ? Value(firstAirDate)
            : const Value.absent(),
        posterPath: posterPath != null
            ? Value(posterPath)
            : const Value.absent(),
        backdropPath: backdropPath != null
            ? Value(backdropPath)
            : const Value.absent(),
        rating: rating != null ? Value(rating) : const Value.absent(),
        metadataId: metadataId != null
            ? Value(metadataId)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update episode record with fetched TMDB metadata.
  Future<int> updateEpisodeMetadata(
    String episodeId, {
    required int tmdbId,
    String? name,
    String? overview,
    int? runtime,
    DateTime? airDate,
    String? stillPath,
    double? rating,
  }) {
    return (update(episodes)..where((e) => e.id.equals(episodeId))).write(
      EpisodesCompanion(
        tmdbId: Value(tmdbId),
        name: name != null ? Value(name) : const Value.absent(),
        overview: overview != null ? Value(overview) : const Value.absent(),
        runtime: runtime != null ? Value(runtime) : const Value.absent(),
        airDate: airDate != null ? Value(airDate) : const Value.absent(),
        stillPath: stillPath != null ? Value(stillPath) : const Value.absent(),
        rating: rating != null ? Value(rating) : const Value.absent(),
      ),
    );
  }

  /// Find movie by its internal ID.
  Future<Movie?> findMovieById(String movieId) =>
      (select(movies)..where((m) => m.id.equals(movieId))).getSingleOrNull();

  /// Find TV show by its internal ID.
  Future<TvShow?> findTvShowById(String showId) =>
      (select(tvShows)..where((t) => t.id.equals(showId))).getSingleOrNull();
}
