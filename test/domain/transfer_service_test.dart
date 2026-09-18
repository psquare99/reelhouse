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
  late Directory tempRoot;
  late Directory sourceDiskDir;
  late Directory deviceDestDir;
  late AppDatabase db;
  late FakeDeviceStorageService deviceStorageService;
  late FakeStorageIdentityService storageIdentityService;
  late TransferServiceImpl transferService;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'reelhouse_transfer_test_',
    );
    sourceDiskDir = Directory(p.join(tempRoot.path, 'source_hdd'))
      ..createSync(recursive: true);
    deviceDestDir = Directory(p.join(tempRoot.path, 'device_storage'))
      ..createSync(recursive: true);

    db = AppDatabase(NativeDatabase.memory());
    deviceStorageService = FakeDeviceStorageService(
      rootPath: deviceDestDir.path,
    );
    storageIdentityService = FakeStorageIdentityService();

    transferService = TransferServiceImpl(
      database: db,
      deviceStorageService: deviceStorageService,
      storageIdentityService: storageIdentityService,
    );

    // Seed HDD Storage in DB
    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'hdd-1',
            name: 'Movies External HDD',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: '0xHDD1',
            rootUri: sourceDiskDir.path,
            lastSeenAt: DateTime.now(),
            available: const drift.Value(true),
          ),
        );
  });

  tearDown(() async {
    transferService.dispose();
    await db.close();
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  /// Helper to create a test movie with a physical file and database media source.
  Future<void> createTestMovie({
    required String id,
    required String title,
    int? year,
    required String relativePath,
    required List<int> content,
    String storageId = 'hdd-1',
  }) async {
    final fullPath = p.join(sourceDiskDir.path, relativePath);
    final file = File(fullPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(content);

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: id,
            title: drift.Value(title),
            detectedTitle: title,
            year: year != null ? drift.Value(year) : const drift.Value.absent(),
            detectedYear: year != null
                ? drift.Value(year)
                : const drift.Value.absent(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'source_$id',
            movieId: drift.Value(id),
            storageId: storageId,
            sourceType: 'removableStorage',
            relativePath: relativePath,
            filename: p.basename(relativePath),
            extension: p.extension(relativePath).replaceAll('.', ''),
            fileSize: BigInt.from(content.length),
            createdAt: DateTime.now(),
            firstSeenAt: DateTime.now(),
            lastSeenAt: DateTime.now(),
          ),
        );
  }

  /// Helper to create a test TV show, season, and episode.
  Future<void> createTestEpisode({
    required String showId,
    required String showTitle,
    required String seasonId,
    required int seasonNumber,
    required String episodeId,
    required int episodeNumber,
    required String episodeTitle,
    required String relativePath,
    required List<int> content,
    String storageId = 'hdd-1',
  }) async {
    final fullPath = p.join(sourceDiskDir.path, relativePath);
    final file = File(fullPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(content);

    // Upsert show
    final existingShow = await db.findTvShowById(showId);
    if (existingShow == null) {
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: showId,
              title: drift.Value(showTitle),
              detectedTitle: showTitle,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
    }

    // Upsert season
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

    // Upsert episode
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

    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'source_$episodeId',
            episodeId: drift.Value(episodeId),
            storageId: storageId,
            sourceType: 'removableStorage',
            relativePath: relativePath,
            filename: p.basename(relativePath),
            extension: p.extension(relativePath).replaceAll('.', ''),
            fileSize: BigInt.from(content.length),
            createdAt: DateTime.now(),
            firstSeenAt: DateTime.now(),
            lastSeenAt: DateTime.now(),
          ),
        );
  }

  group('M5.2 — Domain Model & Contracts', () {
    test('TransferScope enum parsing and string roundtrip', () {
      expect(TransferScope.fromString('MOVIE'), TransferScope.movie);
      expect(TransferScope.fromString('EPISODE'), TransferScope.episode);
      expect(TransferScope.fromString('SEASON'), TransferScope.season);
      expect(TransferScope.movie.toDbString(), 'MOVIE');
      expect(TransferScope.episode.toDbString(), 'EPISODE');
      expect(TransferScope.season.toDbString(), 'SEASON');
    });

    test('TransferState enum transitions and properties', () {
      expect(TransferState.fromString('QUEUED'), TransferState.queued);
      expect(TransferState.fromString('PREPARING'), TransferState.preparing);
      expect(
        TransferState.fromString('TRANSFERRING'),
        TransferState.transferring,
      );
      expect(
        TransferState.fromString('DOWNLOADING'),
        TransferState.transferring,
      );
      expect(TransferState.fromString('COMPLETED'), TransferState.completed);
      expect(TransferState.fromString('FAILED'), TransferState.failed);
      expect(TransferState.fromString('CANCELLED'), TransferState.cancelled);

      expect(TransferState.queued.isActive, true);
      expect(TransferState.transferring.isActive, true);
      expect(TransferState.completed.isTerminal, true);
      expect(TransferState.failed.isTerminal, true);
      expect(TransferState.cancelled.isTerminal, true);
    });

    test('TransferProgress calculates fraction and percentage correctly', () {
      const progress = TransferProgress(
        transferId: 't1',
        scope: TransferScope.movie,
        mediaId: 'm1',
        state: TransferState.transferring,
        bytesTransferred: 500,
        totalBytes: 1000,
      );

      expect(progress.fraction, 0.5);
      expect(progress.percentage, 50);
      expect(progress.toString(), contains('50%'));
    });

    test('CancellationToken dispatches listener notifications', () {
      final token = CancellationToken();
      var notified = false;

      token.addListener(() {
        notified = true;
      });

      expect(token.isCancelled, false);
      token.cancel('test reason');

      expect(token.isCancelled, true);
      expect(token.reason, 'test reason');
      expect(notified, true);
    });
  });

  group('M5.2 — Source Resolution', () {
    test('selects connected and existing physical source', () async {
      final sampleBytes = Uint8List.fromList(
        List.generate(1024, (i) => i % 256),
      );
      await createTestMovie(
        id: 'movie-interstellar',
        title: 'Interstellar',
        year: 2014,
        relativePath: 'movies/Interstellar (2014)/Interstellar.mkv',
        content: sampleBytes,
      );

      final result = await transferService.transferMovie('movie-interstellar');
      expect(result.state, TransferState.transferring);
      expect(result.bytesTransferred, 1024);
      expect(result.totalBytes, 1024);
    });

    test('rejects disconnected or missing source candidates and falls back to connected one', () async {
      // Create second storage (disconnected)
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'hdd-offline',
              name: 'Disconnected HDD',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: '0xOFFLINE',
              rootUri: 'Z:\\MissingDrive',
              lastSeenAt: DateTime.now(),
              available: const drift.Value(false),
            ),
          );

      storageIdentityService.connectedMap['Z:\\MissingDrive'] = false;

      final sampleBytes = Uint8List.fromList(
        List.generate(512, (i) => i % 256),
      );
      await createTestMovie(
        id: 'movie-matrix',
        title: 'The Matrix',
        year: 1999,
        relativePath: 'movies/The Matrix (1999)/matrix.mkv',
        content: sampleBytes,
        storageId: 'hdd-1',
      );

      // Add a non-working source on offline drive
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'source_matrix_offline',
              movieId: const drift.Value('movie-matrix'),
              storageId: 'hdd-offline',
              sourceType: 'removableStorage',
              relativePath: 'movies/The Matrix (1999)/matrix.mkv',
              filename: 'matrix.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(512),
              createdAt: DateTime.now(),
              firstSeenAt: DateTime.now(),
              lastSeenAt: DateTime.now(),
              available: const drift.Value(false),
            ),
          );

      final result = await transferService.transferMovie('movie-matrix');
      expect(result.state, TransferState.transferring);
      expect(result.bytesTransferred, 512);
    });

    test(
      'throws NoAvailableSourceException when no connected source exists',
      () async {
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'movie-ghost',
                detectedTitle: 'Ghost Film',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        expect(
          () => transferService.transferMovie('movie-ghost'),
          throwsA(isA<NoAvailableSourceException>()),
        );
      },
    );
  });

  group('M5.2 — Destination Resolution & Path Safety', () {
    test(
      'generates deterministic destination path within device storage root',
      () async {
        final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        await createTestMovie(
          id: 'movie-avatar',
          title: 'Avatar',
          year: 2009,
          relativePath: 'Avatar.mkv',
          content: sampleBytes,
        );

        final result = await transferService.transferMovie('movie-avatar');

        final expectedDest = p.normalize(
          p.join(deviceDestDir.path, 'movies', 'Avatar (2009)', 'Avatar.mkv'),
        );
        final expectedTemp = '$expectedDest.reelhouse-partial';

        expect(result.destinationPath, expectedDest);
        expect(result.temporaryPath, expectedTemp);

        // Verify temporary file exists on disk with exact bytes
        final tempFile = File(expectedTemp);
        expect(tempFile.existsSync(), true);
        expect(tempFile.lengthSync(), 5);
        expect(tempFile.readAsBytesSync(), sampleBytes);
      },
    );

    test(
      'handles inaccessible device storage destination with clear failure',
      () async {
        deviceStorageService.accessible = false;

        final sampleBytes = Uint8List.fromList([1, 2, 3]);
        await createTestMovie(
          id: 'movie-dune',
          title: 'Dune',
          year: 2021,
          relativePath: 'Dune.mkv',
          content: sampleBytes,
        );

        expect(
          () => transferService.transferMovie('movie-dune'),
          throwsA(isA<DeviceStorageUnavailableException>()),
        );
      },
    );
  });

  group('M5.2 — Capacity Pre-check', () {
    test(
      'fails before copying when destination has insufficient space',
      () async {
        deviceStorageService.availableBytes = 100; // only 100 bytes free

        final sampleBytes = Uint8List.fromList(
          List.generate(1000, (i) => i % 256),
        ); // 1000 bytes file
        await createTestMovie(
          id: 'movie-oppenheimer',
          title: 'Oppenheimer',
          year: 2023,
          relativePath: 'Oppenheimer.mkv',
          content: sampleBytes,
        );

        expect(
          () => transferService.transferMovie('movie-oppenheimer'),
          throwsA(isA<InsufficientStorageException>()),
        );

        // Verify no temporary file was created
        final files = deviceDestDir.listSync(recursive: true);
        expect(files, isEmpty);
      },
    );
  });

  group('M5.2 — Real Byte Copying & Invariants', () {
    test(
      'performs accurate chunked streaming copy without modifying source file',
      () async {
        // 5MB payload to test chunked streaming
        final dataSize = 5 * 1024 * 1024;
        final sampleBytes = Uint8List(dataSize);
        for (var i = 0; i < dataSize; i++) {
          sampleBytes[i] = (i ^ 0x5A) % 256;
        }

        await createTestMovie(
          id: 'movie-gladiator',
          title: 'Gladiator',
          year: 2000,
          relativePath: 'Gladiator.mkv',
          content: sampleBytes,
        );

        final progressEvents = <TransferProgress>[];
        final result = await transferService.transferMovie(
          'movie-gladiator',
          onProgress: (p) => progressEvents.add(p),
        );

        expect(result.state, TransferState.transferring);
        expect(result.bytesTransferred, dataSize);

        // Verify source file remains untouched
        final sourceFile = File(p.join(sourceDiskDir.path, 'Gladiator.mkv'));
        expect(sourceFile.existsSync(), true);
        expect(sourceFile.lengthSync(), dataSize);
        expect(sourceFile.readAsBytesSync(), sampleBytes);

        // Verify temporary file on destination
        final tempFile = File(result.temporaryPath!);
        expect(tempFile.existsSync(), true);
        expect(tempFile.lengthSync(), dataSize);
        expect(tempFile.readAsBytesSync(), sampleBytes);

        // Verify progress events were emitted
        expect(progressEvents, isNotEmpty);
        expect(progressEvents.first.state, TransferState.queued);
        expect(
          progressEvents.any((e) => e.state == TransferState.preparing),
          true,
        );
        expect(progressEvents.last.bytesTransferred, dataSize);
      },
    );
  });

  group('M5.2 — Cooperative Cancellation', () {
    test(
      'cancellation token halts copying and persists CANCELLED state',
      () async {
        // 10MB payload
        final dataSize = 10 * 1024 * 1024;
        final sampleBytes = Uint8List(dataSize);

        await createTestMovie(
          id: 'movie-titanic',
          title: 'Titanic',
          year: 1997,
          relativePath: 'Titanic.mkv',
          content: sampleBytes,
        );

        final token = CancellationToken();
        final progressList = <TransferProgress>[];

        // Cancel after first chunk progress
        final transferFuture = transferService.transferMovie(
          'movie-titanic',
          cancellationToken: token,
          onProgress: (p) {
            progressList.add(p);
            if (p.bytesTransferred > 0) {
              token.cancel('User clicked cancel');
            }
          },
        );

        final result = await transferFuture;

        expect(result.isCancelled, true);
        expect(result.state, TransferState.cancelled);

        // Verify database record
        final jobs = await db.getTransferJobsForMedia('movie-titanic');
        expect(jobs, isNotEmpty);
        expect(jobs.first.status, 'CANCELLED');

        // Verify active transfer was cleared
        expect(transferService.isMediaTransferring('movie-titanic'), false);
      },
    );
  });

  group('M5.2 — Duplicate Transfer Protection', () {
    test('concurrent transfer on same media item throws DuplicateTransferException', () async {
      final sampleBytes = Uint8List(2 * 1024 * 1024);
      await createTestMovie(
        id: 'movie-alien',
        title: 'Alien',
        year: 1979,
        relativePath: 'Alien.mkv',
        content: sampleBytes,
      );

      final firstFuture = transferService.transferMovie('movie-alien');

      // Immediate second attempt while first is in flight
      expect(
        () => transferService.transferMovie('movie-alien'),
        throwsA(isA<DuplicateTransferException>()),
      );

      await firstFuture;
    });
  });

  group('M5.2 — TV Episode & Season Transfers', () {
    test('transfers individual episode to structured tv_shows path', () async {
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

      final result = await transferService.transferEpisode('ep-bb-101');

      expect(result.state, TransferState.transferring);
      expect(result.bytesTransferred, 4);

      final expectedDest = p.normalize(
        p.join(
          deviceDestDir.path,
          'tv_shows',
          'Breaking Bad',
          'Season 01',
          'S01E01.mkv',
        ),
      );
      expect(result.destinationPath, expectedDest);
      expect(File('$expectedDest.reelhouse-partial').existsSync(), true);
    });

    test(
      'transfers canonical season batch and calculates aggregate size upfront',
      () async {
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

        final batchProgress = <TransferProgress>[];
        final results = await transferService.transferSeason(
          'season-got-1',
          onProgress: (p) => batchProgress.add(p),
        );

        expect(results.length, 2);
        expect(results[0].bytesTransferred, 3);
        expect(results[1].bytesTransferred, 4);

        // Verify batch items received progress
        expect(
          batchProgress.any(
            (p) => p.totalItems == 2 && p.currentItemIndex == 1,
          ),
          true,
        );
        expect(
          batchProgress.any(
            (p) => p.totalItems == 2 && p.currentItemIndex == 2,
          ),
          true,
        );
        expect(batchProgress.last.totalBytes, 7);
      },
    );

    test('excludes TV extras (Season -1) from season batch transfer', () async {
      final extraBytes = Uint8List.fromList([1, 2]);
      await createTestEpisode(
        showId: 'show-bcs',
        showTitle: 'Better Call Saul',
        seasonId: 'season-bcs-extras',
        seasonNumber: -1,
        episodeId: 'ep-bcs-extra1',
        episodeNumber: 1,
        episodeTitle: 'Behind the Scenes',
        relativePath: 'BCS/Extras/Featurette.mkv',
        content: extraBytes,
      );

      expect(
        () => transferService.transferSeason('season-bcs-extras'),
        throwsA(isA<TransferException>()),
      );
    });
  });

  group('M5.2 — SQLite Persistence & State Recovery', () {
    test('transfer job record is persisted in SQLite database', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);
      await createTestMovie(
        id: 'movie-jaws',
        title: 'Jaws',
        year: 1975,
        relativePath: 'Jaws.mkv',
        content: sampleBytes,
      );

      final result = await transferService.transferMovie('movie-jaws');

      final job = await db.getTransferJobById(result.transferId);
      expect(job, isNotNull);
      expect(job!.mediaId, 'movie-jaws');
      expect(job.mediaType, 'movie');
      expect(job.status, 'TRANSFERRING');
      expect(job.bytesTransferred, BigInt.from(4));
      expect(job.totalBytes, BigInt.from(4));
      expect(job.destinationRelativePath, contains('Jaws'));
    });
  });
}
