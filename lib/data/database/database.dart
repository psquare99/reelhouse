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
}
