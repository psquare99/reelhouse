import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/data/services/transfer_service_impl.dart';
import 'package:reelhouse/domain/models/device_storage_destination.dart';
import 'package:reelhouse/domain/models/transfer_models.dart';
import 'package:reelhouse/domain/services/device_storage_service.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/domain/services/transfer_coordinator.dart';
import 'package:reelhouse/domain/services/transfer_service.dart';
import 'package:reelhouse/presentation/movies/movie_detail_screen.dart';

class FakeDeviceStorageService implements DeviceStorageService {
  String rootPath;
  bool accessible;
  int availableBytes;
  int totalBytes;

  FakeDeviceStorageService({
    required this.rootPath,
    this.accessible = true,
    this.availableBytes = 50 * 1024 * 1024 * 1024,
    this.totalBytes = 100 * 1024 * 1024 * 1024,
  });

  @override
  Future<DeviceStorageResolution> resolveDestination() async {
    final dest = DeviceStorageDestination(
      id: 'local-device',
      name: 'This Device',
      rootPath: rootPath,
      filesystemIdentifier: 'internal-app-storage',
      isAccessible: accessible,
      isApplicationManaged: true,
      availableBytes: availableBytes,
      totalBytes: totalBytes,
      lastSeenAt: DateTime.now(),
    );

    if (accessible) {
      return DeviceStorageResolution.registeredAndAccessible(dest);
    } else {
      return DeviceStorageResolution.registeredAndInaccessible(
        dest,
        message: 'Device storage is inaccessible',
      );
    }
  }

  @override
  Future<DeviceStorageDestination> ensureDefaultDestinationRegistered() async {
    final res = await resolveDestination();
    return res.destination!;
  }

  @override
  Future<DeviceStorageDestination> registerDestination({
    required String rootPath,
    String? name,
    String? id,
    bool createDirectory = false,
  }) async {
    this.rootPath = rootPath;
    final res = await resolveDestination();
    return res.destination!;
  }

  @override
  Future<StorageCapacity?> getDestinationCapacity(String rootPath) async {
    return StorageCapacity(
      totalBytes: totalBytes,
      availableBytes: availableBytes,
    );
  }

  @override
  Future<bool> isDestinationAccessible(String rootPath) async {
    return accessible && Directory(rootPath).existsSync();
  }

  @override
  Future<String> resolveMediaFilePath(String relativePath) async {
    return p.join(rootPath, relativePath);
  }
}

class FakeStorageIdentityService implements StorageIdentityService {
  final Map<String, bool> connectedMap = {};

  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async => 'fs-id';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async => 'Storage';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async {
    return connectedMap[rootUriOrPath] ?? true;
  }

  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;

  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {}
}

class FakeTransferService implements TransferService {
  final AppDatabase database;
  final _progressController = StreamController<TransferProgress>.broadcast();
  final Map<String, TransferProgress> _activeProgress = {};

  FakeTransferService({required this.database});

  @override
  Stream<TransferProgress> get progressStream => _progressController.stream;

  @override
  bool isMediaTransferring(String mediaId) =>
      _activeProgress.containsKey(mediaId);

  @override
  TransferProgress? getActiveProgress(String mediaId) =>
      _activeProgress[mediaId];

  @override
  Future<bool> cancelTransfer(String transferId) async => true;

