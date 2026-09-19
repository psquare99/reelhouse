import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reelhouse/data/network/tmdb_api_client.dart';

void main() {
  group('TmdbApiClient', () {
    test('searchMovies queries TMDB and parses results correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/3/search/movie');
        expect(request.url.queryParameters['query'], 'Interstellar');
        expect(request.url.queryParameters['primary_release_year'], '2014');
        expect(request.url.queryParameters['api_key'], 'test-api-key');

        final responseJson = {
          'results': [
            {
              'id': 157336,
              'title': 'Interstellar',
              'original_title': 'Interstellar',
              'release_date': '2014-11-05',
              'poster_path': '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
              'vote_average': 8.4,
              'vote_count': 35000,
            },
          ],
        };

        return http.Response(jsonEncode(responseJson), 200);
      });

      final client = TmdbApiClient(
        apiKey: 'test-api-key',
        httpClient: mockClient,
        minRequestInterval: Duration.zero,
      );

      final results = await client.searchMovies('Interstellar', year: 2014);

      expect(results.length, 1);
      final movie = results.first;
      expect(movie.id, 157336);
      expect(movie.title, 'Interstellar');
      expect(movie.releaseYear, 2014);
      expect(movie.voteAverage, 8.4);
    });

    test(
      'getMovieDetails fetches details including external IMDB ID',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/3/movie/157336');

          final responseJson = {
            'id': 157336,
            'title': 'Interstellar',
            'runtime': 169,
            'overview': 'The adventures of a group of explorers...',
            'external_ids': {'imdb_id': 'tt0816692'},
          };

          return http.Response(jsonEncode(responseJson), 200);
        });

        final client = TmdbApiClient(
          apiKey: 'test-api-key',
          httpClient: mockClient,
          minRequestInterval: Duration.zero,
        );

        final details = await client.getMovieDetails(157336);

        expect(details, isNotNull);
        expect(details!.id, 157336);
        expect(details.runtime, 169);
        expect(details.imdbId, 'tt0816692');
      },
    );

    test('retries on HTTP 429 rate limit before succeeding', () async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            '{"status_message":"Rate limit exceeded"}',
            429,
            headers: {'retry-after': '0'},
          );
        }
        return http.Response(
          jsonEncode({
            'results': [
              {'id': 100, 'title': 'Test Movie'},
            ],
          }),
          200,
        );
      });

      final client = TmdbApiClient(
        apiKey: 'test-api-key',
        httpClient: mockClient,
        minRequestInterval: Duration.zero,
      );

      final results = await client.searchMovies('Test');

      expect(callCount, 2);
      expect(results.length, 1);
      expect(results.first.id, 100);
    });

    test('throws TmdbApiException if no API key is configured', () async {
      final client = TmdbApiClient(
        apiKey: null,
        minRequestInterval: Duration.zero,
      );

      expect(
        () => client.searchMovies('Inception'),
        throwsA(isA<TmdbApiException>()),
      );
    });

    group('validateAuthentication', () {
      test('returns notConfigured when key is null or empty', () async {
        final client = TmdbApiClient(
          apiKey: null,
          minRequestInterval: Duration.zero,
        );

        final result = await client.validateAuthentication();
        expect(result.status, TmdbAuthStatus.notConfigured);
        expect(result.isSuccess, isFalse);

        final resultEmpty = await client.validateAuthentication('   ');
        expect(resultEmpty.status, TmdbAuthStatus.notConfigured);
      });

      test(
        'returns connected when TMDB returns 200 for /authentication',
        () async {
          final mockClient = MockClient((request) async {
            expect(request.url.path, '/3/authentication');
            expect(request.url.queryParameters['api_key'], 'valid-key');
            return http.Response(
              jsonEncode({'success': true, 'status_code': 1}),
              200,
            );
          });

          final client = TmdbApiClient(
            apiKey: 'valid-key',
            httpClient: mockClient,
            minRequestInterval: Duration.zero,
          );

          final result = await client.validateAuthentication();
          expect(result.status, TmdbAuthStatus.connected);
          expect(result.isSuccess, isTrue);
          expect(result.statusCode, 200);
        },
      );

      test('returns invalidKey when TMDB returns 401/403', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/3/authentication');
          return http.Response(
            jsonEncode({'status_code': 7, 'status_message': 'Invalid API key'}),
            401,
          );
        });

        final client = TmdbApiClient(
          apiKey: 'bad-key',
          httpClient: mockClient,
          minRequestInterval: Duration.zero,
        );

        final result = await client.validateAuthentication();
        expect(result.status, TmdbAuthStatus.invalidKey);
        expect(result.isSuccess, isFalse);
        expect(result.statusCode, 401);
      });

      test(
        'returns networkFailure on 500 server error or connection error',
        () async {
          final mockClient = MockClient((request) async {
            return http.Response('Server error', 500);
          });

          final client = TmdbApiClient(
            apiKey: 'test-key',
            httpClient: mockClient,
            minRequestInterval: Duration.zero,
          );

          final result = await client.validateAuthentication();
          expect(result.status, TmdbAuthStatus.networkFailure);
          expect(result.statusCode, 500);
        },
      );

      test(
        'validates candidate key without mutating active client key',
        () async {
          final testedKeys = <String?>[];
          final mockClient = MockClient((request) async {
            testedKeys.add(request.url.queryParameters['api_key']);
            return http.Response(
              jsonEncode({'success': true, 'status_code': 1}),
              200,
            );
          });

          final client = TmdbApiClient(
            apiKey: 'primary-key',
            httpClient: mockClient,
            minRequestInterval: Duration.zero,
          );

          final result = await client.validateAuthentication('candidate-key');
          expect(result.status, TmdbAuthStatus.connected);
          expect(testedKeys, contains('candidate-key'));
          // Ensure primary key is preserved
          expect(client.hasApiKey, isTrue);
        },
      );

      test('supports Bearer token authorization header when key length > 40', () async {
        const longBearer =
            'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJleGFtcGxlIiwic3ViIjoiMTIzNCJ9.signature12345678901234567890';
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/3/authentication');
          expect(request.headers['Authorization'], 'Bearer $longBearer');
          expect(request.url.queryParameters.containsKey('api_key'), isFalse);
          return http.Response(
            jsonEncode({'success': true, 'status_code': 1}),
            200,
          );
        });

        final client = TmdbApiClient(
          apiKey: longBearer,
          httpClient: mockClient,
          minRequestInterval: Duration.zero,
        );

        final result = await client.validateAuthentication();
        expect(result.status, TmdbAuthStatus.connected);
      });
    });
  });
}
