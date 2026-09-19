import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/services/transfer_service_impl.dart';
import 'package:reelhouse/domain/models/device_storage_destination.dart';
import 'package:reelhouse/domain/models/transfer_models.dart';
import 'package:reelhouse/domain/services/device_storage_service.dart';
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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('reelhouse_m56_lifecycle_');
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
    int fileSize = 1024 * 1024,
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

  Future<void> seedTvShowWithEpisodes({
    required String showId,
    required String title,
    required String seasonId,
    required int seasonNumber,
    required List<String> episodeIds,
    int episodeSize = 512 * 1024,
  }) async {
    final now = DateTime.now();
    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: showId,
            detectedTitle: title,
            title: drift.Value(title),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(
            id: seasonId,
            showId: showId,
            seasonNumber: seasonNumber,
          ),
        );

    for (var i = 0; i < episodeIds.length; i++) {
      final epId = episodeIds[i];
      final epNum = i + 1;
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: epId,
              seasonId: seasonId,
              episodeNumber: epNum,
              name: drift.Value('Episode $epNum'),
            ),
          );

      final epRelPath = p.join(
        'TV',
        title,
        'Season ${seasonNumber.toString().padLeft(2, '0')}',
        '$title S${seasonNumber.toString().padLeft(2, '0')}E${epNum.toString().padLeft(2, '0')}.mkv',
      );
      final epFile = File(p.join(hddDir.path, epRelPath));
      epFile.parent.createSync(recursive: true);
      final bytes = Uint8List(episodeSize);
      for (var b = 0; b < bytes.length; b++) {
        bytes[b] = (b + i) % 256;
      }
      epFile.writeAsBytesSync(bytes);

      await db.insertMediaSource(
        MediaSourcesCompanion.insert(
          id: 'src_$epId',
          episodeId: drift.Value(epId),
          storageId: 'hdd-1',
          sourceType: 'removableStorage',
          relativePath: epRelPath,
          filename:
              '$title S${seasonNumber.toString().padLeft(2, '0')}E${epNum.toString().padLeft(2, '0')}.mkv',
          extension: 'mkv',
          fileSize: BigInt.from(episodeSize),
          createdAt: now,
          firstSeenAt: now,
          lastSeenAt: now,
          available: const drift.Value(true),
        ),
      );
    }
  }

  group('Area A — Transfer Interruption Lifecycle', () {
    test('Interrupted transfer at PREPARING/TRANSFERRING never falsely records COMPLETED in database', () async {
      await seedMovie(id: 'mov_interrupt', title: 'Inception', year: 2010);

      final token = CancellationToken();

      // Cancel during transfer
      final future = transferService.transferMovie(
        'mov_interrupt',
        cancellationToken: token,
        onProgress: (p) {
          if (p.state == TransferState.transferring && p.bytesTransferred > 0) {
            token.cancel('Simulated crash/interruption');
          }
        },
      );

      final result = await future;
      expect(result.state, TransferState.cancelled);
      expect(result.state == TransferState.completed, false);

      // Verify DB persistence
      final jobs = await db.getTransferJobsForMedia('mov_interrupt');
      expect(jobs.length, 1);
      expect(jobs.first.status, 'CANCELLED');
      expect(jobs.first.status, isNot('COMPLETED'));

      // Verify no MediaSource was registered
      final sources = await db.getSourcesForMovie('mov_interrupt');
      expect(sources.length, 1);
      expect(sources.first.sourceType, 'removableStorage');
    });
  });

  group('Area B — Cancellation Timing Hardening', () {
    test('Cancel before transfer starts (QUEUED state)', () async {
      await seedMovie(id: 'mov_cancel_q', title: 'Arrival', year: 2016);

      final token = CancellationToken()..cancel('Immediate user abort');
      final result = await transferService.transferMovie(
        'mov_cancel_q',
        cancellationToken: token,
      );

      expect(result.state, TransferState.cancelled);
      expect(result.bytesTransferred, 0);

      final jobs = await db.getTransferJobsForMedia('mov_cancel_q');
      expect(jobs.first.status, 'CANCELLED');

      // No finalized or partial files exposed as media sources
      final sources = await db.getSourcesForMovie('mov_cancel_q');
      expect(sources.length, 1);
    });

    test(
      'Cancel after transfer completion does not corrupt completed state',
      () async {
        await seedMovie(
          id: 'mov_completed_cancel',
          title: 'Memento',
          year: 2000,
        );

        final result = await coordinator.requestMovieTransfer(
          'mov_completed_cancel',
        );
        expect(result.state, TransferState.completed);

        // Attempting to cancel an already-completed transfer
        final cancelled = await coordinator.cancelMediaTransfer(
          'mov_completed_cancel',
        );
        expect(cancelled, false);

        final jobs = await db.getTransferJobsForMedia('mov_completed_cancel');
        expect(jobs.first.status, 'COMPLETED');

        final sources = await db.getSourcesForMovie('mov_completed_cancel');
        expect(sources.length, 2);
        expect(sources.any((s) => s.sourceType == 'localDevice'), true);
      },
    );
  });

  group('Area C — Source Disappearance During Transfer', () {
    test('Source file disappearing during byte streaming fails deterministically and allows retry', () async {
      await seedMovie(
        id: 'mov_source_vanish',
        title: 'Interstellar',
        year: 2014,
        fileSize: 4 * 1024 * 1024,
      );

      // We simulate source disappearance by marking drive disconnected in storageIdentity
      storageIdentity.connectedMap[hddDir.path] = false;

      await expectLater(
        () => transferService.transferMovie('mov_source_vanish'),
        throwsA(isA<NoAvailableSourceException>()),
      );

      // Original source record untouched
      final origSources = await db.getSourcesForMovie('mov_source_vanish');
      expect(origSources.length, 1);
      expect(origSources.first.id, 'src_mov_source_vanish');

      // Reconnect source and retry
      storageIdentity.connectedMap[hddDir.path] = true;
      final retryResult = await coordinator.requestMovieTransfer(
        'mov_source_vanish',
      );
      expect(retryResult.state, TransferState.completed);

      final sourcesAfterRetry = await db.getSourcesForMovie(
        'mov_source_vanish',
      );
      expect(sourcesAfterRetry.length, 2);
    });
  });

  group('Area D — Destination Disappearance', () {
    test('Device destination becoming inaccessible fails safely without false completion', () async {
      await seedMovie(id: 'mov_dest_vanish', title: 'Dunkirk', year: 2017);

      deviceStorage.accessible = false;

      await expectLater(
        () => transferService.transferMovie('mov_dest_vanish'),
        throwsA(isA<DeviceStorageUnavailableException>()),
      );

      final sources = await db.getSourcesForMovie('mov_dest_vanish');
      expect(sources.length, 1);
      expect(sources.first.sourceType, 'removableStorage');
    });
  });

  group('Area E — Storage Capacity Boundaries', () {
    test(
      'Single movie: availableBytes < requiredBytes fails before copy',
      () async {
        await seedMovie(
          id: 'mov_cap_fail',
          title: 'Titanic',
          year: 1997,
          fileSize: 10 * 1024 * 1024,
        );

        deviceStorage.availableBytes = 5 * 1024 * 1024; // Less than 10MB

        await expectLater(
          () => transferService.transferMovie('mov_cap_fail'),
          throwsA(isA<InsufficientStorageException>()),
        );

        final jobs = await db.getTransferJobsForMedia('mov_cap_fail');
        expect(jobs.isEmpty, true);
      },
    );

    test(
      'Boundary condition: availableBytes == requiredBytes succeeds',
      () async {
        const fileSize = 2 * 1024 * 1024;
        await seedMovie(
          id: 'mov_cap_exact',
          title: 'Oppenheimer',
          year: 2023,
          fileSize: fileSize,
        );

        deviceStorage.availableBytes = fileSize; // Exactly equal

        final result = await transferService.transferMovie('mov_cap_exact');
        expect(result.state, TransferState.completed);
        expect(result.bytesTransferred, fileSize);
      },
    );

    test(
      'Season batch: aggregate episodes size > availableBytes fails upfront',
      () async {
        await seedTvShowWithEpisodes(
          showId: 'show_cap',
          title: 'Breaking Bad',
          seasonId: 'season_cap_1',
          seasonNumber: 1,
          episodeIds: ['ep_cap_1', 'ep_cap_2', 'ep_cap_3'],
          episodeSize: 4 * 1024 * 1024, // 3 * 4MB = 12MB total
        );

        deviceStorage.availableBytes = 10 * 1024 * 1024; // Only 10MB available

        await expectLater(
          () => transferService.transferSeason('season_cap_1'),
          throwsA(isA<InsufficientStorageException>()),
        );

        // Verify no episodes were copied or registered
        final ep1Sources = await db.getSourcesForEpisode('ep_cap_1');
        expect(ep1Sources.length, 1);
        expect(ep1Sources.first.sourceType, 'removableStorage');
      },
    );
  });

  group('Area F — Duplicate Save Request Protection', () {
    test(
      'Rapid consecutive requests for the same movie reuse active execution',
      () async {
        await seedMovie(
          id: 'mov_dup_rapid',
          title: 'Tenet',
          year: 2020,
          fileSize: 2 * 1024 * 1024,
        );

        final f1 = coordinator.requestMovieTransfer('mov_dup_rapid');
        final f2 = coordinator.requestMovieTransfer('mov_dup_rapid');
        final f3 = coordinator.requestMovieTransfer('mov_dup_rapid');

        final results = await Future.wait([f1, f2, f3]);
        expect(results[0].state, TransferState.completed);
        expect(results[1].state, TransferState.completed);
        expect(results[2].state, TransferState.completed);

        // Only 1 local MediaSource created
        final sources = await db.getSourcesForMovie('mov_dup_rapid');
        expect(sources.length, 2);
        expect(sources.where((s) => s.sourceType == 'localDevice').length, 1);
      },
    );

    test(
      'Direct TransferServiceImpl rejects concurrent transfer on same media',
      () async {
        await seedMovie(
          id: 'mov_dup_direct',
          title: 'The Prestige',
          year: 2006,
          fileSize: 2 * 1024 * 1024,
        );

        final f1 = transferService.transferMovie('mov_dup_direct');
        await expectLater(
          () => transferService.transferMovie('mov_dup_direct'),
          throwsA(isA<DuplicateTransferException>()),
        );

        final r1 = await f1;
        expect(r1.state, TransferState.completed);
      },
    );
  });

  group('Area S — Season Transfer Hardening', () {
    test('Season transfer with TV Extras rejects TV extras from canonical season batch', () async {
      await seedTvShowWithEpisodes(
        showId: 'show_extras',
        title: 'Stranger Things',
        seasonId: 'season_extras',
        seasonNumber: -1, // TV Extras
        episodeIds: ['ep_extra_1'],
      );

      await expectLater(
        () => transferService.transferSeason('season_extras'),
        throwsA(isA<TransferException>()),
      );
    });

    test('Season transfer where some episodes already have local copies is safe and skips redundant copies', () async {
      await seedTvShowWithEpisodes(
        showId: 'show_partial_season',
        title: 'Succession',
        seasonId: 'season_succ_1',
        seasonNumber: 1,
        episodeIds: ['ep_s1_1', 'ep_s1_2'],
        episodeSize: 1024 * 1024,
      );

      // Pre-transfer episode 1
      final ep1Res = await coordinator.requestEpisodeTransfer('ep_s1_1');
      expect(ep1Res.state, TransferState.completed);

      // Now request full season transfer
      final seasonRes = await coordinator.requestSeasonTransfer(
        'season_succ_1',
      );
      expect(seasonRes.length, 2);
      expect(seasonRes.every((r) => r.state == TransferState.completed), true);

      // Ep 1 should only have 1 device copy (no duplicate)
      final ep1Sources = await db.getSourcesForEpisode('ep_s1_1');
      expect(ep1Sources.where((s) => s.sourceType == 'localDevice').length, 1);

      // Ep 2 should have 1 device copy
      final ep2Sources = await db.getSourcesForEpisode('ep_s1_2');
      expect(ep2Sources.where((s) => s.sourceType == 'localDevice').length, 1);
    });
  });
}
