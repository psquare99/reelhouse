import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/data/services/transfer_service_impl.dart';
import 'package:reelhouse/domain/models/availability_status.dart';
import 'package:reelhouse/domain/models/device_storage_destination.dart';
import 'package:reelhouse/domain/models/transfer_models.dart';
import 'package:reelhouse/domain/query/library_result.dart';
import 'package:reelhouse/domain/query/movie_query.dart';
import 'package:reelhouse/domain/query/season_query.dart';
import 'package:reelhouse/domain/query/tv_show_query.dart';
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
  late DriftLibraryRepository repo;
  late FakeDeviceStorageService deviceStorageService;
  late FakeStorageIdentityService storageIdentityService;
  late TransferServiceImpl transferService;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp(
      'reelhouse_m5_offline_state_',
    );
    sourceDiskDir = Directory(p.join(tempRoot.path, 'source_hdd'))
      ..createSync(recursive: true);
    deviceDestDir = Directory(p.join(tempRoot.path, 'device_storage'))
      ..createSync(recursive: true);

    db = AppDatabase(NativeDatabase.memory());
    repo = DriftLibraryRepository(db);
    deviceStorageService = FakeDeviceStorageService(
      rootPath: deviceDestDir.path,
    );
    storageIdentityService = FakeStorageIdentityService();

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
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  Future<void> createTestMovie({
    required String id,
    required String title,
    required String relativePath,
    required Uint8List content,
  }) async {
    final now = DateTime.now();
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: id,
            title: drift.Value(title),
            detectedTitle: title,
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
              name: drift.Value('Season $seasonNumber'),
            ),
          );
    }

    final existingEpisode = await db.findEpisodeById(episodeId);
    if (existingEpisode == null) {
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
    }

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
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );
  }

  /// Collects stream events until [predicate] matches, then returns the page.
  Future<LibraryResult<T>> watchUntil<T>(
    Stream<LibraryResult<T>> stream,
    bool Function(LibraryResult<T> result) predicate,
  ) async {
    final controller = Completer<LibraryResult<T>>();
    late final StreamSubscription<LibraryResult<T>> sub;
    sub = stream.listen((result) {
      if (predicate(result)) {
        controller.complete(result);
        sub.cancel();
      }
    }, onError: controller.completeError);
    return controller.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () =>
          throw TimeoutException('Stream did not reach expected state'),
    );
  }

  group('M5 Bug 1: transfer progress is a 0-100 percentage', () {
    test('movie transfer emits percentages strictly within 0-100', () async {
      await createTestMovie(
        id: 'movie-progress',
        title: 'Progress Movie',
        relativePath: 'Movies/Progress (2026)/Progress.mkv',
        content: Uint8List.fromList(List<int>.filled(4 * 1024 * 1024, 7)),
      );

      final percentages = <int>[];
      final result = await transferService.transferMovie(
        'movie-progress',
        onProgress: (progress) => percentages.add(progress.percentage),
      );
      await transferService.registerCompletedTransfer(result.transferId);

      expect(result.state, TransferState.completed);
      expect(percentages, isNotEmpty);
      for (final pct in percentages) {
        expect(
          pct,
          inInclusiveRange(0, 100),
          reason: 'progress percentage must never exceed 100',
        );
      }
      expect(percentages.last, equals(100));
    });

    test('season transfer emits percentages strictly within 0-100', () async {
      final content = Uint8List.fromList(List<int>.filled(2 * 1024 * 1024, 7));
      await createTestEpisode(
        showId: 'show-progress',
        showTitle: 'Progress Show',
        seasonId: 'season-progress-1',
        seasonNumber: 1,
        episodeId: 'ep-progress-1',
        episodeNumber: 1,
        episodeTitle: 'Chapter One',
        relativePath: 'TV/Progress/Season 1/Progress S01E01.mkv',
        content: content,
      );
      await createTestEpisode(
        showId: 'show-progress',
        showTitle: 'Progress Show',
        seasonId: 'season-progress-1',
        seasonNumber: 1,
        episodeId: 'ep-progress-2',
        episodeNumber: 2,
        episodeTitle: 'Chapter Two',
        relativePath: 'TV/Progress/Season 1/Progress S01E02.mkv',
        content: content,
      );

      final percentages = <int>[];
      final results = await transferService.transferSeason(
        'season-progress-1',
        onProgress: (progress) => percentages.add(progress.percentage),
      );
      await transferService.registerCompletedSeasonTransfers(
        'season-progress-1',
      );

      expect(results, hasLength(2));
      expect(percentages, isNotEmpty);
      for (final pct in percentages) {
        expect(
          pct,
          inInclusiveRange(0, 100),
          reason: 'season batch percentage must never exceed 100',
        );
      }
    });

    test(
      'TransferProgress.fraction is clamped so percentage never exceeds 100',
      () {
        const overTotal = TransferProgress(
          transferId: 'over',
          scope: TransferScope.movie,
          mediaId: 'm',
          state: TransferState.transferring,
          bytesTransferred: 150,
          totalBytes: 100,
        );
        expect(overTotal.fraction, equals(1.0));
        expect(overTotal.percentage, equals(100));
      },
    );
  });

  group('M5 Bug 3: Offline Library only shows offline media', () {
    test(
      'external-only, unavailable, and pending device copies are excluded',
      () async {
        await createTestMovie(
          id: 'movie-external',
          title: 'External Only',
          relativePath: 'Movies/External (2020)/External.mkv',
          content: Uint8List.fromList([1, 2, 3]),
        );
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'movie-unavailable-device',
                title: const drift.Value('Unavailable Device'),
                detectedTitle: 'Unavailable Device',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
        await db
            .into(db.mediaSources)
            .insert(
              MediaSourcesCompanion.insert(
                id: 'src-device-unavailable',
                movieId: const drift.Value('movie-unavailable-device'),
                storageId: 'device-storage-internal',
                sourceType: 'localDevice',
                relativePath: 'Movies/Unavailable/Unavailable.mkv',
                filename: 'Unavailable.mkv',
                extension: 'mkv',
                fileSize: BigInt.from(4),
                createdAt: DateTime.now(),
                firstSeenAt: DateTime.now(),
                lastSeenAt: DateTime.now(),
                available: const drift.Value(false),
              ),
            );

        final offline = await repo.watchMovies(MovieQuery.offline()).first;
        expect(offline.items, isEmpty);
      },
    );

    test('completed device copy appears once a source row is registered', () async {
      await createTestMovie(
        id: 'movie-offline',
        title: 'Offline Movie',
        relativePath: 'Movies/Offline (2021)/Offline.mkv',
        content: Uint8List.fromList(List<int>.filled(256 * 1024, 5)),
      );

      final before = await repo.watchMovies(MovieQuery.offline()).first;
      expect(before.items, isEmpty);

      final result = await transferService.transferMovie('movie-offline');
      await transferService.registerCompletedTransfer(result.transferId);

      final offline = await repo.watchMovies(MovieQuery.offline()).first;
      expect(offline.items, hasLength(1));
      final item = offline.items.single;
      expect(item.id, equals('movie-offline'));
      // Both the external HDD source and the device copy are available, so the
      // availability is reported as multi-source while offline membership is
      // driven purely by the completed device-managed copy.
      expect(
        item.availability,
        equals(AvailabilityStatus.availableOnMultipleSources),
      );

      // Completed device copy is the only thing that counts as offline.
      final localSources = await db.getSourcesForMovie('movie-offline');
      expect(
        localSources.where((s) => s.sourceType == 'localDevice' && s.available),
        hasLength(1),
      );
    });

    test('removal of the offline copy removes it from the Offline Library '
        'reactively', () async {
      await createTestMovie(
        id: 'movie-removal',
        title: 'Removal Movie',
        relativePath: 'Movies/Removal (2022)/Removal.mkv',
        content: Uint8List.fromList(List<int>.filled(256 * 1024, 9)),
      );

      final result = await transferService.transferMovie('movie-removal');
      await transferService.registerCompletedTransfer(result.transferId);

      final offlineStream = repo
          .watchMovies(MovieQuery.offline())
          .asBroadcastStream();
      final hasMovie = watchUntil(
        offlineStream,
        (r) => r.items.any((m) => m.id == 'movie-removal'),
      );
      final hasMovieResult = await hasMovie;
      expect(hasMovieResult.items, hasLength(1));

      final removed = watchUntil(
        offlineStream,
        (r) => r.items.every((m) => m.id != 'movie-removal'),
      );
      await (db.delete(
        db.mediaSources,
      )..where((ms) => ms.sourceType.equals('localDevice'))).go();
      final removedResult = await removed;
      expect(removedResult.items, isEmpty);
    });

    test(
      'TV show appears in Offline Library only when an episode is offline',
      () async {
        await createTestEpisode(
          showId: 'show-filter',
          showTitle: 'Filter Show',
          seasonId: 'season-filter-1',
          seasonNumber: 1,
          episodeId: 'ep-filter-1',
          episodeNumber: 1,
          episodeTitle: 'One',
          relativePath: 'TV/Filter/Season 1/Filter S01E01.mkv',
          content: Uint8List.fromList(List<int>.filled(128 * 1024, 3)),
        );
        await createTestEpisode(
          showId: 'show-filter',
          showTitle: 'Filter Show',
          seasonId: 'season-filter-1',
          seasonNumber: 1,
          episodeId: 'ep-filter-2',
          episodeNumber: 2,
          episodeTitle: 'Two',
          relativePath: 'TV/Filter/Season 1/Filter S01E02.mkv',
          content: Uint8List.fromList(List<int>.filled(128 * 1024, 4)),
        );
        await createTestEpisode(
          showId: 'show-external-only',
          showTitle: 'External Show',
          seasonId: 'season-external-only',
          seasonNumber: 1,
          episodeId: 'ep-external-only',
          episodeNumber: 1,
          episodeTitle: 'Ext',
          relativePath: 'TV/External/Season 1/External S01E01.mkv',
          content: Uint8List.fromList([6, 7, 8]),
        );

        // No offline episode yet.
        final empty = await repo.watchTvShows(TvShowQuery.offline()).first;
        expect(empty.items.map((t) => t.id), isNot(contains('show-filter')));
        expect(
          empty.items.map((t) => t.id),
          isNot(contains('show-external-only')),
        );

        // Offline one of the two episodes.
        final result = await transferService.transferEpisode('ep-filter-1');
        await transferService.registerCompletedTransfer(result.transferId);

        final shows = await repo.watchTvShows(TvShowQuery.offline()).first;
        expect(shows.items.map((t) => t.id), contains('show-filter'));
        expect(
          shows.items.map((t) => t.id),
          isNot(contains('show-external-only')),
        );
      },
    );
  });

  group('M5 Bug 2/4: season offline state aggregates per episode', () {
    test(
      'offlineEpisodeCount tracks per-episode completed device copies',
      () async {
        await createTestEpisode(
          showId: 'show-aggregate',
          showTitle: 'Aggregate Show',
          seasonId: 'season-aggregate-1',
          seasonNumber: 1,
          episodeId: 'ep-agg-1',
          episodeNumber: 1,
          episodeTitle: 'First',
          relativePath: 'TV/Aggregate/Season 1/Agg S01E01.mkv',
          content: Uint8List.fromList(List<int>.filled(128 * 1024, 1)),
        );
        await createTestEpisode(
          showId: 'show-aggregate',
          showTitle: 'Aggregate Show',
          seasonId: 'season-aggregate-1',
          seasonNumber: 1,
          episodeId: 'ep-agg-2',
          episodeNumber: 2,
          episodeTitle: 'Second',
          relativePath: 'TV/Aggregate/Season 1/Agg S01E02.mkv',
          content: Uint8List.fromList(List<int>.filled(128 * 1024, 2)),
        );

        final emptySeason =
            (await repo
                    .watchSeasons(SeasonQuery.forShow('show-aggregate'))
                    .first)
                .items
                .single;
        expect(emptySeason.episodeCount, equals(2));
        expect(emptySeason.offlineEpisodeCount, equals(0));
        expect(emptySeason.isFullyOffline, isFalse);
        expect(emptySeason.remainingOfflineEpisodeCount, equals(2));

        final result = await transferService.transferEpisode('ep-agg-1');
        await transferService.registerCompletedTransfer(result.transferId);

        final partial =
            (await repo
                    .watchSeasons(SeasonQuery.forShow('show-aggregate'))
                    .first)
                .items
                .single;
        expect(partial.offlineEpisodeCount, equals(1));
        expect(partial.isFullyOffline, isFalse);
        expect(partial.remainingOfflineEpisodeCount, equals(1));

        final second = await transferService.transferEpisode('ep-agg-2');
        await transferService.registerCompletedTransfer(second.transferId);

        final fullyOffline =
            (await repo
                    .watchSeasons(SeasonQuery.forShow('show-aggregate'))
                    .first)
                .items
                .single;
        expect(fullyOffline.offlineEpisodeCount, equals(2));
        expect(fullyOffline.isFullyOffline, isTrue);
        expect(fullyOffline.remainingOfflineEpisodeCount, equals(0));
      },
    );

    test('completed season transfer registers an offline copy for every '
        'episode', () async {
      await createTestEpisode(
        showId: 'show-season',
        showTitle: 'Season Show',
        seasonId: 'season-season-1',
        seasonNumber: 1,
        episodeId: 'ep-seas-1',
        episodeNumber: 1,
        episodeTitle: 'One',
        relativePath: 'TV/Season/Season 1/Season S01E01.mkv',
        content: Uint8List.fromList(List<int>.filled(128 * 1024, 3)),
      );
      await createTestEpisode(
        showId: 'show-season',
        showTitle: 'Season Show',
        seasonId: 'season-season-1',
        seasonNumber: 1,
        episodeId: 'ep-seas-2',
        episodeNumber: 2,
        episodeTitle: 'Two',
        relativePath: 'TV/Season/Season 1/Season S01E02.mkv',
        content: Uint8List.fromList(List<int>.filled(128 * 1024, 5)),
      );

      final results = await transferService.transferSeason('season-season-1');
      await transferService.registerCompletedSeasonTransfers('season-season-1');

      expect(results.where((r) => r.isFailed || r.isCancelled), isEmpty);
      for (final epId in ['ep-seas-1', 'ep-seas-2']) {
        final sources = await db.getSourcesForEpisode(epId);
        final offlineCopies = sources.where(
          (s) => s.sourceType == 'localDevice' && s.available,
        );
        expect(
          offlineCopies,
          hasLength(1),
          reason: '$epId must have exactly one completed offline copy',
        );
      }

      final season =
          (await repo.watchSeasons(SeasonQuery.forShow('show-season')).first)
              .items
              .single;
      expect(season.isFullyOffline, isTrue);
      expect(season.offlineEpisodeCount, equals(2));
    });

    test('re-running a completed season transfer skips already-offline '
        'episodes and never duplicates copies', () async {
      await createTestEpisode(
        showId: 'show-skip',
        showTitle: 'Skip Show',
        seasonId: 'season-skip-1',
        seasonNumber: 1,
        episodeId: 'ep-skip-1',
        episodeNumber: 1,
        episodeTitle: 'One',
        relativePath: 'TV/Skip/Season 1/Skip S01E01.mkv',
        content: Uint8List.fromList(List<int>.filled(128 * 1024, 1)),
      );
      await createTestEpisode(
        showId: 'show-skip',
        showTitle: 'Skip Show',
        seasonId: 'season-skip-1',
        seasonNumber: 1,
        episodeId: 'ep-skip-2',
        episodeNumber: 2,
        episodeTitle: 'Two',
        relativePath: 'TV/Skip/Season 1/Skip S01E02.mkv',
        content: Uint8List.fromList(List<int>.filled(128 * 1024, 2)),
      );

      final firstRun = await transferService.transferSeason('season-skip-1');
      await transferService.registerCompletedSeasonTransfers('season-skip-1');
      expect(firstRun, hasLength(2));

      final secondRun = await transferService.transferSeason('season-skip-1');
      await transferService.registerCompletedSeasonTransfers('season-skip-1');
      expect(secondRun, isEmpty);

      for (final epId in ['ep-skip-1', 'ep-skip-2']) {
        final sources = await db.getSourcesForEpisode(epId);
        final offlineCopies = sources.where(
          (s) => s.sourceType == 'localDevice' && s.available,
        );
        expect(
          offlineCopies,
          hasLength(1),
          reason: 're-run must not create duplicate offline copies',
        );
      }
    });

    test(
      'an external-only MediaSource is never treated as an offline copy',
      () async {
        await createTestEpisode(
          showId: 'show-external-safety',
          showTitle: 'External Safety',
          seasonId: 'season-external-safety',
          seasonNumber: 1,
          episodeId: 'ep-ext-safety',
          episodeNumber: 1,
          episodeTitle: 'Ext',
          relativePath: 'TV/Ext/Season 1/Ext S01E01.mkv',
          content: Uint8List.fromList([4, 5, 6]),
        );

        final season =
            (await repo
                    .watchSeasons(SeasonQuery.forShow('show-external-safety'))
                    .first)
                .items
                .single;
        expect(season.offlineEpisodeCount, equals(0));
        expect(season.isFullyOffline, isFalse);

        final offlineTv = await repo.watchTvShows(TvShowQuery.offline()).first;
        expect(
          offlineTv.items.map((t) => t.id),
          isNot(contains('show-external-safety')),
        );

        // Season transfer must still copy the external-only episode.
        final results = await transferService.transferSeason(
          'season-external-safety',
        );
        await transferService.registerCompletedSeasonTransfers(
          'season-external-safety',
        );
        expect(results, hasLength(1));
      },
    );
  });
}
