import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/domain/services/storage_monitor_service.dart';

class MockStorageIdentityService implements StorageIdentityService {
  final Map<String, bool> connectedMap = {};

  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'mock-id';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      'Mock Drive';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async =>
      connectedMap[rootUriOrPath] ?? false;

  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;

  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {}
}

void main() {
  late AppDatabase db;
  late MockStorageIdentityService identityService;
  late StorageMonitorService monitorService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    identityService = MockStorageIdentityService();
    monitorService = StorageMonitorService(
      database: db,
      storageIdentityService: identityService,
    );
  });

  tearDown(() async {
    monitorService.dispose();
    await db.close();
  });

  test(
    'cascades drive disconnection to media sources and emits event',
    () async {
      const driveUri = r'D:\Movies';
      identityService.connectedMap[driveUri] = true;

      // 1. Insert external storage
      final now = DateTime.now();
      await db.upsertStorage(
        StoragesCompanion.insert(
          id: 'hdd-1',
          name: 'Movies HDD',
          storageType: 'REMOVABLE_VOLUME',
          filesystemIdentifier: '0x1234',
          rootUri: driveUri,
          lastSeenAt: now,
          available: const drift.Value(true),
        ),
      );

      // 2. Insert movie and media source
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'movie-1',
              detectedTitle: 'Interstellar',
              title: const drift.Value('Interstellar'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-1',
              movieId: const drift.Value('movie-1'),
              storageId: 'hdd-1',
              sourceType: 'removableStorage',
              relativePath: 'Interstellar.mkv',
              filename: 'Interstellar.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // Verify initially available
      final initialSources = await db.getSourcesForMovie('movie-1');
      expect(initialSources.first.available, isTrue);

      // 3. Simulate drive disconnection
      identityService.connectedMap[driveUri] = false;

      final events = <StorageConnectivityEvent>[];
      final sub = monitorService.onConnectivityChanged.listen(events.add);

      await monitorService.checkAllStorages();

      // Verify storage updated
      final storage = (await db.getAllStorages()).firstWhere(
        (s) => s.id == 'hdd-1',
      );
      expect(storage.available, isFalse);

      // Verify media source marked unavailable
      final updatedSources = await db.getSourcesForMovie('movie-1');
      expect(updatedSources.first.available, isFalse);

      // Verify event emitted
      expect(events.length, 1);
      expect(events.first.isConnected, isFalse);
      expect(events.first.storage.id, 'hdd-1');

      // 4. Simulate drive reconnection
      identityService.connectedMap[driveUri] = true;
      await monitorService.checkAllStorages();

      final reconnectedStorage = (await db.getAllStorages()).firstWhere(
        (s) => s.id == 'hdd-1',
      );
      expect(reconnectedStorage.available, isTrue);

      final reconnectedSources = await db.getSourcesForMovie('movie-1');
      expect(reconnectedSources.first.available, isTrue);

      expect(events.length, 2);
      expect(events.last.isConnected, isTrue);

      await sub.cancel();
    },
  );
}
