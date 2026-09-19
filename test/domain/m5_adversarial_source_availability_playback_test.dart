import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/services/transfer_service_impl.dart';
import 'package:reelhouse/domain/models/availability_status.dart';
import 'package:reelhouse/domain/models/device_storage_destination.dart';
import 'package:reelhouse/domain/models/playback_resolution.dart';
import 'package:reelhouse/domain/models/transfer_models.dart';
import 'package:reelhouse/domain/scanner/library_scanner_service.dart';
import 'package:reelhouse/domain/services/availability_resolver.dart';
import 'package:reelhouse/domain/services/device_storage_service.dart';
import 'package:reelhouse/domain/services/playback_source_resolver.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/domain/services/transfer_coordinator.dart';

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

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late Directory hddDir;
  late Directory deviceDir;
  late FakeDeviceStorageService deviceStorage;
  late FakeStorageIdentityService storageIdentity;
  late TransferServiceImpl transferService;
  late TransferCoordinator coordinator;
  late AvailabilityResolver availabilityResolver;
  const playbackResolver = PlaybackSourceResolver();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('reelhouse_m56_avail_');
    hddDir = Directory(p.join(tempDir.path, 'external_hdd'))..createSync();
    deviceDir = Directory(p.join(tempDir.path, 'app_device'))..createSync();

    deviceStorage = FakeDeviceStorageService(rootPath: deviceDir.path);
    storageIdentity = FakeStorageIdentityService();

    transferService = TransferServiceImpl(
      database: db,
      deviceStorageService: deviceStorage,
      storageIdentityService: storageIdentity,
    );

    coordinator = TransferCoordinator(
      transferService: transferService,
      database: db,
      deviceStorageService: deviceStorage,
      storageIdentityService: storageIdentity,
    );

    availabilityResolver = AvailabilityResolver();

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
    transferService.dispose();
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
    String watchState = 'IN_PROGRESS',
    int playbackPosition = 1200,
    DateTime? lastPlayedAt,
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
            watchState: drift.Value(watchState),
            playbackPositionSeconds: drift.Value(playbackPosition),
            lastPlayedAt: drift.Value(lastPlayedAt ?? now),
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
        id: 'src_hdd_$id',
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

  group('Area M & N — External HDD + Device Copy Availability Coexistence', () {
    test('Both available -> HDD disconnected -> Device unavailable -> Both disconnected states', () async {
      await seedMovie(
        id: 'mov_multi_avail',
        title: 'The Dark Knight',
        year: 2008,
      );

      // Save offline
      final result = await coordinator.requestMovieTransfer('mov_multi_avail');
      expect(result.state, TransferState.completed);

      // State 1: Both HDD and Device are connected/available
      var sources = await db.getSourcesForMovie('mov_multi_avail');
      expect(sources.length, 2);

      var checkInfos = [
        SourceCheckInfo(
          sourceId: 'src_hdd_mov_multi_avail',
          sourceType: 'removableStorage',
          isSourceAvailable: true,
          storageId: 'hdd-1',
          storageName: 'Passport HDD',
          isStorageConnected: true,
        ),
        SourceCheckInfo(
          sourceId: sources.firstWhere((s) => s.sourceType == 'localDevice').id,
          sourceType: 'localDevice',
          isSourceAvailable: true,
          storageId: 'local-device',
          storageName: 'This Device',
          isStorageConnected: true,
        ),
      ];

      var avail = availabilityResolver.resolve(checkInfos);
      expect(avail, AvailabilityStatus.availableOnMultipleSources);
      var playRes = playbackResolver.resolve(checkInfos);
      expect(playRes.action, PlaybackAction.playOffline);
      expect(playRes.isPlayable, true);

      // State 2: HDD disconnected, Device copy connected
      checkInfos = [
        SourceCheckInfo(
          sourceId: 'src_hdd_mov_multi_avail',
          sourceType: 'removableStorage',
          isSourceAvailable: true,
          storageId: 'hdd-1',
          storageName: 'Passport HDD',
          isStorageConnected: false, // Disconnected!
        ),
        SourceCheckInfo(
          sourceId: sources.firstWhere((s) => s.sourceType == 'localDevice').id,
          sourceType: 'localDevice',
          isSourceAvailable: true,
          storageId: 'local-device',
          storageName: 'This Device',
          isStorageConnected: true,
        ),
      ];

      avail = availabilityResolver.resolve(checkInfos);
      expect(avail, AvailabilityStatus.availableLocally);
      playRes = playbackResolver.resolve(checkInfos);
      expect(playRes.action, PlaybackAction.playOffline);
      expect(playRes.isPlayable, true);

      // State 3: HDD connected, Device storage unmounted/inaccessible
      checkInfos = [
        SourceCheckInfo(
          sourceId: 'src_hdd_mov_multi_avail',
          sourceType: 'removableStorage',
          isSourceAvailable: true,
          storageId: 'hdd-1',
          storageName: 'Passport HDD',
          isStorageConnected: true,
        ),
        SourceCheckInfo(
          sourceId: sources.firstWhere((s) => s.sourceType == 'localDevice').id,
          sourceType: 'localDevice',
          isSourceAvailable: false, // Inaccessible!
          storageId: 'local-device',
          storageName: 'This Device',
          isStorageConnected: false,
        ),
      ];

      avail = availabilityResolver.resolve(checkInfos);
      expect(avail, AvailabilityStatus.availableOnRemovableStorage);
      playRes = playbackResolver.resolve(checkInfos);
      expect(playRes.action, PlaybackAction.play);
      expect(playRes.isPlayable, true);

      // State 4: Both disconnected
      checkInfos = [
        SourceCheckInfo(
          sourceId: 'src_hdd_mov_multi_avail',
          sourceType: 'removableStorage',
          isSourceAvailable: true,
          storageId: 'hdd-1',
          storageName: 'Passport HDD',
          isStorageConnected: false,
        ),
        SourceCheckInfo(
          sourceId: sources.firstWhere((s) => s.sourceType == 'localDevice').id,
          sourceType: 'localDevice',
          isSourceAvailable: false,
          storageId: 'local-device',
          storageName: 'This Device',
          isStorageConnected: false,
        ),
      ];

      avail = availabilityResolver.resolve(checkInfos);
      expect(avail, AvailabilityStatus.unavailable);
      playRes = playbackResolver.resolve(checkInfos);
      expect(playRes.action, PlaybackAction.connectDisk);
      expect(playRes.isPlayable, false);

      // Invariant check: Neither source was deleted or removed from database
      final finalSources = await db.getSourcesForMovie('mov_multi_avail');
      expect(finalSources.length, 2);
    });
  });

  group('Area P, Q & R — Offline Deletion Hardening', () {
    test('Deleting offline copy removes only device file and MediaSource, keeping original media and watch state intact', () async {
      final playedTime = DateTime(2026, 9, 1, 10, 0);
      await seedMovie(
        id: 'mov_del_test',
        title: 'Forrest Gump',
        year: 1994,
        watchState: 'IN_PROGRESS',
        playbackPosition: 3600,
        lastPlayedAt: playedTime,
      );

      // Save offline
      await coordinator.requestMovieTransfer('mov_del_test');
      var sources = await db.getSourcesForMovie('mov_del_test');
      final localSource = sources.firstWhere(
        (s) => s.sourceType == 'localDevice',
      );

      // Delete offline copy
      await coordinator.deleteOfflineCopy(localSource.id);

      // Verify device MediaSource is deleted
      sources = await db.getSourcesForMovie('mov_del_test');
      expect(sources.length, 1);
      expect(sources.first.sourceType, 'removableStorage');
      expect(sources.first.id, 'src_hdd_mov_del_test');

      // Verify original file on HDD exists
      final hddFile = File(
        p.join(hddDir.path, 'Movies', 'Forrest Gump (1994).mkv'),
      );
      expect(hddFile.existsSync(), true);

      // Verify logical Movie record and watch state are untouched
      final movie = await db.findMovieById('mov_del_test');
      expect(movie, isNotNull);
      expect(movie!.title, 'Forrest Gump');
      expect(movie.watchState, 'IN_PROGRESS');
      expect(movie.playbackPositionSeconds, 3600);
      expect(movie.lastPlayedAt, playedTime);

      // Idempotency: Calling deleteOfflineCopy a second time on the same ID is safe
      await coordinator.deleteOfflineCopy(localSource.id);
    });

    test('Deleting offline copy when physical file is already missing on disk removes DB record cleanly', () async {
      await seedMovie(
        id: 'mov_del_missing_file',
        title: 'Pulp Fiction',
        year: 1994,
      );

      await coordinator.requestMovieTransfer('mov_del_missing_file');
      var sources = await db.getSourcesForMovie('mov_del_missing_file');
      final localSource = sources.firstWhere(
        (s) => s.sourceType == 'localDevice',
      );

      // Delete physical file manually behind REELHOUSE's back
      final physicalFile = File(
        p.join(deviceDir.path, localSource.relativePath),
      );
      if (physicalFile.existsSync()) {
        physicalFile.deleteSync();
      }

      // Deleting offline copy should still cleanly delete the MediaSource row
      await coordinator.deleteOfflineCopy(localSource.id);
      sources = await db.getSourcesForMovie('mov_del_missing_file');
      expect(sources.length, 1);
      expect(sources.first.sourceType, 'removableStorage');
    });
  });

  group('Area U — Scanner Isolation Invariant', () {
    test('LibraryScannerService strictly ignores application-managed device storage', () async {
      await seedMovie(id: 'mov_scan_iso', title: 'Casablanca', year: 1942);
      await coordinator.requestMovieTransfer('mov_scan_iso');

      final deviceStorageRow = await db.getDeviceStorage();
      expect(deviceStorageRow, isNotNull);

      final scanner = LibraryScannerService(
        database: db,
        storageIdentityService: storageIdentity,
      );

      final scanSummary = await scanner.scanStorage(deviceStorageRow!);
      expect(scanSummary.filesDiscovered, 0);
      expect(scanSummary.newSourcesAdded, 0);
      expect(scanSummary.moviesIdentified, 0);

      // Verify no duplicate logical movies or media sources were created
      final movies = await db.select(db.movies).get();
      expect(movies.where((m) => m.id == 'mov_scan_iso').length, 1);
    });
  });

  group('Area V — Watch State and History Invariant', () {
    test('Watch state and playback position remain attached to logical movie regardless of offline transfers', () async {
      final playedTime = DateTime(2026, 9, 15, 20, 30);
      await seedMovie(
        id: 'mov_watch_test',
        title: 'Spirited Away',
        year: 2001,
        watchState: 'WATCHED',
        playbackPosition: 7500,
        lastPlayedAt: playedTime,
      );

      // Save offline
      await coordinator.requestMovieTransfer('mov_watch_test');

      // Verify movie watch state is identical
      final movieAfterTransfer = await db.findMovieById('mov_watch_test');
      expect(movieAfterTransfer!.watchState, 'WATCHED');
      expect(movieAfterTransfer.playbackPositionSeconds, 7500);
      expect(movieAfterTransfer.lastPlayedAt, playedTime);

      // Updating playback state (e.g. playing the offline copy) updates logical item
      await (db.update(
        db.movies,
      )..where((m) => m.id.equals('mov_watch_test'))).write(
        const MoviesCompanion(
          playbackPositionSeconds: drift.Value(8000),
          watchState: drift.Value('WATCHED'),
        ),
      );
      final updatedMovie = await db.findMovieById('mov_watch_test');
      expect(updatedMovie!.playbackPositionSeconds, 8000);
      expect(updatedMovie.watchState, 'WATCHED');
    });
  });
}
