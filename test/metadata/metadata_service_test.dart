import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/network/tmdb_api_client.dart';
import 'package:reelhouse/domain/metadata/image_cache_service.dart';
import 'package:reelhouse/domain/metadata/metadata_matcher.dart';
import 'package:reelhouse/domain/metadata/metadata_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';

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

    // 1. Insert unmatched movie into database
    final now = DateTime.now();
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'movie-interstellar',
            title: 'Interstellar',
            year: const drift.Value(2014),
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
    expect(updatedMovie!.tmdbId, 157336);
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
            title: 'The Thing',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final movie = (await db.getAllMovies()).first;

    // 1. Automatic identification should flag as ambiguous / needs verification
    final decision = await service.identifyMovie(movie);
    expect(decision.needsVerification, isTrue);
    expect(decision.candidates.length, 2);

    // Movie remains unmatched in DB
    final notEnriched = await db.findMovieById('movie-the-thing');
    expect(notEnriched!.tmdbId, isNull);

    // 2. User manually selects 1982 version
    final selected = decision.candidates.firstWhere((c) => c.id == 1091);
    await service.applyMovieMatch('movie-the-thing', selected, isManual: true);

    // Movie is now enriched with manual attribution
    final manuallyEnriched = await db.findMovieById('movie-the-thing');
    expect(manuallyEnriched!.tmdbId, 1091);
    expect(manuallyEnriched.overview, 'John Carpenter masterpiece.');
    expect(manuallyEnriched.metadataId, 'manual:tmdb:1091');
    expect((await db.getUnmatchedMovies()).isEmpty, isTrue);
  });
}
