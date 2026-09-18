import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/platform/platform_storage_adapter.dart';
import 'package:reelhouse/domain/services/playback_launcher_service.dart';

/// Minimal in-memory [PlatformStorageAdapter] for test control.
/// Implements only the two methods used by [PlaybackLauncherService].
class _FakeStorageAdapter implements PlatformStorageAdapter {
  final bool connected;
  final bool filePresent;

  const _FakeStorageAdapter({this.connected = true, this.filePresent = true});

  @override
  Future<bool> isStorageConnected(String rootUri) async => connected;

  @override
  Future<String> resolvePlaybackUri(
    String rootUri,
    String relativePath,
  ) async => '$rootUri\\$relativePath';

  @override
  Future<bool> fileExists(String rootUri, String relativePath) async =>
      filePresent;

  @override
  Future<String?> getFilesystemIdentifier(String rootUri) async => null;

  @override
  Future<String> getStorageDisplayName(String rootUri) async => 'Fake Storage';

  @override
  Future<int> getAvailableBytes(String rootUri) async => 0;

  @override
  Future<int> getTotalBytes(String rootUri) async => 0;

  @override
  Future<int> getFileSizeBytes(String rootUri, String relativePath) async => 0;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to insert the storage + media source records used by multiple tests.
  Future<void> seedData() async {
    final now = DateTime.now();

    // External HDD
    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'hdd-test',
            name: 'Test HDD',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: '0xAABB',
            rootUri: r'D:\Movies',
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    // Movie
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'movie-1',
            detectedTitle: 'Test Movie',
            title: const drift.Value('Test Movie'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Media source pointing at the HDD
    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'source-1',
            storageId: 'hdd-test',
            movieId: const drift.Value('movie-1'),
            relativePath: r'TestMovie.mkv',
            filename: 'TestMovie',
            extension: 'mkv',
            fileSize: BigInt.from(4 * 1024 * 1024 * 1024),
            sourceType: 'removableStorage',
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
          ),
        );
  }

  group('PlaybackLauncherService', () {
    test('returns sourceNotFound when media source does not exist', () async {
      final svc = PlaybackLauncherService(
        database: db,
        storageAdapter: const _FakeStorageAdapter(),
      );

      final result = await svc.launchPlayback(mediaSourceId: 'non-existent-id');
      expect(result.status, PlaybackStatus.sourceNotFound);
      expect(result.isSuccess, false);
    });

    test(
      'returns storageDisconnected when storage record is missing',
      () async {
        final now = DateTime.now();
        // Insert media source referencing a non-existent storage.
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'orphan-movie',
                detectedTitle: 'Orphan Movie',
                title: const drift.Value('Orphan Movie'),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.mediaSources)
            .insert(
              MediaSourcesCompanion.insert(
                id: 'source-no-storage',
                storageId: 'ghost-storage',
                movieId: const drift.Value('orphan-movie'),
                relativePath: 'orphan.mkv',
                filename: 'orphan',
                extension: 'mkv',
                fileSize: BigInt.from(1024),
                sourceType: 'removableStorage',
                createdAt: now,
                firstSeenAt: now,
                lastSeenAt: now,
              ),
            );

        final svc = PlaybackLauncherService(
          database: db,
          storageAdapter: const _FakeStorageAdapter(),
        );

        final result = await svc.launchPlayback(
          mediaSourceId: 'source-no-storage',
        );
        expect(result.status, PlaybackStatus.storageDisconnected);
        expect(result.isSuccess, false);
      },
    );

    test(
      'returns storageDisconnected when adapter reports storage offline',
      () async {
        await seedData();

        final svc = PlaybackLauncherService(
          database: db,
          // Storage is present in DB but physically disconnected.
          storageAdapter: const _FakeStorageAdapter(connected: false),
        );

        final result = await svc.launchPlayback(mediaSourceId: 'source-1');
        expect(result.status, PlaybackStatus.storageDisconnected);
        expect(result.isSuccess, false);
        expect(result.errorMessage, contains('disconnected'));
      },
    );

    test(
      'returns fileNotFound when storage is connected but file is missing',
      () async {
        await seedData();

        final svc = PlaybackLauncherService(
          database: db,
          storageAdapter: const _FakeStorageAdapter(
            connected: true,
            filePresent: false,
          ),
        );

        final result = await svc.launchPlayback(mediaSourceId: 'source-1');
        expect(result.status, PlaybackStatus.fileNotFound);
        expect(result.isSuccess, false);
      },
    );

    test('passes --start-time to VLC and updates watch lifecycle on launch success', () async {
      await seedData();

      String? launchedExec;
      List<String>? launchedArgs;

      final svc = PlaybackLauncherService(
        database: db,
        storageAdapter: const _FakeStorageAdapter(
          connected: true,
          filePresent: true,
        ),
        processStarter: (exec, args, {mode = ProcessStartMode.normal}) async {
          launchedExec = exec;
          launchedArgs = args;
          return _FakeProcess();
        },
      );

      final result = await svc.launchPlayback(
        mediaSourceId: 'source-1',
        startPositionSeconds: 125,
      );

      expect(result.isSuccess, true);
      expect(result.status, PlaybackStatus.success);
      expect(launchedExec, isNotNull);
      expect(launchedArgs, contains('--start-time=125'));

      // Check database state: movie should be IN_PROGRESS and lastPlayedAt set
      final movie = await db.findMovieById('movie-1');
      expect(movie, isNotNull);
      expect(movie!.watchState, 'IN_PROGRESS');
      expect(movie.lastPlayedAt, isNotNull);
    });

    test(
      'does not update watchState or lastPlayedAt when launch fails',
      () async {
        await seedData();

        final svc = PlaybackLauncherService(
          database: db,
          storageAdapter: const _FakeStorageAdapter(connected: false),
        );

        final result = await svc.launchPlayback(mediaSourceId: 'source-1');
        expect(result.isSuccess, false);

        final movie = await db.findMovieById('movie-1');
        expect(movie!.watchState, 'UNWATCHED');
        expect(movie.lastPlayedAt, isNull);
      },
    );
  });
}

class _FakeProcess implements Process {
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;

  @override
  int get pid => 12345;

  @override
  Future<int> get exitCode => Future.value(0);

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  Stream<List<int>> get stdout => const Stream.empty();

  @override
  IOSink get stdin => throw UnimplementedError();
}
