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
import 'package:reelhouse/domain/services/availability_resolver.dart';
import 'package:reelhouse/domain/services/device_storage_service.dart';
import 'package:reelhouse/domain/services/playback_source_resolver.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';

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
  final Map<String, bool> connectedMap = {};

  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async => 'fs-id';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async => 'Storage';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async {
    return connectedMap[p.normalize(rootUriOrPath)] ?? true;
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
  late Directory tempRootDir;
  late Directory sourceDiskDir;
  late Directory deviceDestDir;
  late FakeDeviceStorageService deviceStorageService;
  late FakeStorageIdentityService storageIdentityService;
  late TransferServiceImpl transferService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    tempRootDir = await Directory.systemTemp.createTemp('reelhouse_m54_test_');
    sourceDiskDir = Directory(p.join(tempRootDir.path, 'source_hdd'))
      ..createSync(recursive: true);
    deviceDestDir = Directory(p.join(tempRootDir.path, 'device_storage'))
      ..createSync(recursive: true);

    deviceStorageService = FakeDeviceStorageService(
      rootPath: deviceDestDir.path,
    );
    storageIdentityService = FakeStorageIdentityService();
    storageIdentityService.connectedMap[p.normalize(sourceDiskDir.path)] = true;

    // Register external HDD and internal device storage in DB
    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'storage-source-hdd',
            name: 'Movies External HDD',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: '0xHDD1',
            rootUri: sourceDiskDir.path,
            lastSeenAt: DateTime.now(),
            available: const drift.Value(true),
          ),
        );

    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'device-storage-internal',
            name: 'This Device',
            storageType: 'LOCAL_APPLICATION',
            filesystemIdentifier: 'internal-app-storage',
            rootUri: deviceDestDir.path,
            lastSeenAt: DateTime.now(),
            available: const drift.Value(true),
          ),
        );

    transferService = TransferServiceImpl(
      database: db,
      deviceStorageService: deviceStorageService,
      storageIdentityService: storageIdentityService,
    );
  });

  tearDown(() async {
    transferService.dispose();
    await db.close();
    if (tempRootDir.existsSync()) {
      try {
        tempRootDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  Future<void> createTestMovie({
    required String id,
    required String title,
    int? year,
    required String relativePath,
    required Uint8List content,
    String watchState = 'IN_PROGRESS',
    int playbackPosition = 1200,
  }) async {
    final now = DateTime.now();
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: id,
            title: drift.Value(title),
            year: year != null ? drift.Value(year) : const drift.Value.absent(),
            detectedTitle: title,
            detectedYear: year != null
                ? drift.Value(year)
                : const drift.Value.absent(),
            watchState: drift.Value(watchState),
            playbackPositionSeconds: drift.Value(playbackPosition),
            lastPlayedAt: drift.Value(now),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final physicalFile = File(p.join(sourceDiskDir.path, relativePath));
    physicalFile.parent.createSync(recursive: true);
    physicalFile.writeAsBytesSync(content);

    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'src-hdd-$id',
            movieId: drift.Value(id),
            storageId: 'storage-source-hdd',
            sourceType: 'removableStorage',
            relativePath: relativePath,
            filename: p.basename(relativePath),
            extension: p.extension(relativePath).replaceAll('.', ''),
            fileSize: BigInt.from(content.length),
            videoCodec: const drift.Value('H264'),
            audioCodec: const drift.Value('AAC'),
            resolution: const drift.Value('1080p'),
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );
  }

  Future<void> createTestEpisode({
    required String showId,
    required String showTitle,
    required String seasonId,
    required int seasonNumber,
    required String episodeId,
    required int episodeNumber,
    required String episodeTitle,
    required String relativePath,
    required Uint8List content,
  }) async {
    final now = DateTime.now();

    final existingShow = await db.findTvShowById(showId);
    if (existingShow == null) {
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: showId,
              title: drift.Value(showTitle),
              detectedTitle: showTitle,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    final existingSeason = await db.findSeasonById(seasonId);
    if (existingSeason == null) {
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: seasonId,
              showId: showId,
              seasonNumber: seasonNumber,
              name: drift.Value(
                seasonNumber < 0 ? 'Extras' : 'Season $seasonNumber',
              ),
            ),
          );
    }

    await db
        .into(db.episodes)
        .insert(
          EpisodesCompanion.insert(
            id: episodeId,
            seasonId: seasonId,
            episodeNumber: episodeNumber,
            name: drift.Value(episodeTitle),
          ),
        );

    final physicalFile = File(p.join(sourceDiskDir.path, relativePath));
    physicalFile.parent.createSync(recursive: true);
    physicalFile.writeAsBytesSync(content);

    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'src-hdd-$episodeId',
            episodeId: drift.Value(episodeId),
            storageId: 'storage-source-hdd',
            sourceType: 'removableStorage',
            relativePath: relativePath,
            filename: p.basename(relativePath),
            extension: p.extension(relativePath).replaceAll('.', ''),
            fileSize: BigInt.from(content.length),
            videoCodec: const drift.Value('HEVC'),
            audioCodec: const drift.Value('EAC3'),
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );
  }

  group('M5.4 — Movie MediaSource Registration', () {
    test('completed movie transfer registers one localDevice MediaSource on the existing logical movie', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      await createTestMovie(
        id: 'movie-interstellar',
        title: 'Interstellar',
        year: 2014,
        relativePath: 'Interstellar (2014).mkv',
        content: sampleBytes,
        watchState: 'IN_PROGRESS',
        playbackPosition: 3600,
      );

      // 1. Perform M5.3 transfer (Transfer -> Verify -> Finalize -> COMPLETED)
      final transferResult = await transferService.transferMovie(
        'movie-interstellar',
      );
      expect(transferResult.state, TransferState.completed);

      // Verify that before M5.4 registration, exactly 1 MediaSource exists (HDD)
      final sourcesBefore = await db.getSourcesForMovie('movie-interstellar');
      expect(sourcesBefore.length, 1);

      // 2. Perform M5.4 registration
      final registeredSource = await transferService.registerCompletedTransfer(
        transferResult.transferId,
      );

      expect(registeredSource, isNotNull);
      expect(registeredSource.movieId, 'movie-interstellar');
      expect(registeredSource.storageId, 'device-storage-internal');
      expect(registeredSource.sourceType, 'localDevice');
      expect(registeredSource.available, true);
      expect(registeredSource.fileSize, BigInt.from(5));
      expect(registeredSource.videoCodec, 'H264');
      expect(registeredSource.audioCodec, 'AAC');
      expect(registeredSource.resolution, '1080p');

      // Verify total MediaSources for movie: exactly 2 (HDD + Device)
      final sourcesAfter = await db.getSourcesForMovie('movie-interstellar');
      expect(sourcesAfter.length, 2);
      expect(sourcesAfter.any((s) => s.sourceType == 'removableStorage'), true);
      expect(sourcesAfter.any((s) => s.sourceType == 'localDevice'), true);

      // Verify logical movie count is still 1 (no duplicate movie created)
      final totalMovies = await db.select(db.movies).get();
      expect(totalMovies.length, 1);

      // Verify watch state and playback history remain completely untouched
      final movie = await db.findMovieById('movie-interstellar');
      expect(movie!.watchState, 'IN_PROGRESS');
      expect(movie.playbackPositionSeconds, 3600);
    });
  });

  group('M5.4 — TV Episode & Season Registration', () {
    test('completed episode transfer registers localDevice MediaSource on existing episode', () async {
      final sampleBytes = Uint8List.fromList([10, 20, 30, 40]);
      await createTestEpisode(
        showId: 'show-bb',
        showTitle: 'Breaking Bad',
        seasonId: 'season-bb-1',
        seasonNumber: 1,
        episodeId: 'ep-bb-101',
        episodeNumber: 1,
        episodeTitle: 'Pilot',
        relativePath: 'Breaking Bad/Season 01/S01E01.mkv',
        content: sampleBytes,
      );

      final transferResult = await transferService.transferEpisode('ep-bb-101');
      expect(transferResult.state, TransferState.completed);

      final registeredSource = await transferService.registerCompletedTransfer(
        transferResult.transferId,
      );

      expect(registeredSource.episodeId, 'ep-bb-101');
      expect(registeredSource.storageId, 'device-storage-internal');
      expect(registeredSource.sourceType, 'localDevice');
      expect(registeredSource.available, true);

      final sources = await db.getSourcesForEpisode('ep-bb-101');
      expect(sources.length, 2);

      // Logical counts must remain unchanged
      expect((await db.select(db.tvShows).get()).length, 1);
      expect((await db.select(db.seasons).get()).length, 1);
      expect((await db.select(db.episodes).get()).length, 1);
    });

    test('registerCompletedSeasonTransfers registers distinct MediaSources for each canonical episode', () async {
      final ep1Bytes = Uint8List.fromList([1, 2, 3]);
      final ep2Bytes = Uint8List.fromList([4, 5, 6, 7]);

      await createTestEpisode(
        showId: 'show-got',
        showTitle: 'Game of Thrones',
        seasonId: 'season-got-1',
        seasonNumber: 1,
        episodeId: 'ep-got-101',
        episodeNumber: 1,
        episodeTitle: 'Winter Is Coming',
        relativePath: 'GOT/S01E01.mkv',
        content: ep1Bytes,
      );

      await createTestEpisode(
        showId: 'show-got',
        showTitle: 'Game of Thrones',
        seasonId: 'season-got-1',
        seasonNumber: 1,
        episodeId: 'ep-got-102',
        episodeNumber: 2,
        episodeTitle: 'The Kingsroad',
        relativePath: 'GOT/S01E02.mkv',
        content: ep2Bytes,
      );

      // Transfer whole season
      final results = await transferService.transferSeason('season-got-1');
      expect(results.length, 2);
      expect(results.every((r) => r.state == TransferState.completed), true);

      // Batch register season transfers
      final registeredSources = await transferService
          .registerCompletedSeasonTransfers('season-got-1');

      expect(registeredSources.length, 2);
      expect(registeredSources[0].episodeId, 'ep-got-101');
      expect(registeredSources[1].episodeId, 'ep-got-102');

      expect((await db.getSourcesForEpisode('ep-got-101')).length, 2);
      expect((await db.getSourcesForEpisode('ep-got-102')).length, 2);
    });
  });

  group('M5.4 — Registration Invariants & Security Boundaries', () {
    test(
      'registration strictly rejects non-COMPLETED transfer states',
      () async {
        final destRel = p.join('movies', 'Memento (2000)', 'Memento.mkv');
        final destPath = p.normalize(p.join(deviceDestDir.path, destRel));
        File(destPath)
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync([1, 2, 3]);

        for (final nonCompletedStatus in [
          'QUEUED',
          'PREPARING',
          'TRANSFERRING',
          'VERIFYING',
          'FAILED',
          'CANCELLED',
        ]) {
          final transferId = 'job-$nonCompletedStatus';
          await db.upsertTransferJob(
            TransferJobsCompanion.insert(
              id: transferId,
              mediaType: 'movie',
              mediaId: 'movie-memento',
              sourceMediaSourceId: 'src-memento',
              destinationStorageId: 'device-storage-internal',
              destinationRelativePath: destRel,
              status: nonCompletedStatus,
              totalBytes: BigInt.from(3),
              bytesTransferred: drift.Value(BigInt.from(3)),
              startedAt: DateTime.now(),
            ),
          );

          expect(
            () => transferService.registerCompletedTransfer(transferId),
            throwsA(
              isA<TransferException>().having(
                (e) => e.message,
                'message',
                contains('not COMPLETED'),
              ),
            ),
          );
        }
      },
    );

    test(
      'partial .reelhouse-partial path cannot be registered as a MediaSource',
      () async {
        final partialRel = p.join(
          'movies',
          'Dune (2021)',
          'Dune.mkv.reelhouse-partial',
        );
        final partialPath = p.normalize(p.join(deviceDestDir.path, partialRel));
        File(partialPath)
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync([1, 2, 3]);

        await db.upsertTransferJob(
          TransferJobsCompanion.insert(
            id: 'job-partial-dest',
            mediaType: 'movie',
            mediaId: 'movie-dune',
            sourceMediaSourceId: 'src-dune',
            destinationStorageId: 'device-storage-internal',
            destinationRelativePath: partialRel,
            status: 'COMPLETED',
            totalBytes: BigInt.from(3),
            bytesTransferred: drift.Value(BigInt.from(3)),
            startedAt: DateTime.now(),
          ),
        );

        expect(
          () => transferService.registerCompletedTransfer('job-partial-dest'),
          throwsA(
            isA<TransferException>().having(
              (e) => e.message,
              'message',
              contains('temporary partial artifact'),
            ),
          ),
        );
      },
    );

    test('completed job fails registration safely if final destination file is missing on disk', () async {
      await createTestMovie(
        id: 'movie-ghost',
        title: 'Ghost Film',
        year: 1990,
        relativePath: 'Ghost.mkv',
        content: Uint8List.fromList([1, 2, 3]),
      );

      final destRel = p.join('movies', 'Ghost Film (1990)', 'Ghost.mkv');
      // Do NOT create the destination file on disk

      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-missing-dest-file',
          mediaType: 'movie',
          mediaId: 'movie-ghost',
          sourceMediaSourceId: 'src-hdd-movie-ghost',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'COMPLETED',
          totalBytes: BigInt.from(3),
          bytesTransferred: drift.Value(BigInt.from(3)),
          startedAt: DateTime.now(),
        ),
      );

      expect(
        () =>
            transferService.registerCompletedTransfer('job-missing-dest-file'),
        throwsA(
          isA<TransferException>().having(
            (e) => e.message,
            'message',
            contains('does not exist'),
          ),
        ),
      );
    });
  });

  group('M5.4 — Registration Idempotency & Collision Protection', () {
    test(
      'registerCompletedTransfer is idempotent when called multiple times',
      () async {
        final sampleBytes = Uint8List.fromList([10, 20, 30]);
        await createTestMovie(
          id: 'movie-avatar',
          title: 'Avatar',
          year: 2009,
          relativePath: 'Avatar.mkv',
          content: sampleBytes,
        );

        final transferResult = await transferService.transferMovie(
          'movie-avatar',
        );

        // First registration
        final source1 = await transferService.registerCompletedTransfer(
          transferResult.transferId,
        );

        // Second registration
        final source2 = await transferService.registerCompletedTransfer(
          transferResult.transferId,
        );

        expect(source1.id, source2.id);

        // Total sources for Avatar: exactly 2 (HDD + 1 Local)
        final sources = await db.getSourcesForMovie('movie-avatar');
        expect(sources.length, 2);
      },
    );

    test('throws TransferException on path collision attached to different media ID', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);
      await createTestMovie(
        id: 'movie-alien-1',
        title: 'Alien',
        year: 1979,
        relativePath: 'Alien.mkv',
        content: sampleBytes,
      );

      await createTestMovie(
        id: 'movie-alien-2',
        title: 'Aliens',
        year: 1986,
        relativePath: 'Aliens.mkv',
        content: sampleBytes,
      );

      final destRel = p.join('movies', 'Alien (1979)', 'Alien.mkv');
      final destPath = p.normalize(p.join(deviceDestDir.path, destRel));
      File(destPath)
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(sampleBytes);

      // Register for movie-alien-1 first
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-alien-1-local',
              movieId: const drift.Value('movie-alien-1'),
              storageId: 'device-storage-internal',
              sourceType: 'localDevice',
              relativePath: destRel,
              filename: 'Alien.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(4),
              createdAt: DateTime.now(),
              firstSeenAt: DateTime.now(),
              lastSeenAt: DateTime.now(),
            ),
          );

      // Create completed transfer job for movie-alien-2 with the same physical destination
      await db.upsertTransferJob(
        TransferJobsCompanion.insert(
          id: 'job-alien-collision',
          mediaType: 'movie',
          mediaId: 'movie-alien-2',
          sourceMediaSourceId: 'src-hdd-movie-alien-2',
          destinationStorageId: 'device-storage-internal',
          destinationRelativePath: destRel,
          status: 'COMPLETED',
          totalBytes: BigInt.from(4),
          bytesTransferred: drift.Value(BigInt.from(4)),
          startedAt: DateTime.now(),
        ),
      );

      expect(
        () => transferService.registerCompletedTransfer('job-alien-collision'),
        throwsA(
          isA<TransferException>().having(
            (e) => e.message,
            'message',
            contains('MediaSource collision'),
          ),
        ),
      );
    });
  });

  group('M5.4 — Availability & Playback Resolution Integration', () {
    test('AvailabilityResolver & PlaybackSourceResolver integrate offline local copy', () async {
      final sampleBytes = Uint8List.fromList([100, 200]);
      await createTestMovie(
        id: 'movie-oppenheimer',
        title: 'Oppenheimer',
        year: 2023,
        relativePath: 'Oppenheimer (2023).mkv',
        content: sampleBytes,
      );

      final transferResult = await transferService.transferMovie(
        'movie-oppenheimer',
      );
      final localSource = await transferService.registerCompletedTransfer(
        transferResult.transferId,
      );

      const availabilityResolver = AvailabilityResolver();
      const playbackResolver = PlaybackSourceResolver();

      // 1. HDD Connected + Local Device Present
      final checkSourcesBothConnected = [
        SourceCheckInfo(
          sourceId: 'src-hdd-movie-oppenheimer',
          sourceType: 'removableStorage',
          isSourceAvailable: true,
          storageId: 'storage-source-hdd',
          storageName: 'Movies External HDD',
          isStorageConnected: true,
        ),
        SourceCheckInfo(
          sourceId: localSource.id,
          sourceType: 'localDevice',
          isSourceAvailable: true,
          storageId: 'device-storage-internal',
          storageName: 'This Device',
          isStorageConnected: true,
        ),
      ];

      final availBoth = availabilityResolver.resolve(checkSourcesBothConnected);
      expect(availBoth, AvailabilityStatus.availableOnMultipleSources);

      final playBoth = playbackResolver.resolve(checkSourcesBothConnected);
      expect(playBoth.action, PlaybackAction.playOffline);
      expect(playBoth.selectedSourceId, localSource.id);

      // 2. HDD Disconnected + Local Device Present
      final checkSourcesHddDisconnected = [
        SourceCheckInfo(
          sourceId: 'src-hdd-movie-oppenheimer',
          sourceType: 'removableStorage',
          isSourceAvailable: false,
          storageId: 'storage-source-hdd',
          storageName: 'Movies External HDD',
          isStorageConnected: false, // HDD disconnected!
        ),
        SourceCheckInfo(
          sourceId: localSource.id,
          sourceType: 'localDevice',
          isSourceAvailable: true,
          storageId: 'device-storage-internal',
          storageName: 'This Device',
          isStorageConnected: true,
        ),
      ];

      final availHddOffline = availabilityResolver.resolve(
        checkSourcesHddDisconnected,
      );
      expect(availHddOffline, AvailabilityStatus.availableLocally);

      final playHddOffline = playbackResolver.resolve(
        checkSourcesHddDisconnected,
      );
      expect(playHddOffline.action, PlaybackAction.playOffline);
      expect(playHddOffline.selectedSourceId, localSource.id);

      // 3. Device Storage Inaccessible -> MediaSource remains registered but unavailable
      final checkSourcesDeviceInaccessible = [
        SourceCheckInfo(
          sourceId: 'src-hdd-movie-oppenheimer',
          sourceType: 'removableStorage',
          isSourceAvailable: false,
          storageId: 'storage-source-hdd',
          storageName: 'Movies External HDD',
          isStorageConnected: false,
        ),
        SourceCheckInfo(
          sourceId: localSource.id,
          sourceType: 'localDevice',
          isSourceAvailable: false, // Inaccessible device copy
          storageId: 'device-storage-internal',
          storageName: 'This Device',
          isStorageConnected: true,
        ),
      ];

      final availNone = availabilityResolver.resolve(
        checkSourcesDeviceInaccessible,
      );
      expect(availNone, AvailabilityStatus.unavailable);

      final playNone = playbackResolver.resolve(checkSourcesDeviceInaccessible);
      expect(playNone.action, PlaybackAction.connectDisk);
    });
  });
}
