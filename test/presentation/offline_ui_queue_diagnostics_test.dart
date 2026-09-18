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
import 'package:reelhouse/data/platform/local_storage_manager_impl.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/domain/models/device_storage_destination.dart';
import 'package:reelhouse/domain/models/transfer_models.dart';
import 'package:reelhouse/domain/services/device_storage_service.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/domain/services/transfer_coordinator.dart';
import 'package:reelhouse/domain/services/transfer_service.dart';
import 'package:reelhouse/presentation/movies/movie_detail_screen.dart';
import 'package:reelhouse/presentation/offline/offline_screen.dart';
import 'package:reelhouse/presentation/settings/settings_screen.dart';
import 'package:reelhouse/presentation/tv_shows/tv_show_detail_screen.dart';

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
      id: 'device-storage-internal',
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
  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'fs-identity-1';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      'Cinema HDD';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async =>
      Directory(rootUriOrPath).existsSync();

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
      'device-storage-internal',
      'movies/$mediaId.mkv',
    );
    if (existing != null) return existing;

    final sourceId = 'src_${mediaId}_device';
    final isMovie = mediaId.startsWith('movie');

    final newSource = MediaSourcesCompanion.insert(
      id: sourceId,
      movieId: isMovie ? drift.Value(mediaId) : const drift.Value.absent(),
      episodeId: !isMovie ? drift.Value(mediaId) : const drift.Value.absent(),
      storageId: 'device-storage-internal',
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
  late DriftLibraryRepository repo;
  late Directory tempDir;
  late Directory sourceDir;
  late Directory destDir;
  late FakeDeviceStorageService deviceStorageService;
  late StorageIdentityService storageIdentityService;
  late FakeTransferService transferService;
  late TransferCoordinator coordinator;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftLibraryRepository(db);
    tempDir = await Directory.systemTemp.createTemp('reelhouse_ui_queue_test_');
    sourceDir = Directory(p.join(tempDir.path, 'source'))
      ..createSync(recursive: true);
    destDir = Directory(p.join(tempDir.path, 'dest'))
      ..createSync(recursive: true);

    deviceStorageService = FakeDeviceStorageService(rootPath: destDir.path);
    storageIdentityService = FakeStorageIdentityService();
    transferService = FakeTransferService(database: db);
    coordinator = TransferCoordinator(
      transferService: transferService,
      database: db,
      deviceStorageService: deviceStorageService,
      storageIdentityService: storageIdentityService,
    );
  });

  tearDown(() async {
    coordinator.dispose();
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget createThemedTestApp(Widget child) {
    return MaterialApp(theme: CinemaTheme.darkTheme, home: child);
  }

  testWidgets(
    'MovieDetailScreen Save Offline action, completion badge, and delete local copy',
    (tester) async {
      final now = DateTime.now();

      // 1. Setup DB: Device Storage & External HDD Storage
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'device-storage-internal',
              name: 'This Device',
              storageType: 'DEVICE_LOCAL_STORAGE',
              filesystemIdentifier: 'internal-app-storage',
              rootUri: destDir.path,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'hdd-1',
              name: 'Cinema HDD',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'fs-identity-1',
              rootUri: sourceDir.path,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      final movieFile = File(
        p.join(
          sourceDir.path,
          'Blade Runner 2049 (2017)',
          'Blade Runner 2049.mkv',
        ),
      )..createSync(recursive: true);
      movieFile.writeAsBytesSync(Uint8List(1024 * 64)); // 64 KB

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'movie-br2049',
              detectedTitle: 'Blade Runner 2049',
              title: const drift.Value('Blade Runner 2049'),
              year: const drift.Value(2017),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-br2049-hdd',
              movieId: const drift.Value('movie-br2049'),
              storageId: 'hdd-1',
              sourceType: 'removableStorage',
              relativePath: 'Blade Runner 2049 (2017)/Blade Runner 2049.mkv',
              filename: 'Blade Runner 2049.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1024 * 64),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      await tester.pumpWidget(
        createThemedTestApp(
          MovieDetailScreen(
            movieId: 'movie-br2049',
            repository: repo,
            database: db,
            transferCoordinator: coordinator,
            transferService: transferService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "SAVE OFFLINE" button is present
      expect(find.text('SAVE OFFLINE'), findsOneWidget);
      final transferFuture = coordinator.requestMovieTransfer('movie-br2049');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await transferFuture;
      await tester.pump(const Duration(milliseconds: 100));

      // After transfer finishes, "AVAILABLE OFFLINE" badge and "DELETE LOCAL COPY" button appear
      expect(find.text('AVAILABLE OFFLINE'), findsOneWidget);
      expect(find.text('DELETE LOCAL COPY'), findsOneWidget);

      // Tap "DELETE LOCAL COPY"
      await tester.tap(find.text('DELETE LOCAL COPY'));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete Local Copy?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Copy'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify "SAVE OFFLINE" button is back
      expect(find.text('SAVE OFFLINE'), findsOneWidget);
      expect(find.text('AVAILABLE OFFLINE'), findsNothing);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets('TvShowDetailScreen Save Season Offline and Episode Cards', (
    tester,
  ) async {
    final now = DateTime.now();

    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'device-storage-internal',
            name: 'This Device',
            storageType: 'DEVICE_LOCAL_STORAGE',
            filesystemIdentifier: 'internal-app-storage',
            rootUri: destDir.path,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'hdd-1',
            name: 'Cinema HDD',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: 'fs-identity-1',
            rootUri: sourceDir.path,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'show-chernobyl',
            detectedTitle: 'Chernobyl',
            title: const drift.Value('Chernobyl'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(
            id: 'season-chernobyl-1',
            showId: 'show-chernobyl',
            seasonNumber: 1,
            name: const drift.Value('Season 1'),
          ),
        );

    final ep1File = File(
      p.join(sourceDir.path, 'Chernobyl', 'Season 01', 'Chernobyl.S01E01.mkv'),
    )..createSync(recursive: true);
    ep1File.writeAsBytesSync(Uint8List(1024 * 32));

    await db
        .into(db.episodes)
        .insert(
          EpisodesCompanion.insert(
            id: 'ep-chernobyl-101',
            seasonId: 'season-chernobyl-1',
            episodeNumber: 1,
            name: const drift.Value('1:23:45'),
          ),
        );

    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'src-chernobyl-101-hdd',
            episodeId: const drift.Value('ep-chernobyl-101'),
            storageId: 'hdd-1',
            sourceType: 'removableStorage',
            relativePath: 'Chernobyl/Season 01/Chernobyl.S01E01.mkv',
            filename: 'Chernobyl.S01E01.mkv',
            extension: 'mkv',
            fileSize: BigInt.from(1024 * 32),
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      createThemedTestApp(
        TvShowDetailScreen(
          showId: 'show-chernobyl',
          repository: repo,
          database: db,
          transferCoordinator: coordinator,
          transferService: transferService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "SAVE SEASON OFFLINE" button exists
    expect(find.text('SAVE SEASON OFFLINE'), findsOneWidget);

    // Save season offline and wait for completion
    final seasonFuture = coordinator.requestSeasonTransfer(
      'season-chernobyl-1',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await seasonFuture;
    await tester.pump(const Duration(milliseconds: 100));

    // Episode 1 is now available offline
    final sources = await db.getSourcesForEpisode('ep-chernobyl-101');
    expect(
      sources.any((s) => s.storageId == 'device-storage-internal'),
      isTrue,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('OfflineScreen displays registered offline movie', (
    tester,
  ) async {
    final now = DateTime.now();

    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'device-storage-internal',
            name: 'This Device',
            storageType: 'DEVICE_LOCAL_STORAGE',
            filesystemIdentifier: 'internal-app-storage',
            rootUri: destDir.path,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'movie-arrival',
            detectedTitle: 'Arrival',
            title: const drift.Value('Arrival'),
            year: const drift.Value(2016),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'src-arrival-device',
            movieId: const drift.Value('movie-arrival'),
            storageId: 'device-storage-internal',
            sourceType: 'localDevice',
            relativePath: 'Movies/Arrival (2016)/Arrival.mkv',
            filename: 'Arrival.mkv',
            extension: 'mkv',
            fileSize: BigInt.from(1024 * 100),
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      createThemedTestApp(OfflineScreen(repository: repo, database: db)),
    );
    await tester.pumpAndSettle();

    // Verify movie is displayed in Offline Screen
    expect(find.text('Arrival'), findsOneWidget);
    expect(find.text('1 title stored locally on this device'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets(
    'SettingsScreen displays transfer queue diagnostics and cleanup buttons',
    (tester) async {
      final now = DateTime.now();

      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'device-storage-internal',
              name: 'This Device',
              storageType: 'DEVICE_LOCAL_STORAGE',
              filesystemIdentifier: 'internal-app-storage',
              rootUri: destDir.path,
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // Insert a transfer job record
      await db
          .into(db.transferJobs)
          .insert(
            TransferJobsCompanion.insert(
              id: 'job-test-1',
              mediaType: 'movie',
              mediaId: 'movie-test',
              sourceMediaSourceId: 'src-test',
              destinationStorageId: 'device-storage-internal',
              destinationRelativePath: 'Movies/Test/Test.mkv',
              status: 'COMPLETED',
              bytesTransferred: drift.Value(BigInt.from(1000)),
              totalBytes: BigInt.from(1000),
              startedAt: now,
              completedAt: drift.Value(now),
            ),
          );

      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      await tester.pumpWidget(
        createThemedTestApp(
          SettingsScreen(
            database: db,
            repository: repo,
            storageIdentityService: storageIdentityService,
            localStorageManager: LocalStorageManagerImpl(),
            deviceStorageService: deviceStorageService,
            transferCoordinator: coordinator,
            transferService: transferService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OFFLINE TRANSFER QUEUE & DIAGNOSTICS'), findsOneWidget);
      expect(find.text('Reconcile'), findsOneWidget);
      expect(find.text('Clean Partials'), findsOneWidget);
      expect(find.text('MOVIE: Test.mkv'), findsOneWidget);

      // Tap "Clean Partials"
      await tester.tap(find.text('Clean Partials'));
      await tester.pumpAndSettle();

      // Tap "Reconcile"
      await tester.tap(find.text('Reconcile'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
