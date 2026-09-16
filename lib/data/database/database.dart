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
    Collections,
    CollectionItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? connect());

  @override
  int get schemaVersion => 4;

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
          ),
        );
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
    String? metadataProvider,
    String? providerItemId,
    DateTime? metadataUpdatedAt,
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
        metadataProvider: metadataProvider != null
            ? Value(metadataProvider)
            : const Value.absent(),
        providerItemId: providerItemId != null
            ? Value(providerItemId)
            : const Value.absent(),
        metadataUpdatedAt: metadataUpdatedAt != null
            ? Value(metadataUpdatedAt)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update TV show record with fetched TMDB/fallback metadata.
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
    String? metadataProvider,
    String? providerItemId,
    DateTime? metadataUpdatedAt,
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
        metadataProvider: metadataProvider != null
            ? Value(metadataProvider)
            : const Value.absent(),
        providerItemId: providerItemId != null
            ? Value(providerItemId)
            : const Value.absent(),
        metadataUpdatedAt: metadataUpdatedAt != null
            ? Value(metadataUpdatedAt)
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

  /// Watch movie by its internal ID.
  Stream<Movie?> watchMovieById(String movieId) =>
      (select(movies)..where((m) => m.id.equals(movieId))).watchSingleOrNull();

  /// Find TV show by its internal ID.
  Future<TvShow?> findTvShowById(String showId) =>
      (select(tvShows)..where((t) => t.id.equals(showId))).getSingleOrNull();

  /// Watch TV show by its internal ID.
  Stream<TvShow?> watchTvShowById(String showId) =>
      (select(tvShows)..where((t) => t.id.equals(showId))).watchSingleOrNull();

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
}
