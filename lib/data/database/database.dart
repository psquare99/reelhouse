import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'query_engine/database_query_engine.dart';
import 'tables.dart';
import '../../domain/query/query.dart';

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
    Collections,
    CollectionItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? connect());

  @override
  int get schemaVersion => 5;

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
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(movies, movies.isFavorite);
        await m.addColumn(movies, movies.isWatchlist);
        await m.addColumn(movies, movies.watchState);
        await m.addColumn(movies, movies.playbackPositionSeconds);

        await m.addColumn(tvShows, tvShows.isFavorite);
        await m.addColumn(tvShows, tvShows.isWatchlist);

        await m.addColumn(episodes, episodes.watchState);
        await m.addColumn(episodes, episodes.playbackPositionSeconds);

        await m.createTable(collections);
        await m.createTable(collectionItems);
      }
      if (from < 3) {
        await m.addColumn(movies, movies.metadataProvider);
        await m.addColumn(movies, movies.providerItemId);
        await m.addColumn(movies, movies.metadataUpdatedAt);

        await m.addColumn(tvShows, tvShows.metadataProvider);
        await m.addColumn(tvShows, tvShows.providerItemId);
        await m.addColumn(tvShows, tvShows.metadataUpdatedAt);
      }
      if (from < 4) {
        await m.alterTable(
          TableMigration(
            movies,
            columnTransformer: {
              movies.detectedTitle: movies.title,
              movies.detectedYear: movies.year,
              movies.identificationStatus: const CustomExpression<String>(
                "CASE WHEN tmdb_id IS NOT NULL THEN 'IDENTIFIED' ELSE 'PENDING' END",
              ),
            },
            newColumns: [
              movies.genres,
              movies.tmdbCollectionId,
              movies.tmdbCollectionName,
              movies.tmdbCollectionPosterPath,
              movies.tmdbCollectionBackdropPath,
            ],
          ),
        );

        await m.alterTable(
          TableMigration(
            tvShows,
            columnTransformer: {
              tvShows.detectedTitle: tvShows.title,
              tvShows.identificationStatus: const CustomExpression<String>(
                "CASE WHEN tmdb_id IS NOT NULL THEN 'IDENTIFIED' ELSE 'PENDING' END",
              ),
            },
            newColumns: [tvShows.genres],
          ),
        );
      } else if (from < 5) {
        await m.addColumn(movies, movies.genres);
        await m.addColumn(movies, movies.tmdbCollectionId);
        await m.addColumn(movies, movies.tmdbCollectionName);
        await m.addColumn(movies, movies.tmdbCollectionPosterPath);
        await m.addColumn(movies, movies.tmdbCollectionBackdropPath);
        await m.addColumn(tvShows, tvShows.genres);
      }
    },
  );

  // --- Convenience queries for Milestone 1 ---

  /// Stream all registered storages (external disks + local device).
  Stream<List<Storage>> watchAllStorages() => select(storages).watch();

  /// Get all registered storages.
  Future<List<Storage>> getAllStorages() => select(storages).get();

  /// Find a storage by its internal ID.
  Future<Storage?> getStorageById(String id) =>
      (select(storages)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Find a media source by its internal ID.
  Future<MediaSource?> getMediaSourceById(String id) =>
      (select(mediaSources)..where((s) => s.id.equals(id))).getSingleOrNull();

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

  /// Find an existing movie by detected title and optional detected year (case-insensitive title match).
  Future<Movie?> findMovieByDetectedTitleAndYear(
    String detectedTitle,
    int? detectedYear,
  ) {
    final q = select(movies)
      ..where(
        (m) => m.detectedTitle.collate(Collate.noCase).equals(detectedTitle),
      );
    if (detectedYear != null) {
      q.where((m) => m.detectedYear.equals(detectedYear));
    } else {
      q.where((m) => m.detectedYear.isNull());
    }
    return q.getSingleOrNull();
  }

  /// Find an existing TV show by detected title (case-insensitive match).
  Future<TvShow?> findTvShowByDetectedTitle(String detectedTitle) =>
      (select(tvShows)..where(
            (t) =>
                t.detectedTitle.collate(Collate.noCase).equals(detectedTitle),
          ))
          .getSingleOrNull();

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

  /// Get all identified TV shows that have unenriched episodes (missing TMDB ID or still).
  Future<List<TvShow>> getIdentifiedTvShowsNeedingEpisodeEnrichment() {
    final query = select(tvShows).join([
      innerJoin(seasons, seasons.showId.equalsExp(tvShows.id)),
      innerJoin(
        episodes,
        episodes.seasonId.equalsExp(seasons.id) &
            (episodes.tmdbId.isNull() | episodes.stillPath.isNull()),
      ),
    ])..where(tvShows.tmdbId.isNotNull());

    query.groupBy([tvShows.id]);
    return query.map((row) => row.readTable(tvShows)).get();
  }

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

  /// Update movie record with fetched TMDB/fallback metadata.
  Future<int> updateMovieMetadata(
    String movieId, {
    required int tmdbId,
    String? title,
    int? year,
    String identificationStatus = 'IDENTIFIED',
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
    String? metadataProvider = 'TMDB',
    String? providerItemId,
    DateTime? metadataUpdatedAt,
    String? genres,
    int? tmdbCollectionId,
    String? tmdbCollectionName,
    String? tmdbCollectionPosterPath,
    String? tmdbCollectionBackdropPath,
  }) {
    return (update(movies)..where((m) => m.id.equals(movieId))).write(
      MoviesCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        year: year != null ? Value(year) : const Value.absent(),
        identificationStatus: Value(identificationStatus),
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
        metadataProvider: metadataProvider != null
            ? Value(metadataProvider)
            : const Value.absent(),
        providerItemId: providerItemId != null
            ? Value(providerItemId)
            : const Value.absent(),
        metadataUpdatedAt: metadataUpdatedAt != null
            ? Value(metadataUpdatedAt)
            : Value(DateTime.now()),
        genres: genres != null ? Value(genres) : const Value.absent(),
        tmdbCollectionId: tmdbCollectionId != null
            ? Value(tmdbCollectionId)
            : const Value.absent(),
        tmdbCollectionName: tmdbCollectionName != null
            ? Value(tmdbCollectionName)
            : const Value.absent(),
        tmdbCollectionPosterPath: tmdbCollectionPosterPath != null
            ? Value(tmdbCollectionPosterPath)
            : const Value.absent(),
        tmdbCollectionBackdropPath: tmdbCollectionBackdropPath != null
            ? Value(tmdbCollectionBackdropPath)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update TV show record with fetched TMDB/fallback metadata.
  Future<int> updateTvShowMetadata(
    String showId, {
    required int tmdbId,
    String? title,
    String identificationStatus = 'IDENTIFIED',
    String? imdbId,
    String? originalTitle,
    String? overview,
    DateTime? firstAirDate,
    String? posterPath,
    String? backdropPath,
    double? rating,
    String? metadataId,
    String? metadataProvider = 'TMDB',
    String? providerItemId,
    DateTime? metadataUpdatedAt,
    String? genres,
  }) {
    return (update(tvShows)..where((t) => t.id.equals(showId))).write(
      TvShowsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        identificationStatus: Value(identificationStatus),
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
        metadataProvider: metadataProvider != null
            ? Value(metadataProvider)
            : const Value.absent(),
        providerItemId: providerItemId != null
            ? Value(providerItemId)
            : const Value.absent(),
        metadataUpdatedAt: metadataUpdatedAt != null
            ? Value(metadataUpdatedAt)
            : Value(DateTime.now()),
        genres: genres != null ? Value(genres) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Milestone 2.2: System Curation & Franchises Queries ---

  /// Stream distinct canonical genres present in the user's library.
  Stream<List<String>> watchDiscoveredGenres() {
    return customSelect(
      '''
SELECT DISTINCT genres FROM movies WHERE genres IS NOT NULL AND genres != ''
UNION
SELECT DISTINCT genres FROM tv_shows WHERE genres IS NOT NULL AND genres != ''
''',
      readsFrom: {movies, tvShows},
    ).watch().map((rows) {
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

  /// Get distinct canonical genres present in the user's library.
  Future<List<String>> getDiscoveredGenres() async {
    final rows = await customSelect(
      '''
SELECT DISTINCT genres FROM movies WHERE genres IS NOT NULL AND genres != ''
UNION
SELECT DISTINCT genres FROM tv_shows WHERE genres IS NOT NULL AND genres != ''
''',
      readsFrom: {movies, tvShows},
    ).get();

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

  /// Stream TMDB collections / franchises grouped across movies in the user's library.
  Stream<List<FranchiseLibraryItem>> watchDiscoveredFranchises() {
    return customSelect(
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
      readsFrom: {movies, mediaSources, storages},
    ).watch().map((rows) {
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

  /// Get TMDB collections / franchises grouped across movies in the user's library.
  Future<List<FranchiseLibraryItem>> getDiscoveredFranchises() async {
    final rows = await customSelect(
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
      readsFrom: {movies, mediaSources, storages},
    ).get();

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

  /// Update identification status of a movie.
  Future<int> updateMovieIdentificationStatus(String movieId, String status) {
    return (update(movies)..where((m) => m.id.equals(movieId))).write(
      MoviesCompanion(
        identificationStatus: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update identification status of a TV show.
  Future<int> updateTvShowIdentificationStatus(String showId, String status) {
    return (update(tvShows)..where((t) => t.id.equals(showId))).write(
      TvShowsCompanion(
        identificationStatus: Value(status),
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

  /// Find movie by TMDB ID.
  Future<Movie?> findMovieByTmdbId(int tmdbId) =>
      (select(movies)..where((m) => m.tmdbId.equals(tmdbId))).getSingleOrNull();

  /// Watch movie by its internal ID.
  Stream<Movie?> watchMovieById(String movieId) =>
      (select(movies)..where((m) => m.id.equals(movieId))).watchSingleOrNull();

  /// Find TV show by its internal ID.
  Future<TvShow?> findTvShowById(String showId) =>
      (select(tvShows)..where((t) => t.id.equals(showId))).getSingleOrNull();

  /// Find TV show by TMDB ID.
  Future<TvShow?> findTvShowByTmdbId(int tmdbId) => (select(
    tvShows,
  )..where((t) => t.tmdbId.equals(tmdbId))).getSingleOrNull();

  /// Watch TV show by its internal ID.
  Stream<TvShow?> watchTvShowById(String showId) =>
      (select(tvShows)..where((t) => t.id.equals(showId))).watchSingleOrNull();

  /// Merges a duplicate TV show ([sourceShowId]) into a canonical TV show ([targetShowId]).
  ///
  /// This performs a lossless transactional merge:
  /// 1. Re-parents or merges all seasons and episodes.
  /// 2. Re-points all media sources so no physical files are lost.
  /// 3. Re-points active transfer jobs.
  /// 4. Re-points or deduplicates collection items.
  /// 5. Merges favorite/watchlist flags and episode watch states.
  /// 6. Deletes the empty source TV show record.
  Future<void> mergeTvShows({
    required String sourceShowId,
    required String targetShowId,
  }) async {
    if (sourceShowId == targetShowId) return;

    await transaction(() async {
      final sourceShow = await (select(
        tvShows,
      )..where((t) => t.id.equals(sourceShowId))).getSingleOrNull();
      final targetShow = await (select(
        tvShows,
      )..where((t) => t.id.equals(targetShowId))).getSingleOrNull();

      if (sourceShow == null || targetShow == null) return;

      // 1. Merge show-level user flags (favorite, watchlist)
      final newFavorite = targetShow.isFavorite || sourceShow.isFavorite;
      final newWatchlist = targetShow.isWatchlist || sourceShow.isWatchlist;
      if (newFavorite != targetShow.isFavorite ||
          newWatchlist != targetShow.isWatchlist) {
        await (update(tvShows)..where((t) => t.id.equals(targetShowId))).write(
          TvShowsCompanion(
            isFavorite: Value(newFavorite),
            isWatchlist: Value(newWatchlist),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // 2. Re-parent / deduplicate collection items
      final sourceColItems = await (select(
        collectionItems,
      )..where((ci) => ci.tvShowId.equals(sourceShowId))).get();
      for (final sci in sourceColItems) {
        final existingInCol =
            await (select(collectionItems)..where(
                  (ci) =>
                      ci.collectionId.equals(sci.collectionId) &
                      ci.tvShowId.equals(targetShowId),
                ))
                .getSingleOrNull();
        if (existingInCol != null) {
          await (delete(
            collectionItems,
          )..where((ci) => ci.id.equals(sci.id))).go();
        } else {
          await (update(collectionItems)..where((ci) => ci.id.equals(sci.id)))
              .write(CollectionItemsCompanion(tvShowId: Value(targetShowId)));
        }
      }

      // 3. Merge Seasons & Episodes
      final sourceSeasons = await (select(
        seasons,
      )..where((s) => s.showId.equals(sourceShowId))).get();
      for (final sourceSeason in sourceSeasons) {
        final targetSeason =
            await (select(seasons)..where(
                  (s) =>
                      s.showId.equals(targetShowId) &
                      s.seasonNumber.equals(sourceSeason.seasonNumber),
                ))
                .getSingleOrNull();

        if (targetSeason == null) {
          // Disjoint season: re-parent entire season to target show
          await (update(seasons)..where((s) => s.id.equals(sourceSeason.id)))
              .write(SeasonsCompanion(showId: Value(targetShowId)));
        } else {
          // Overlapping season: merge episodes from source season into target season
          final sourceEpisodes = await (select(
            episodes,
          )..where((e) => e.seasonId.equals(sourceSeason.id))).get();
          for (final sourceEp in sourceEpisodes) {
            final targetEp =
                await (select(episodes)..where(
                      (e) =>
                          e.seasonId.equals(targetSeason.id) &
                          e.episodeNumber.equals(sourceEp.episodeNumber),
                    ))
                    .getSingleOrNull();

            if (targetEp == null) {
              // Disjoint episode: re-parent episode to target season
              await (update(episodes)..where((e) => e.id.equals(sourceEp.id)))
                  .write(EpisodesCompanion(seasonId: Value(targetSeason.id)));
            } else {
              // Overlapping episode: re-point media sources, transfer jobs, merge watch state, then delete source episode
              await (update(mediaSources)
                    ..where((ms) => ms.episodeId.equals(sourceEp.id)))
                  .write(MediaSourcesCompanion(episodeId: Value(targetEp.id)));

              await (update(transferJobs)..where(
                    (tj) =>
                        tj.mediaType.equals('episode') &
                        tj.mediaId.equals(sourceEp.id),
                  ))
                  .write(TransferJobsCompanion(mediaId: Value(targetEp.id)));

              // Merge watch state: WATCHED > IN_PROGRESS > UNWATCHED
              var mergedWatchState = targetEp.watchState;
              var mergedPosition = targetEp.playbackPositionSeconds;

              if (sourceEp.watchState == 'WATCHED') {
                mergedWatchState = 'WATCHED';
                mergedPosition = 0;
              } else if (sourceEp.watchState == 'IN_PROGRESS') {
                if (mergedWatchState == 'UNWATCHED') {
                  mergedWatchState = 'IN_PROGRESS';
                  mergedPosition = sourceEp.playbackPositionSeconds;
                } else if (mergedWatchState == 'IN_PROGRESS') {
                  if (sourceEp.playbackPositionSeconds > mergedPosition) {
                    mergedPosition = sourceEp.playbackPositionSeconds;
                  }
                }
              }

              if (mergedWatchState != targetEp.watchState ||
                  mergedPosition != targetEp.playbackPositionSeconds) {
                await (update(
                  episodes,
                )..where((e) => e.id.equals(targetEp.id))).write(
                  EpisodesCompanion(
                    watchState: Value(mergedWatchState),
                    playbackPositionSeconds: Value(mergedPosition),
                  ),
                );
              }

              // Delete redundant source episode
              await (delete(
                episodes,
              )..where((e) => e.id.equals(sourceEp.id))).go();
            }
          }

          // Delete now-empty source season
          await (delete(
            seasons,
          )..where((s) => s.id.equals(sourceSeason.id))).go();
        }
      }

      // 4. Delete source show record
      await (delete(tvShows)..where((t) => t.id.equals(sourceShowId))).go();

      // 5. Update target show timestamp
      await (update(tvShows)..where((t) => t.id.equals(targetShowId))).write(
        TvShowsCompanion(updatedAt: Value(DateTime.now())),
      );
    });
  }

  /// Merges a duplicate movie ([sourceMovieId]) into a canonical movie ([targetMovieId]).
  ///
  /// This performs a lossless transactional merge:
  /// 1. Re-points all media sources to the target movie.
  /// 2. Re-points active transfer jobs.
  /// 3. Re-points or deduplicates collection items.
  /// 4. Merges favorite/watchlist flags and movie watch states.
  /// 5. Deletes the empty source movie record.
  Future<void> mergeMovies({
    required String sourceMovieId,
    required String targetMovieId,
  }) async {
    if (sourceMovieId == targetMovieId) return;

    await transaction(() async {
      final sourceMovie = await (select(
        movies,
      )..where((m) => m.id.equals(sourceMovieId))).getSingleOrNull();
      final targetMovie = await (select(
        movies,
      )..where((m) => m.id.equals(targetMovieId))).getSingleOrNull();

      if (sourceMovie == null || targetMovie == null) return;

      // 1. Merge movie-level flags
      final newFavorite = targetMovie.isFavorite || sourceMovie.isFavorite;
      final newWatchlist = targetMovie.isWatchlist || sourceMovie.isWatchlist;

      var mergedWatchState = targetMovie.watchState;
      var mergedPosition = targetMovie.playbackPositionSeconds;

      if (sourceMovie.watchState == 'WATCHED') {
        mergedWatchState = 'WATCHED';
        mergedPosition = 0;
      } else if (sourceMovie.watchState == 'IN_PROGRESS') {
        if (mergedWatchState == 'UNWATCHED') {
          mergedWatchState = 'IN_PROGRESS';
          mergedPosition = sourceMovie.playbackPositionSeconds;
        } else if (mergedWatchState == 'IN_PROGRESS') {
          if (sourceMovie.playbackPositionSeconds > mergedPosition) {
            mergedPosition = sourceMovie.playbackPositionSeconds;
          }
        }
      }

      await (update(movies)..where((m) => m.id.equals(targetMovieId))).write(
        MoviesCompanion(
          isFavorite: Value(newFavorite),
          isWatchlist: Value(newWatchlist),
          watchState: Value(mergedWatchState),
          playbackPositionSeconds: Value(mergedPosition),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 2. Re-parent / deduplicate collection items
      final sourceColItems = await (select(
        collectionItems,
      )..where((ci) => ci.movieId.equals(sourceMovieId))).get();
      for (final sci in sourceColItems) {
        final existingInCol =
            await (select(collectionItems)..where(
                  (ci) =>
                      ci.collectionId.equals(sci.collectionId) &
                      ci.movieId.equals(targetMovieId),
                ))
                .getSingleOrNull();
        if (existingInCol != null) {
          await (delete(
            collectionItems,
          )..where((ci) => ci.id.equals(sci.id))).go();
        } else {
          await (update(collectionItems)..where((ci) => ci.id.equals(sci.id)))
              .write(CollectionItemsCompanion(movieId: Value(targetMovieId)));
        }
      }

      // 3. Re-point media sources
      await (update(mediaSources)
            ..where((ms) => ms.movieId.equals(sourceMovieId)))
          .write(MediaSourcesCompanion(movieId: Value(targetMovieId)));

      // 4. Re-point transfer jobs
      await (update(transferJobs)..where(
            (tj) =>
                tj.mediaType.equals('movie') & tj.mediaId.equals(sourceMovieId),
          ))
          .write(TransferJobsCompanion(mediaId: Value(targetMovieId)));

      // 5. Delete source movie
      await (delete(movies)..where((m) => m.id.equals(sourceMovieId))).go();
    });
  }

  // --- Milestone 4: Cinema Experience UI Queries ---

  /// Watch movies in progress (Continue Watching).
  Stream<List<Movie>> watchContinueWatchingMovies() =>
      (select(movies)
            ..where((m) => m.watchState.equals('IN_PROGRESS'))
            ..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
          .watch();

  /// Watch episodes in progress (Continue Watching).
  Stream<List<Episode>> watchContinueWatchingEpisodes() =>
      (select(episodes)
            ..where((e) => e.watchState.equals('IN_PROGRESS'))
            ..orderBy([(e) => OrderingTerm.desc(e.airDate)]))
          .watch();

  /// Watch recently added movies.
  Stream<List<Movie>> watchRecentlyAddedMovies({int limit = 10}) =>
      (select(movies)
            ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
            ..limit(limit))
          .watch();

  /// Watch recently added TV shows.
  Stream<List<TvShow>> watchRecentlyAddedTvShows({int limit = 10}) =>
      (select(tvShows)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  /// Watch favorite movies.
  Stream<List<Movie>> watchFavoriteMovies() =>
      (select(movies)
            ..where((m) => m.isFavorite.equals(true))
            ..orderBy([(m) => OrderingTerm.asc(m.title)]))
          .watch();

  /// Watch favorite TV shows.
  Stream<List<TvShow>> watchFavoriteTvShows() =>
      (select(tvShows)
            ..where((t) => t.isFavorite.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .watch();

  /// Watch watchlist movies.
  Stream<List<Movie>> watchWatchlistMovies() =>
      (select(movies)
            ..where((m) => m.isWatchlist.equals(true))
            ..orderBy([(m) => OrderingTerm.asc(m.title)]))
          .watch();

  /// Watch watchlist TV shows.
  Stream<List<TvShow>> watchWatchlistTvShows() =>
      (select(tvShows)
            ..where((t) => t.isWatchlist.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.title)]))
          .watch();

  /// Watch movies that have an available device-local copy (Offline Library).
  Stream<List<Movie>> watchOfflineMovies() {
    final query = select(movies).join([
      innerJoin(
        mediaSources,
        mediaSources.movieId.equalsExp(movies.id) &
            mediaSources.sourceType.equals('localDevice') &
            mediaSources.available.equals(true),
      ),
    ]);
    query.groupBy([movies.id]);
    query.orderBy([OrderingTerm.asc(movies.title)]);
    return query.map((row) => row.readTable(movies)).watch();
  }

  /// Watch TV shows that have at least one available device-local episode copy (Offline Library).
  Stream<List<TvShow>> watchOfflineTvShows() {
    final query = select(tvShows).join([
      innerJoin(seasons, seasons.showId.equalsExp(tvShows.id)),
      innerJoin(episodes, episodes.seasonId.equalsExp(seasons.id)),
      innerJoin(
        mediaSources,
        mediaSources.episodeId.equalsExp(episodes.id) &
            mediaSources.sourceType.equals('localDevice') &
            mediaSources.available.equals(true),
      ),
    ]);
    query.groupBy([tvShows.id]);
    query.orderBy([OrderingTerm.asc(tvShows.title)]);
    return query.map((row) => row.readTable(tvShows)).watch();
  }

  /// Toggle movie favorite status.
  Future<int> toggleMovieFavorite(String movieId, bool isFavorite) =>
      (update(movies)..where((m) => m.id.equals(movieId))).write(
        MoviesCompanion(
          isFavorite: Value(isFavorite),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Toggle movie watchlist status.
  Future<int> toggleMovieWatchlist(String movieId, bool isWatchlist) =>
      (update(movies)..where((m) => m.id.equals(movieId))).write(
        MoviesCompanion(
          isWatchlist: Value(isWatchlist),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Set movie watch state ('UNWATCHED', 'IN_PROGRESS', 'WATCHED').
  Future<int> setMovieWatchState(
    String movieId,
    String watchState, {
    int? positionSeconds,
  }) => (update(movies)..where((m) => m.id.equals(movieId))).write(
    MoviesCompanion(
      watchState: Value(watchState),
      playbackPositionSeconds: positionSeconds != null
          ? Value(positionSeconds)
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ),
  );

  /// Toggle TV show favorite status.
  Future<int> toggleTvShowFavorite(String showId, bool isFavorite) =>
      (update(tvShows)..where((t) => t.id.equals(showId))).write(
        TvShowsCompanion(
          isFavorite: Value(isFavorite),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Toggle TV show watchlist status.
  Future<int> toggleTvShowWatchlist(String showId, bool isWatchlist) =>
      (update(tvShows)..where((t) => t.id.equals(showId))).write(
        TvShowsCompanion(
          isWatchlist: Value(isWatchlist),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Set episode watch state ('UNWATCHED', 'IN_PROGRESS', 'WATCHED').
  Future<int> setEpisodeWatchState(
    String episodeId,
    String watchState, {
    int? positionSeconds,
  }) => (update(episodes)..where((e) => e.id.equals(episodeId))).write(
    EpisodesCompanion(
      watchState: Value(watchState),
      playbackPositionSeconds: positionSeconds != null
          ? Value(positionSeconds)
          : const Value.absent(),
    ),
  );

  /// Watch seasons for a TV show ordered by season number.
  Stream<List<Season>> watchSeasonsForShow(String showId) =>
      (select(seasons)
            ..where((s) => s.showId.equals(showId))
            ..orderBy([(s) => OrderingTerm.asc(s.seasonNumber)]))
          .watch();

  /// Get seasons for a TV show ordered by season number.
  Future<List<Season>> getSeasonsForShow(String showId) =>
      (select(seasons)
            ..where((s) => s.showId.equals(showId))
            ..orderBy([(s) => OrderingTerm.asc(s.seasonNumber)]))
          .get();

  /// Watch episodes for a season ordered by episode number.
  Stream<List<Episode>> watchEpisodesForSeason(String seasonId) =>
      (select(episodes)
            ..where((e) => e.seasonId.equals(seasonId))
            ..orderBy([(e) => OrderingTerm.asc(e.episodeNumber)]))
          .watch();

  /// Get episodes for a season ordered by episode number.
  Future<List<Episode>> getEpisodesForSeason(String seasonId) =>
      (select(episodes)
            ..where((e) => e.seasonId.equals(seasonId))
            ..orderBy([(e) => OrderingTerm.asc(e.episodeNumber)]))
          .get();

  /// Watch physical media sources for a movie.
  Stream<List<MediaSource>> watchSourcesForMovie(String movieId) =>
      (select(mediaSources)..where((s) => s.movieId.equals(movieId))).watch();

  /// Watch physical media sources for an episode.
  Stream<List<MediaSource>> watchSourcesForEpisode(String episodeId) => (select(
    mediaSources,
  )..where((s) => s.episodeId.equals(episodeId))).watch();

  /// Delete a physical media source record (e.g. removing device-local copy).
  Future<int> deleteMediaSource(String sourceId) =>
      (delete(mediaSources)..where((s) => s.id.equals(sourceId))).go();

  /// Watch active transfer jobs for a movie.
  Stream<List<TransferJob>> watchActiveTransferJobsForMovie(String movieId) =>
      (select(transferJobs)..where(
            (j) =>
                j.mediaType.equals('movie') &
                j.mediaId.equals(movieId) &
                (j.status.equals('QUEUED') | j.status.equals('DOWNLOADING')),
          ))
          .watch();

  /// Watch active transfer jobs for an episode.
  Stream<List<TransferJob>> watchActiveTransferJobsForEpisode(
    String episodeId,
  ) =>
      (select(transferJobs)..where(
            (j) =>
                j.mediaType.equals('episode') &
                j.mediaId.equals(episodeId) &
                (j.status.equals('QUEUED') | j.status.equals('DOWNLOADING')),
          ))
          .watch();

  /// Create a transfer job record.
  Future<int> createTransferJob(TransferJobsCompanion job) =>
      into(transferJobs).insert(job);

  // --- Curated Collections Queries ---

  /// Watch all collections ordered by name.
  Stream<List<Collection>> watchAllCollections() =>
      (select(collections)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();

  /// Get all collections.
  Future<List<Collection>> getAllCollections() =>
      (select(collections)..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

  /// Find collection by ID.
  Future<Collection?> getCollection(String id) =>
      (select(collections)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Watch collection by ID.
  Stream<Collection?> watchCollection(String id) =>
      (select(collections)..where((c) => c.id.equals(id))).watchSingleOrNull();

  /// Create a new collection.
  Future<int> createCollection(CollectionsCompanion companion) =>
      into(collections).insert(companion);

  /// Delete a collection and its item associations.
  Future<int> deleteCollection(String id) async {
    await (delete(
      collectionItems,
    )..where((ci) => ci.collectionId.equals(id))).go();
    return (delete(collections)..where((c) => c.id.equals(id))).go();
  }

  /// Watch all items inside a collection ordered by display order.
  Stream<List<CollectionItem>> watchItemsForCollection(String collectionId) =>
      (select(collectionItems)
            ..where((ci) => ci.collectionId.equals(collectionId))
            ..orderBy([(ci) => OrderingTerm.asc(ci.displayOrder)]))
          .watch();

  /// Get all items inside a collection ordered by display order.
  Future<List<CollectionItem>> getItemsForCollection(String collectionId) =>
      (select(collectionItems)
            ..where((ci) => ci.collectionId.equals(collectionId))
            ..orderBy([(ci) => OrderingTerm.asc(ci.displayOrder)]))
          .get();

  /// Add an item to a collection.
  Future<int> addItemToCollection(CollectionItemsCompanion companion) =>
      into(collectionItems).insert(companion);

  /// Remove an item from a collection.
  Future<int> removeItemFromCollection(
    String collectionId, {
    String? movieId,
    String? tvShowId,
  }) {
    final query = delete(collectionItems)
      ..where((ci) => ci.collectionId.equals(collectionId));
    if (movieId != null) {
      query.where((ci) => ci.movieId.equals(movieId));
    }
    if (tvShowId != null) {
      query.where((ci) => ci.tvShowId.equals(tvShowId));
    }
    return query.go();
  }

  // --- Local Fast Search Queries ---

  /// Search movies by title, original title, or overview.
  Future<List<Movie>> searchMovies(String query) {
    final term = '%${query.trim()}%';
    return (select(movies)
          ..where(
            (m) =>
                m.title.like(term) |
                m.originalTitle.like(term) |
                m.overview.like(term),
          )
          ..orderBy([(m) => OrderingTerm.asc(m.title)]))
        .get();
  }

  /// Search TV shows by title, original title, or overview.
  Future<List<TvShow>> searchTvShows(String query) {
    final term = '%${query.trim()}%';
    return (select(tvShows)
          ..where(
            (t) =>
                t.title.like(term) |
                t.originalTitle.like(term) |
                t.overview.like(term),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .get();
  }

  /// Search episodes by name or overview.
  Future<List<Episode>> searchEpisodes(String query) {
    final term = '%${query.trim()}%';
    return (select(episodes)
          ..where((e) => e.name.like(term) | e.overview.like(term))
          ..orderBy([(e) => OrderingTerm.asc(e.name)]))
        .get();
  }

  // --- Phase 1E: Domain Query Engine ---

  late final DatabaseQueryEngine _queryEngine = DatabaseQueryEngine(this);
  DatabaseQueryEngine get queryEngine => _queryEngine;

  /// Executes a [MovieQuery] returning a paginated [LibraryResult] of [MovieLibraryItem].
  Future<LibraryResult<MovieLibraryItem>> queryMovies(MovieQuery query) =>
      _queryEngine.queryMovies(query);

  /// Streams [MovieQuery] results reactively.
  Stream<LibraryResult<MovieLibraryItem>> watchMovies(MovieQuery query) =>
      _queryEngine.watchMovies(query);

  /// Executes a [TvShowQuery] returning a paginated [LibraryResult] of [TvShowLibraryItem].
  Future<LibraryResult<TvShowLibraryItem>> queryTvShows(TvShowQuery query) =>
      _queryEngine.queryTvShows(query);

  /// Streams [TvShowQuery] results reactively.
  Stream<LibraryResult<TvShowLibraryItem>> watchTvShows(TvShowQuery query) =>
      _queryEngine.watchTvShows(query);

  /// Executes a [SeasonQuery] returning a [LibraryResult] of [SeasonLibraryItem].
  Future<LibraryResult<SeasonLibraryItem>> querySeasons(SeasonQuery query) =>
      _queryEngine.querySeasons(query);

  /// Streams [SeasonQuery] results reactively.
  Stream<LibraryResult<SeasonLibraryItem>> watchSeasons(SeasonQuery query) =>
      _queryEngine.watchSeasons(query);

  /// Executes an [EpisodeQuery] returning a paginated [LibraryResult] of [EpisodeLibraryItem].
  Future<LibraryResult<EpisodeLibraryItem>> queryEpisodes(EpisodeQuery query) =>
      _queryEngine.queryEpisodes(query);

  /// Streams [EpisodeQuery] results reactively.
  Stream<LibraryResult<EpisodeLibraryItem>> watchEpisodes(EpisodeQuery query) =>
      _queryEngine.watchEpisodes(query);

  /// Executes a [CollectionQuery] returning a paginated [LibraryResult] of [CollectionLibraryItem].
  Future<LibraryResult<CollectionLibraryItem>> queryCollections(
    CollectionQuery query,
  ) => _queryEngine.queryCollections(query);

  /// Streams [CollectionQuery] results reactively.
  Stream<LibraryResult<CollectionLibraryItem>> watchCollections(
    CollectionQuery query,
  ) => _queryEngine.watchCollections(query);
}
