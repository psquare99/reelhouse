import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/network/tmdb_api_client.dart';
import 'package:reelhouse/data/network/tmdb_models.dart';
import 'package:reelhouse/domain/metadata/image_cache_service.dart';
import 'package:reelhouse/domain/metadata/metadata_matcher.dart';
import 'package:reelhouse/domain/metadata/metadata_service.dart';
import 'package:reelhouse/domain/scanner/library_scanner_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';

class MockStorageIdentityService implements StorageIdentityService {
  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async => 'mock-id';
  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async => 'Mock Drive';
  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async => true;
  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;
  @override
  Future<void> writeMarkerIdentifier(String rootUriOrPath, String storageId) async {}
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
      'reelhouse_meta_service_test_',
    );
    storageManager = MockLocalStorageManager(tempDir.path);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('identifyMovie automatically enriches movie when high confidence match is found', () async {
    final mockClient = MockClient((request) async {
      final path = request.url.path;

      if (path == '/3/search/movie') {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 157336,
                'title': 'Interstellar',
                'release_date': '2014-11-05',
                'poster_path': '/interstellar.jpg',
                'backdrop_path': '/backdrop.jpg',
                'vote_average': 8.4,
                'vote_count': 35000,
              },
            ],
          }),
          200,
        );
      }

      if (path == '/3/movie/157336') {
        return http.Response(
          jsonEncode({
            'id': 157336,
            'title': 'Interstellar',
            'overview': 'The adventures of a group of explorers...',
            'runtime': 169,
            'release_date': '2014-11-05',
            'poster_path': '/interstellar.jpg',
            'backdrop_path': '/backdrop.jpg',
            'vote_average': 8.4,
            'vote_count': 35000,
            'external_ids': {'imdb_id': 'tt0816692'},
          }),
          200,
        );
      }

      if (request.url.host == 'image.tmdb.org') {
        return http.Response.bytes([1, 2, 3], 200);
      }

      return http.Response('Not Found', 404);
    });

    final tmdbClient = TmdbApiClient(
      apiKey: 'test-api-key',
      httpClient: mockClient,
      minRequestInterval: Duration.zero,
    );
    final imageCache = ImageCacheService(
      localStorageManager: storageManager,
      httpClient: mockClient,
    );
    final service = MetadataService(
      database: db,
      tmdbClient: tmdbClient,
      imageCacheService: imageCache,
      matcher: const MetadataMatcher(),
    );

    // 1. Insert unmatched movie into database (with null canonical title/year, pending status)
    final now = DateTime.now();
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'movie-interstellar',
            detectedTitle: 'Interstellar',
            detectedYear: const drift.Value(2014),
            identificationStatus: const drift.Value('PENDING'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect((await db.getUnmatchedMovies()).length, 1);

    final movie = (await db.getAllMovies()).first;

    // 2. Run identification
    final decision = await service.identifyMovie(movie);

    expect(decision.isAutomatic, isTrue);
    expect(decision.bestMatch?.id, 157336);

    // 3. Verify database was enriched
    final updatedMovie = await db.findMovieById('movie-interstellar');
    expect(updatedMovie, isNotNull);
    expect(updatedMovie!.detectedTitle, 'Interstellar');
    expect(updatedMovie.detectedYear, 2014);
    expect(updatedMovie.title, 'Interstellar');
    expect(updatedMovie.year, 2014);
    expect(updatedMovie.identificationStatus, 'IDENTIFIED');
    expect(updatedMovie.metadataProvider, 'TMDB');
    expect(updatedMovie.providerItemId, '157336');
    expect(updatedMovie.tmdbId, 157336);
    expect(updatedMovie.imdbId, 'tt0816692');
    expect(updatedMovie.runtime, 169);
    expect(updatedMovie.rating, 8.4);
    expect(
      updatedMovie.overview,
      contains('adventures of a group of explorers'),
    );
    expect(updatedMovie.posterPath, isNotNull);
    expect(File(updatedMovie.posterPath!).existsSync(), isTrue);

    // 4. Verify no longer unmatched
    expect((await db.getUnmatchedMovies()).isEmpty, isTrue);
  });

  test('identifyMovie routes ambiguous remakes to needsVerification and allows manual resolution', () async {
    final mockClient = MockClient((request) async {
      final path = request.url.path;

      if (path == '/3/search/movie') {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 1091,
                'title': 'The Thing',
                'release_date': '1982-06-25',
                'poster_path': '/thething1982.jpg',
              },
              {
                'id': 60935,
                'title': 'The Thing',
                'release_date': '2011-10-14',
                'poster_path': '/thething2011.jpg',
              },
            ],
          }),
          200,
        );
      }

      if (path == '/3/movie/1091') {
        return http.Response(
          jsonEncode({
            'id': 1091,
            'title': 'The Thing',
            'release_date': '1982-06-25',
            'overview': 'John Carpenter masterpiece.',
            'runtime': 109,
          }),
          200,
        );
      }

      return http.Response.bytes([1, 2], 200);
    });

    final tmdbClient = TmdbApiClient(
      apiKey: 'test-api-key',
      httpClient: mockClient,
      minRequestInterval: Duration.zero,
    );
    final imageCache = ImageCacheService(
      localStorageManager: storageManager,
      httpClient: mockClient,
    );
    final service = MetadataService(
      database: db,
      tmdbClient: tmdbClient,
      imageCacheService: imageCache,
    );

    // Insert movie without year: "The Thing"
    final now = DateTime.now();
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'movie-the-thing',
            detectedTitle: 'The Thing',
            identificationStatus: const drift.Value('PENDING'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final movie = (await db.getAllMovies()).first;

    // 1. Automatic identification should flag as ambiguous / needs verification
    final decision = await service.identifyMovie(movie);
    expect(decision.needsVerification, isTrue);
    expect(decision.candidates.length, 2);

    // Movie remains unmatched in DB and status transitioned to NEEDS_VERIFICATION
    final notEnriched = await db.findMovieById('movie-the-thing');
    expect(notEnriched!.tmdbId, isNull);
    expect(notEnriched.title, isNull);
    expect(notEnriched.identificationStatus, 'NEEDS_VERIFICATION');

    // 2. User manually selects 1982 version
    final selected = decision.candidates.firstWhere((c) => c.id == 1091);
    await service.applyMovieMatch('movie-the-thing', selected, isManual: true);

    // Movie is now enriched with manual attribution
    final manuallyEnriched = await db.findMovieById('movie-the-thing');
    expect(manuallyEnriched!.detectedTitle, 'The Thing');
    expect(manuallyEnriched.title, 'The Thing');
    expect(manuallyEnriched.year, 1982);
    expect(manuallyEnriched.identificationStatus, 'IDENTIFIED');
    expect(manuallyEnriched.metadataProvider, 'TMDB');
    expect(manuallyEnriched.providerItemId, '1091');
    expect(manuallyEnriched.tmdbId, 1091);
    expect(manuallyEnriched.overview, 'John Carpenter masterpiece.');
    expect(manuallyEnriched.metadataId, 'manual:tmdb:1091');
    expect((await db.getUnmatchedMovies()).isEmpty, isTrue);
  });

  // --- Phase 1C Comprehensive Tests A through G ---

  test('A & C & G: Automatic movie canonicalization preserves detected fields and persists canonical title, year, status, and provenance', () async {
    final mockClient = MockClient((request) async {
      final path = request.url.path;
      if (path == '/3/search/movie') {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 27205,
                'title': 'Inception',
                'release_date': '2010-07-16',
                'poster_path': '/inception.jpg',
                'vote_average': 8.8,
                'vote_count': 34000,
              },
            ],
          }),
          200,
        );
      }
      if (path == '/3/movie/27205') {
        return http.Response(
          jsonEncode({
            'id': 27205,
            'title': 'Inception',
            'overview': 'Cobb steals information from targets dreams.',
            'runtime': 148,
            'release_date': '2010-07-16',
            'poster_path': '/inception.jpg',
            'vote_average': 8.8,
            'vote_count': 34000,
          }),
          200,
        );
      }
      return http.Response.bytes([1, 2], 200);
    });

    final tmdbClient = TmdbApiClient(
      apiKey: 'test-api-key',
      httpClient: mockClient,
      minRequestInterval: Duration.zero,
    );
    final imageCache = ImageCacheService(
      localStorageManager: storageManager,
      httpClient: mockClient,
    );
    final service = MetadataService(
      database: db,
      tmdbClient: tmdbClient,
      imageCacheService: imageCache,
    );

    final now = DateTime.now();
    await db.into(db.movies).insert(
      MoviesCompanion.insert(
        id: 'movie-inception',
        detectedTitle: 'Inception',
        detectedYear: const drift.Value(2010),
        identificationStatus: const drift.Value('PENDING'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final movie = (await db.getAllMovies()).first;
    final decision = await service.identifyMovie(movie);

    expect(decision.isAutomatic, isTrue);

    final updated = await db.findMovieById('movie-inception');
    expect(updated, isNotNull);
    // (A & G) Detected fields remain untouched
    expect(updated!.detectedTitle, 'Inception');
    expect(updated.detectedYear, 2010);
    // (A & C) Canonical fields populated from provider
    expect(updated.title, 'Inception');
    expect(updated.year, 2010);
    expect(updated.tmdbId, 27205);
    expect(updated.identificationStatus, 'IDENTIFIED');
    expect(updated.metadataProvider, 'TMDB');
    expect(updated.providerItemId, '27205');
  });

  test('B & E & G: TV canonicalization (automatic & manual) with variant HIMYM -> How I Met Your Mother preserves detectedTitle', () async {
    final mockClient = MockClient((request) async {
      final path = request.url.path;
      if (path == '/3/search/tv') {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 1100,
                'name': 'How I Met Your Mother',
                'first_air_date': '2005-09-19',
                'poster_path': '/himym.jpg',
                'vote_average': 8.2,
                'vote_count': 4500,
              },
            ],
          }),
          200,
        );
      }
      if (path == '/3/tv/1100') {
        return http.Response(
          jsonEncode({
            'id': 1100,
            'name': 'How I Met Your Mother',
            'overview': 'Ted Mosby recounts how he met his wife.',
            'first_air_date': '2005-09-19',
            'poster_path': '/himym.jpg',
            'vote_average': 8.2,
            'vote_count': 4500,
          }),
          200,
        );
      }
      return http.Response.bytes([1, 2], 200);
    });

    final tmdbClient = TmdbApiClient(
      apiKey: 'test-api-key',
      httpClient: mockClient,
      minRequestInterval: Duration.zero,
    );
    final imageCache = ImageCacheService(
      localStorageManager: storageManager,
      httpClient: mockClient,
    );
    final service = MetadataService(
      database: db,
      tmdbClient: tmdbClient,
      imageCacheService: imageCache,
    );

    final now = DateTime.now();
    await db.into(db.tvShows).insert(
      TvShowsCompanion.insert(
        id: 'show-himym',
        detectedTitle: 'HIMYM',
        identificationStatus: const drift.Value('PENDING'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final show = (await db.getAllTvShows()).first;
    expect(show.detectedTitle, 'HIMYM');
    expect(show.title, isNull);

    // Search and apply candidate manually (E)
    final candidates = await tmdbClient.searchTvShows('HIMYM');
    expect(candidates.isNotEmpty, isTrue);
    final chosenCandidate = candidates.first;

    await service.applyTvShowMatch('show-himym', chosenCandidate, isManual: true);

    final updated = await (db.select(db.tvShows)..where((t) => t.id.equals('show-himym'))).getSingle();
    // (B & E & G) Verify canonical title is provider name, detectedTitle remains HIMYM
    expect(updated.detectedTitle, 'HIMYM');
    expect(updated.title, 'How I Met Your Mother');
    expect(updated.tmdbId, 1100);
    expect(updated.identificationStatus, 'IDENTIFIED');
    expect(updated.metadataProvider, 'TMDB');
    expect(updated.providerItemId, '1100');
    expect(updated.metadataId, 'manual:tmdb:1100');
  });

  test('D: Ambiguous / low-confidence match marks status as NEEDS_VERIFICATION and does not write canonical title', () async {
    final mockClient = MockClient((request) async {
      final path = request.url.path;
      if (path == '/3/search/tv') {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 901,
                'name': 'Totally Unrelated Show Alpha',
                'first_air_date': '2019-01-01',
              },
              {
                'id': 902,
                'name': 'Totally Unrelated Show Beta',
                'first_air_date': '2020-01-01',
              },
            ],
          }),
          200,
        );
      }
      return http.Response.bytes([1, 2], 200);
    });

    final tmdbClient = TmdbApiClient(
      apiKey: 'test-api-key',
      httpClient: mockClient,
      minRequestInterval: Duration.zero,
    );
    final imageCache = ImageCacheService(
      localStorageManager: storageManager,
      httpClient: mockClient,
    );
    final service = MetadataService(
      database: db,
      tmdbClient: tmdbClient,
      imageCacheService: imageCache,
    );

    final now = DateTime.now();
    await db.into(db.tvShows).insert(
      TvShowsCompanion.insert(
        id: 'show-ambiguous',
        detectedTitle: 'Obscure Show',
        identificationStatus: const drift.Value('PENDING'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final show = (await db.getAllTvShows()).first;
    final decision = await service.identifyTvShow(show);

    expect(decision.needsVerification, isTrue);

    final updated = await (db.select(db.tvShows)..where((t) => t.id.equals('show-ambiguous'))).getSingle();
    expect(updated.detectedTitle, 'Obscure Show');
    expect(updated.title, isNull);
    expect(updated.tmdbId, isNull);
    expect(updated.identificationStatus, 'NEEDS_VERIFICATION');
  });

  test('F: Rescan after canonicalization finds existing show via detectedTitle, preserves ID, and attaches new episodes', () async {
    final storageCompanion = StoragesCompanion.insert(
      id: 'hdd-rescan-meta',
      name: 'Rescan Storage',
      storageType: 'REMOVABLE_VOLUME',
      filesystemIdentifier: '0xRESCAN',
      rootUri: tempDir.path,
      lastSeenAt: DateTime.now(),
      available: const drift.Value(true),
    );
    await db.upsertStorage(storageCompanion);
    final storage = (await db.getAllStorages()).firstWhere((s) => s.id == 'hdd-rescan-meta');

    final scanner = LibraryScannerService(
      database: db,
      storageIdentityService: MockStorageIdentityService(),
    );

    // 1. Initial scan discovers HIMYM S01E01
    final ep1File = File(p.join(tempDir.path, 'HIMYM', 'Season 1', 'HIMYM.S01E01.mkv'));
    ep1File.parent.createSync(recursive: true);
    ep1File.writeAsBytesSync(List.filled(1024, 0));

    await scanner.scanStorage(storage);

    final showBefore = (await db.getAllTvShows()).first;
    expect(showBefore.detectedTitle, 'HIMYM');
    expect(showBefore.title, isNull);
    final originalShowId = showBefore.id;

    // 2. Metadata service canonicalizes show to "How I Met Your Mother"
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'id': 1100,
          'name': 'How I Met Your Mother',
          'first_air_date': '2005-09-19',
        }),
        200,
      );
    });
    final tmdbClient = TmdbApiClient(
      apiKey: 'test-api-key',
      httpClient: mockClient,
      minRequestInterval: Duration.zero,
    );
    final service = MetadataService(
      database: db,
      tmdbClient: tmdbClient,
      imageCacheService: ImageCacheService(
        localStorageManager: storageManager,
        httpClient: mockClient,
      ),
    );

    await service.applyTvShowMatch(
      originalShowId,
      const TmdbTvSearchResult(id: 1100, name: 'How I Met Your Mother'),
    );

    final canonicalizedShow = await (db.select(db.tvShows)..where((t) => t.id.equals(originalShowId))).getSingle();
    expect(canonicalizedShow.title, 'How I Met Your Mother');
    expect(canonicalizedShow.detectedTitle, 'HIMYM');
    expect(canonicalizedShow.identificationStatus, 'IDENTIFIED');

    // 3. User adds Episode 2 to disk and rescans
    final ep2File = File(p.join(tempDir.path, 'HIMYM', 'Season 1', 'HIMYM.S01E02.mkv'));
    ep2File.writeAsBytesSync(List.filled(1024, 0));

    await scanner.scanStorage(storage);

    // Verify exactly ONE logical TvShow exists, reusing the original ID
    final shows = await db.getAllTvShows();
    expect(shows.length, 1);
    expect(shows.first.id, originalShowId);
    expect(shows.first.detectedTitle, 'HIMYM');
    expect(shows.first.title, 'How I Met Your Mother');

    // Verify season and both episodes belong to this show
    final season = await db.findSeason(originalShowId, 1);
    expect(season, isNotNull);

    final ep1 = await db.findEpisode(season!.id, 1);
    final ep2 = await db.findEpisode(season.id, 2);
    expect(ep1, isNotNull);
    expect(ep2, isNotNull);

    final ep1Sources = await db.getSourcesForEpisode(ep1!.id);
    final ep2Sources = await db.getSourcesForEpisode(ep2!.id);
    expect(ep1Sources.length, 1);
    expect(ep2Sources.length, 1);
  });
}
