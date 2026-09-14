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
}