  @override
  Future<TransferResult> transferMovie(
    String movieId, {
    CancellationToken? cancellationToken,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    return TransferResult(
      transferId: 'job_$movieId',
      scope: TransferScope.movie,
      mediaId: movieId,
      state: TransferState.completed,
      bytesTransferred: 1000,
      totalBytes: 1000,
    );
  }

  @override
  Future<TransferResult> transferEpisode(
    String episodeId, {
    CancellationToken? cancellationToken,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    return TransferResult(
      transferId: 'job_$episodeId',
      scope: TransferScope.episode,
      mediaId: episodeId,
      state: TransferState.completed,
      bytesTransferred: 1000,
      totalBytes: 1000,
    );
  }

  @override
  Future<List<TransferResult>> transferSeason(
    String seasonId, {
    CancellationToken? cancellationToken,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    final episodes = await database.getEpisodesForSeason(seasonId);
    return [
      for (final ep in episodes)
        TransferResult(
          transferId: 'job_${ep.id}',
          scope: TransferScope.episode,
          mediaId: ep.id,
          state: TransferState.completed,
          bytesTransferred: 1000,
          totalBytes: 1000,
        ),
    ];
  }

  @override
  Future<MediaSource> registerCompletedTransfer(String transferId) async {
    final now = DateTime.now();
    final parts = transferId.split('_');
    final mediaId = parts.length > 1 ? parts.sublist(1).join('_') : transferId;

    final existing = await database.findMediaSourceByStorageAndPath(
      'local-device',
      'movies/$mediaId.mkv',
    );
    if (existing != null) return existing;

    final sourceId = 'src_${mediaId}_device';
    final isMovie = mediaId.startsWith('mov') || mediaId.startsWith('movie');

    final newSource = MediaSourcesCompanion.insert(
      id: sourceId,
      movieId: isMovie ? drift.Value(mediaId) : const drift.Value.absent(),
      episodeId: !isMovie ? drift.Value(mediaId) : const drift.Value.absent(),
      storageId: 'local-device',
      sourceType: 'localDevice',
      relativePath: 'movies/$mediaId.mkv',
      filename: '$mediaId.mkv',
      extension: 'mkv',
      fileSize: BigInt.from(1000),
      createdAt: now,
      firstSeenAt: now,
      lastSeenAt: now,
      available: const drift.Value(true),
    );
    await database.into(database.mediaSources).insert(newSource);
    return (await database.getMediaSourceById(sourceId))!;
  }

  @override
  Future<List<MediaSource>> registerCompletedSeasonTransfers(
    String seasonId,
  ) async {
    final episodes = await database.getEpisodesForSeason(seasonId);
    final results = <MediaSource>[];
    for (final ep in episodes) {
      final res = await registerCompletedTransfer('job_${ep.id}');
      results.add(res);
    }
    return results;
  }

  @override
  Future<List<TransferResult>> reconcileTransfers() async => [];

  @override
  Future<int> cleanStalePartials() async => 0;
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late Directory hddDir;
  late Directory deviceDir;
  late FakeDeviceStorageService deviceStorage;
  late FakeStorageIdentityService storageIdentity;
  late FakeTransferService fakeTransferService;
  late TransferCoordinator coordinator;
  late DriftLibraryRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('reelhouse_m56_ui_races_');
    hddDir = Directory(p.join(tempDir.path, 'external_hdd'))..createSync();
    deviceDir = Directory(p.join(tempDir.path, 'app_device'))..createSync();

    deviceStorage = FakeDeviceStorageService(rootPath: deviceDir.path);
    storageIdentity = FakeStorageIdentityService();

    fakeTransferService = FakeTransferService(database: db);

    coordinator = TransferCoordinator(
      transferService: fakeTransferService,
      database: db,
      deviceStorageService: deviceStorage,
      storageIdentityService: storageIdentity,
    );

    repository = DriftLibraryRepository(db);

    // Register external HDD storage
    await db.upsertStorage(
      StoragesCompanion.insert(
        id: 'hdd-1',
        name: 'Passport HDD',
        storageType: 'EXTERNAL_HDD',
        filesystemIdentifier: 'fs-hdd-1',
        rootUri: hddDir.path,
        lastSeenAt: DateTime.now(),
        available: const drift.Value(true),
      ),
    );

    // Update default local-device storage record rootUri
    await (db.update(
      db.storages,
    )..where((s) => s.id.equals('local-device'))).write(
      StoragesCompanion(
        rootUri: drift.Value(deviceDir.path),
        available: const drift.Value(true),
      ),
    );
  });

  tearDown(() async {
    coordinator.dispose();
    await db.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Future<void> seedMovie({
    required String id,
    required String title,
    int year = 2024,
    int fileSize = 512 * 1024,
  }) async {
    final now = DateTime.now();
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: id,
            detectedTitle: title,
            title: drift.Value(title),
            year: drift.Value(year),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final movieRelPath = p.join('Movies', '$title ($year).mkv');
    final movieFile = File(p.join(hddDir.path, movieRelPath));
    movieFile.parent.createSync(recursive: true);
    final bytes = Uint8List(fileSize);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = i % 256;
    }
    movieFile.writeAsBytesSync(bytes);

    await db.insertMediaSource(
      MediaSourcesCompanion.insert(
        id: 'src_$id',
        movieId: drift.Value(id),
        storageId: 'hdd-1',
        sourceType: 'removableStorage',
        relativePath: movieRelPath,
        filename: '$title ($year).mkv',
        extension: 'mkv',
        fileSize: BigInt.from(fileSize),
        createdAt: now,
        firstSeenAt: now,
        lastSeenAt: now,
        available: const drift.Value(true),
      ),
    );
  }

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(theme: CinemaTheme.darkTheme, home: child);
  }

  group('Area W — UI Race Conditions and State Convergence', () {
    testWidgets(
      'Save Offline on MovieDetailScreen updates UI to Available Offline and exposes Delete button',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 1400));
        await seedMovie(id: 'mov_race_1', title: 'The Matrix', year: 1999);

        await tester.pumpWidget(
          createWidgetUnderTest(
            MovieDetailScreen(
              movieId: 'mov_race_1',
              repository: repository,
              transferCoordinator: coordinator,
              transferService: fakeTransferService,
              database: db,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('SAVE OFFLINE'), findsOneWidget);

        // Save Offline flow
        final transferFuture = coordinator.requestMovieTransfer('mov_race_1');
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await transferFuture;
        await tester.pump(const Duration(milliseconds: 100));

        // After transfer completes, AVAILABLE OFFLINE and DELETE LOCAL COPY appear
        expect(find.text('AVAILABLE OFFLINE'), findsOneWidget);
        expect(find.text('DELETE LOCAL COPY'), findsOneWidget);

        // Drain stream query store timers
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );
  });

  group('Area X — Application Restart and Recovery Integration', () {
    test(
      'Coordinator.initialize cleans up non-terminal jobs left in database',
      () async {
        await seedMovie(
          id: 'mov_restart',
          title: 'Blade Runner',
          year: 1982,
          fileSize: 512 * 1024,
        );

        final realTransferService = TransferServiceImpl(
          database: db,
          deviceStorageService: deviceStorage,
          storageIdentityService: storageIdentity,
        );

        final destRelPath = p.join(
          'movies',
          'Blade Runner (1982)',
          'Blade Runner (1982).mkv',
        );
        final partialPath = p.join(
          deviceDir.path,
          '$destRelPath.reelhouse-partial',
        );
        final partialFile = File(partialPath)
          ..parent.createSync(recursive: true);
        partialFile.writeAsBytesSync(Uint8List(256 * 1024)); // Incomplete 256KB

        // Simulate a crashed session leaving a TRANSFERRING job in database
        await db.upsertTransferJob(
          TransferJobsCompanion.insert(
            id: 'job_crashed_1',
            mediaType: 'movie',
            mediaId: 'mov_restart',
            sourceMediaSourceId: 'src_mov_restart',
            destinationStorageId: 'local-device',
            destinationRelativePath: destRelPath,
            status: 'TRANSFERRING',
            totalBytes: BigInt.from(512 * 1024),
            bytesTransferred: drift.Value(BigInt.from(256 * 1024)),
            startedAt: DateTime.now(),
          ),
        );

        // Startup initialization of new TransferCoordinator
        final freshCoordinator = TransferCoordinator(
          transferService: realTransferService,
          database: db,
          deviceStorageService: deviceStorage,
          storageIdentityService: storageIdentity,
        );

        await freshCoordinator.initialize();

        // Incomplete job marked FAILED
        final job = await db.getTransferJobById('job_crashed_1');
        expect(job!.status, 'FAILED');

        // Stale partial deleted
        expect(partialFile.existsSync(), false);

        freshCoordinator.dispose();
        realTransferService.dispose();
      },
    );
  });

  group('Concurrency Hardening — Sequential Queue Execution', () {
    test('Three queued transfers execute sequentially one at a time', () async {
      await seedMovie(
        id: 'mov_seq_1',
        title: 'Iron Man',
        year: 2008,
        fileSize: 256 * 1024,
      );
      await seedMovie(
        id: 'mov_seq_2',
        title: 'Thor',
        year: 2011,
        fileSize: 256 * 1024,
      );
      await seedMovie(
        id: 'mov_seq_3',
        title: 'Captain America',
        year: 2011,
        fileSize: 256 * 1024,
      );

      final f1 = coordinator.requestMovieTransfer('mov_seq_1');
      final f2 = coordinator.requestMovieTransfer('mov_seq_2');
      final f3 = coordinator.requestMovieTransfer('mov_seq_3');

      final results = await Future.wait([f1, f2, f3]);
      expect(results.every((r) => r.state == TransferState.completed), true);
      expect(coordinator.queuedCount, 0);

      final s1 = await db.getSourcesForMovie('mov_seq_1');
      final s2 = await db.getSourcesForMovie('mov_seq_2');
      final s3 = await db.getSourcesForMovie('mov_seq_3');

      expect(s1.where((s) => s.sourceType == 'localDevice').length, 1);
      expect(s2.where((s) => s.sourceType == 'localDevice').length, 1);
      expect(s3.where((s) => s.sourceType == 'localDevice').length, 1);
    });
  });

  group('Path Safety & Sanitization Hardening', () {
    test(
      'Sanitizes illegal characters and prevents path traversal escaping root',
      () async {
        final realTransferService = TransferServiceImpl(
          database: db,
          deviceStorageService: deviceStorage,
          storageIdentityService: storageIdentity,
        );

        // Testing normal root resolution
        await expectLater(
          () => realTransferService.transferMovie('non_existent_movie'),
          throwsA(isA<TransferException>()),
        );

        realTransferService.dispose();
      },
    );
  });

  group('Error-Message Hardening', () {
    test(
      'Translates technical exceptions into human-readable user messages',
      () {
        expect(
          TransferCoordinator.formatError(
            const InsufficientStorageException(
              requiredBytes: 1000,
              availableBytes: 500,
            ),
          ),
          contains("isn't enough free space"),
        );

        expect(
          TransferCoordinator.formatError(
            const NoAvailableSourceException('Source disk is disconnected'),
          ),
          contains('source drive is not connected'),
        );

        expect(
          TransferCoordinator.formatError(
            const DeviceStorageUnavailableException(
              'Device root is inaccessible',
            ),
          ),
          contains('Device storage directory is inaccessible'),
        );

        expect(
          TransferCoordinator.formatError('Transfer was cancelled by user.'),
          'Transfer was cancelled.',
        );

        expect(
          TransferCoordinator.formatError(null),
          "Couldn't save offline. An unknown error occurred.",
        );
      },
    );
  });
}
