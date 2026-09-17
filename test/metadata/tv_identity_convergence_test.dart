import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/network/tmdb_api_client.dart';
import 'package:reelhouse/data/network/tmdb_models.dart';
import 'package:reelhouse/domain/metadata/image_cache_service.dart';
import 'package:reelhouse/domain/metadata/metadata_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';

class MockStorageIdentityService implements StorageIdentityService {
  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'mock-id';
  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      'Mock Drive';
  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async => true;
  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;
  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {}
}

class MockLocalStorageManager implements LocalStorageManager {
  final String testPath;
  MockLocalStorageManager(this.testPath);

  @override
  Future<String> getLocalMediaDirectoryPath() async => testPath;

  @override
  Future<int> getAvailableDeviceStorageBytes() async => 50000000;

  @override
  Future<int> getUsedOfflineStorageBytes() async => 0;

  @override
  Future<String> resolveLocalPath(String relativePath) async =>
      '$testPath/$relativePath';

  @override
  Future<bool> verifyLocalCopyIntegrity(
    String relativePath,
    int expectedBytes,
  ) async => true;

  @override
  Future<bool> deleteLocalCopy(String relativePath) async => true;
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late MockLocalStorageManager storageManager;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = Directory.systemTemp.createTempSync(
      'reelhouse_convergence_test_',
    );
    storageManager = MockLocalStorageManager(tempDir.path);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Database mergeTvShows & mergeMovies', () {
    test('mergeTvShows correctly merges disjoint seasons without losing media sources', () async {
      final now = DateTime.now();

      // Storage
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'storage-1',
              name: 'Main Drive',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'serial-1',
              rootUri: r'D:\TV',
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // Target Show: "Two and a Half Men" (S1, S2, S3)
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'show-main',
              detectedTitle: 'Two and a Half Men',
              title: const drift.Value('Two and a Half Men'),
              tmdbId: const drift.Value(2691),
              identificationStatus: const drift.Value('IDENTIFIED'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // S1 for Target Show
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 'season-s1',
              showId: 'show-main',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-s1e1',
              seasonId: 'season-s1',
              episodeNumber: 1,
              name: const drift.Value('Pilot'),
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-s1e1',
              episodeId: const drift.Value('ep-s1e1'),
              storageId: 'storage-1',
              sourceType: 'removableStorage',
              relativePath: 'Two and a Half Men/Season 1/S01E01.mkv',
              filename: 'S01E01.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Duplicate Source Show: "Two and a Half Men 2003" (S4)
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'show-dup',
              detectedTitle: 'Two and a Half Men 2003',
              title: const drift.Value('Two and a Half Men 2003'),
              identificationStatus: const drift.Value('PENDING'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // S4 for Source Show
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 'season-s4',
              showId: 'show-dup',
              seasonNumber: 4,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-s4e1',
              seasonId: 'season-s4',
              episodeNumber: 1,
              name: const drift.Value('Working for Caligula'),
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-s4e1',
              episodeId: const drift.Value('ep-s4e1'),
              storageId: 'storage-1',
              sourceType: 'removableStorage',
              relativePath: 'Two and a Half Men 2003/Season 4/S04E01.mkv',
              filename: 'S04E01.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(1000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Perform Merge
      await db.mergeTvShows(
        sourceShowId: 'show-dup',
        targetShowId: 'show-main',
      );

      // Verify Source Show is deleted
      final deletedShow = await db.findTvShowById('show-dup');
      expect(deletedShow, isNull);

      // Verify Target Show has both seasons
      final seasons = await db.getSeasonsForShow('show-main');
      expect(seasons.length, 2);
      expect(seasons.map((s) => s.seasonNumber).toList(), containsAll([1, 4]));

      // Verify S4 season is now under target show
      final s4 = seasons.firstWhere((s) => s.seasonNumber == 4);
      expect(s4.id, 'season-s4');
      expect(s4.showId, 'show-main');

      // Verify S4 episode and media source are completely intact
      final s4Episodes = await db.getEpisodesForSeason(s4.id);
      expect(s4Episodes.length, 1);
      expect(s4Episodes.first.id, 'ep-s4e1');
      expect(s4Episodes.first.name, 'Working for Caligula');

      final s4Sources = await db.getSourcesForEpisode('ep-s4e1');
      expect(s4Sources.length, 1);
      expect(s4Sources.first.id, 'src-s4e1');
      expect(
        s4Sources.first.relativePath,
        'Two and a Half Men 2003/Season 4/S04E01.mkv',
      );

      // Verify total sources for show-main is 2
      final allShowSources = await db.getSourcesForTvShow('show-main');
      expect(allShowSources.length, 2);
    });

    test('mergeTvShows merges overlapping seasons and episodes, combining media sources and merging watch states', () async {
      final now = DateTime.now();

      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'storage-1',
              name: 'Main Drive',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'serial-1',
              rootUri: r'D:\TV',
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // Target Show with S1E1 (UNWATCHED, file A)
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'show-target',
              detectedTitle: 'Severance',
              title: const drift.Value('Severance'),
              tmdbId: const drift.Value(97546),
              identificationStatus: const drift.Value('IDENTIFIED'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 'target-s1',
              showId: 'show-target',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'target-s1e1',
              seasonId: 'target-s1',
              episodeNumber: 1,
              name: const drift.Value('Good News About Hell'),
              watchState: const drift.Value('UNWATCHED'),
              playbackPositionSeconds: const drift.Value(0),
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-file-a',
              episodeId: const drift.Value('target-s1e1'),
              storageId: 'storage-1',
              sourceType: 'removableStorage',
              relativePath: 'Severance/Season 1/Severance.S01E01.1080p.mkv',
              filename: 'Severance.S01E01.1080p.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(2000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Source Show with S1E1 (WATCHED, file B - e.g. 4K version)
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'show-source',
              detectedTitle: 'Severance 2022',
              title: const drift.Value('Severance 2022'),
              identificationStatus: const drift.Value('PENDING'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 'source-s1',
              showId: 'show-source',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'source-s1e1',
              seasonId: 'source-s1',
              episodeNumber: 1,
              name: const drift.Value('Good News About Hell (4K)'),
              watchState: const drift.Value('WATCHED'),
              playbackPositionSeconds: const drift.Value(3200),
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-file-b',
              episodeId: const drift.Value('source-s1e1'),
              storageId: 'storage-1',
              sourceType: 'removableStorage',
              relativePath: 'Severance.2022/S01E01.2160p.mkv',
              filename: 'S01E01.2160p.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(8000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Perform Merge
      await db.mergeTvShows(
        sourceShowId: 'show-source',
        targetShowId: 'show-target',
      );

      // Verify source show, season, and episode records are cleaned up
      expect(await db.findTvShowById('show-source'), isNull);
      expect(
        await (db.select(
          db.seasons,
        )..where((s) => s.id.equals('source-s1'))).getSingleOrNull(),
        isNull,
      );
      expect(
        await (db.select(
          db.episodes,
        )..where((e) => e.id.equals('source-s1e1'))).getSingleOrNull(),
        isNull,
      );

      // Verify target episode now contains BOTH media sources
      final targetSources = await db.getSourcesForEpisode('target-s1e1');
      expect(targetSources.length, 2);
      expect(
        targetSources.map((s) => s.id).toList(),
        containsAll(['src-file-a', 'src-file-b']),
      );

      // Verify watch state merged: WATCHED wins over UNWATCHED
      final targetEp = (await db.getEpisodesForSeason('target-s1')).first;
      expect(targetEp.watchState, 'WATCHED');
    });

    test('mergeTvShows re-parents collections and deduplicates', () async {
      final now = DateTime.now();

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'target-show',
              detectedTitle: 'Show Target',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'source-show',
              detectedTitle: 'Show Source',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Collections: Col A contains both; Col B contains only source
      await db
          .into(db.collections)
          .insert(
            CollectionsCompanion.insert(
              id: 'col-a',
              name: 'Favorites',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.collections)
          .insert(
            CollectionsCompanion.insert(
              id: 'col-b',
              name: 'Comedy',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.collectionItems)
          .insert(
            CollectionItemsCompanion.insert(
              id: 'item-1',
              collectionId: 'col-a',
              tvShowId: const drift.Value('target-show'),
              addedAt: now,
            ),
          );
      await db
          .into(db.collectionItems)
          .insert(
            CollectionItemsCompanion.insert(
              id: 'item-2',
              collectionId: 'col-a',
              tvShowId: const drift.Value('source-show'),
              addedAt: now,
            ),
          );
      await db
          .into(db.collectionItems)
          .insert(
            CollectionItemsCompanion.insert(
              id: 'item-3',
              collectionId: 'col-b',
              tvShowId: const drift.Value('source-show'),
              addedAt: now,
            ),
          );

      await db.mergeTvShows(
        sourceShowId: 'source-show',
        targetShowId: 'target-show',
      );

      final colAItems = await db.getItemsForCollection('col-a');
      expect(colAItems.length, 1);
      expect(colAItems.first.tvShowId, 'target-show');

      final colBItems = await db.getItemsForCollection('col-b');
      expect(colBItems.length, 1);
      expect(colBItems.first.tvShowId, 'target-show');
    });

    test('mergeMovies re-points sources and merges watch states', () async {
      final now = DateTime.now();

      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'storage-1',
              name: 'Main Drive',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'serial-1',
              rootUri: r'D:\Movies',
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'movie-target',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              tmdbId: const drift.Value(27205),
              watchState: const drift.Value('IN_PROGRESS'),
              playbackPositionSeconds: const drift.Value(500),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-inception-1',
              movieId: const drift.Value('movie-target'),
              storageId: 'storage-1',
              sourceType: 'removableStorage',
              relativePath: 'Inception.1080p.mkv',
              filename: 'Inception.1080p.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(2000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'movie-source',
              detectedTitle: 'Inception 2010',
              title: const drift.Value('Inception 2010'),
              watchState: const drift.Value('IN_PROGRESS'),
              playbackPositionSeconds: const drift.Value(1500),
              isFavorite: const drift.Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-inception-2',
              movieId: const drift.Value('movie-source'),
              storageId: 'storage-1',
              sourceType: 'removableStorage',
              relativePath: 'Inception.2010.2160p.mkv',
              filename: 'Inception.2010.2160p.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(8000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      await db.mergeMovies(
        sourceMovieId: 'movie-source',
        targetMovieId: 'movie-target',
      );

      expect(await db.findMovieById('movie-source'), isNull);

      final mergedMovie = await db.findMovieById('movie-target');
      expect(mergedMovie, isNotNull);
      expect(mergedMovie!.isFavorite, isTrue);
      expect(mergedMovie.watchState, 'IN_PROGRESS');
      expect(mergedMovie.playbackPositionSeconds, 1500);

      final sources = await db.getSourcesForMovie('movie-target');
      expect(sources.length, 2);
      expect(
        sources.map((s) => s.id).toList(),
        containsAll(['src-inception-1', 'src-inception-2']),
      );
    });
  });

  group('MetadataService Canonical Convergence', () {
    test('applyTvShowMatch converges duplicate TV shows into single canonical show and enriches all seasons', () async {
      final now = DateTime.now();

      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/3/tv/2691') {
          return http.Response(
            jsonEncode({
              'id': 2691,
              'name': 'Two and a Half Men',
              'original_name': 'Two and a Half Men',
              'overview': 'A hedonistic jingle writer...',
              'first_air_date': '2003-09-22',
              'poster_path': '/poster.jpg',
              'backdrop_path': '/backdrop.jpg',
              'vote_average': 7.2,
              'vote_count': 3000,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/3/tv/2691/season/1') {
          return http.Response(
            jsonEncode({
              'season_number': 1,
              'episodes': [
                {
                  'id': 1001,
                  'episode_number': 1,
                  'name': 'Pilot',
                  'overview': 'Charlie is a wealthy jingle writer...',
                  'still_path': '/still_s1e1.jpg',
                  'vote_average': 7.5,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/3/tv/2691/season/4') {
          return http.Response(
            jsonEncode({
              'season_number': 4,
              'episodes': [
                {
                  'id': 4001,
                  'episode_number': 1,
                  'name': 'Working for Caligula',
                  'overview': 'Charlie tries to adjust...',
                  'still_path': '/still_s4e1.jpg',
                  'vote_average': 7.8,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.contains('/t/p/')) {
          return http.Response.bytes(
            [1, 2, 3, 4],
            200,
            headers: {'content-type': 'image/jpeg'},
          );
        }

        return http.Response('Not Found', 404);
      });

      final tmdbClient = TmdbApiClient(
        apiKey: 'test-api-key',
        httpClient: mockClient,
      );
      final imageCacheService = ImageCacheService(
        localStorageManager: storageManager,
        httpClient: mockClient,
      );
      final metadataService = MetadataService(
        database: db,
        tmdbClient: tmdbClient,
        imageCacheService: imageCacheService,
      );

      // 1. Pre-existing canonical show: "Two and a Half Men" with TMDB ID 2691 (S1)
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'show-main-id',
              detectedTitle: 'Two and a Half Men',
              title: const drift.Value('Two and a Half Men'),
              tmdbId: const drift.Value(2691),
              identificationStatus: const drift.Value('IDENTIFIED'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 'season-1-id',
              showId: 'show-main-id',
              seasonNumber: 1,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-s1e1-id',
              seasonId: 'season-1-id',
              episodeNumber: 1,
              name: const drift.Value('Pilot'),
            ),
          );

      // 2. Duplicate show pending verification: "Two and a Half Men 2003" (S4)
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'show-dup-id',
              detectedTitle: 'Two and a Half Men 2003',
              identificationStatus: const drift.Value('PENDING'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 'season-4-id',
              showId: 'show-dup-id',
              seasonNumber: 4,
            ),
          );
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-s4e1-id',
              seasonId: 'season-4-id',
              episodeNumber: 1,
            ),
          );

      // 3. User or pipeline matches duplicate show to TMDB candidate 2691
      const candidate = TmdbTvSearchResult(
        id: 2691,
        name: 'Two and a Half Men',
        originalName: 'Two and a Half Men',
        overview: 'A hedonistic jingle writer...',
        firstAirDate: '2003-09-22',
        firstAirYear: 2003,
      );

      await metadataService.applyTvShowMatch('show-dup-id', candidate);

      // 4. Verify Duplicate Show is deleted from the database
      expect(await db.findTvShowById('show-dup-id'), isNull);

      // 5. Verify Main Show has converged both seasons
      final mainShow = await db.findTvShowById('show-main-id');
      expect(mainShow, isNotNull);
      expect(mainShow!.title, 'Two and a Half Men');
      expect(mainShow.tmdbId, 2691);

      final seasons = await db.getSeasonsForShow('show-main-id');
      expect(seasons.length, 2);
      expect(seasons.map((s) => s.seasonNumber).toList(), containsAll([1, 4]));

      // 6. Verify S4 episode was enriched with TMDB episode details & still path
      final s4Episodes = await db.getEpisodesForSeason('season-4-id');
      expect(s4Episodes.length, 1);
      final s4e1 = s4Episodes.first;
      expect(s4e1.name, 'Working for Caligula');
      expect(s4e1.tmdbId, 4001);
      expect(s4e1.stillPath, isNotNull);
    });

    test('shows with different TMDB IDs do not merge', () async {
      final now = DateTime.now();

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path == '/3/tv/100') {
          return http.Response(
            jsonEncode({
              'id': 100,
              'name': 'Show One',
              'original_name': 'Show One',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path == '/3/tv/200') {
          return http.Response(
            jsonEncode({
              'id': 200,
              'name': 'Show Two',
              'original_name': 'Show Two',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final tmdbClient = TmdbApiClient(
        apiKey: 'test-api-key',
        httpClient: mockClient,
      );
      final imageCacheService = ImageCacheService(
        localStorageManager: storageManager,
        httpClient: mockClient,
      );
      final metadataService = MetadataService(
        database: db,
        tmdbClient: tmdbClient,
        imageCacheService: imageCacheService,
      );

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'show-1',
              detectedTitle: 'Show One',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'show-2',
              detectedTitle: 'Show Two',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await metadataService.applyTvShowMatch(
        'show-1',
        const TmdbTvSearchResult(
          id: 100,
          name: 'Show One',
          originalName: 'Show One',
        ),
      );
      await metadataService.applyTvShowMatch(
        'show-2',
        const TmdbTvSearchResult(
          id: 200,
          name: 'Show Two',
          originalName: 'Show Two',
        ),
      );

      final show1 = await db.findTvShowById('show-1');
      final show2 = await db.findTvShowById('show-2');

      expect(show1, isNotNull);
      expect(show1!.tmdbId, 100);
      expect(show2, isNotNull);
      expect(show2!.tmdbId, 200);
    });
  });
}
