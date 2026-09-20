import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reelhouse/data/services/update_models.dart';
import 'package:reelhouse/data/services/update_service_impl.dart';

/// Builds a minimal GitHub Releases API response payload.
Map<String, dynamic> _releaseJson({
  required String tagName,
  String htmlUrl = 'https://github.com/psquare99/reelhouse/releases/tag/v1.1.0',
  String publishedAt = '2026-01-15T12:00:00Z',
  String body = 'Release notes here.',
}) => {
  'tag_name': tagName,
  'html_url': htmlUrl,
  'published_at': publishedAt,
  'body': body,
};

void main() {
  group('UpdateServiceImpl', () {
    // ── 1. Update available (remote 1.1.0 > installed 1.0.0) ──────────
    test('returns updateAvailable when remote version is newer', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: 'v1.1.0')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.updateAvailable);
      expect(result.hasUpdate, isTrue);
      expect(result.releaseInfo, isNotNull);
      expect(result.releaseInfo!.version, '1.1.0');
      expect(result.releaseInfo!.tagName, 'v1.1.0');
    });

    // ── 2. Up to date (remote 1.0.0 == installed 1.0.0) ───────────────
    test('returns upToDate when versions match', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: 'v1.0.0')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.upToDate);
      expect(result.hasUpdate, isFalse);
      expect(result.releaseInfo, isNull);
    });

    // ── 3. Ahead of release (installed 2.0.0 > remote 1.1.0) ──────────
    test('returns aheadOfRelease when installed version is newer', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: 'v1.1.0')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '2.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.aheadOfRelease);
      expect(result.hasUpdate, isFalse);
      expect(result.releaseInfo, isNull);
    });

    // ── 4. Leading "v" stripped ───────────────────────────────────────
    test('strips leading v/V from tag_name', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: 'V2.0.0')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.updateAvailable);
      expect(result.releaseInfo!.version, '2.0.0');
      expect(result.releaseInfo!.tagName, 'V2.0.0');
    });

    // ── 5. Unparseable remote tag ─────────────────────────────────────
    test('returns checkFailed for unparseable remote tag', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: 'not-a-version')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.errorMessage, contains('not-a-version'));
    });

    // ── 6. Unparseable local version ──────────────────────────────────
    test('returns checkFailed when local version is invalid', () async {
      final mockClient = MockClient((_) async {
        return http.Response('never reached', 200);
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: 'not.valid',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(
        result.errorMessage,
        contains('Unable to parse installed app version'),
      );
      expect(result.hasUpdate, isFalse);
    });

    // ── 7. HTTP 404 + repo exists → releaseChannelEmpty ───────────────
    test(
      'returns releaseChannelEmpty when 404 on release but repo exists',
      () async {
        final mockClient = MockClient((request) async {
          // Release endpoint returns 404
          if (request.url.path.contains('releases')) {
            return http.Response('{"message":"Not Found"}', 404);
          }
          // Repo validation endpoint returns 200 (repo exists)
          return http.Response('{"full_name":"psquare99/reelhouse"}', 200);
        });

        final service = UpdateServiceImpl(
          client: mockClient,
          appVersion: '1.0.0',
        );
        final result = await service.checkForUpdate();

        expect(result.status, UpdateCheckStatus.releaseChannelEmpty);
        expect(result.isReleaseChannelEmpty, isTrue);
        expect(result.isUpToDate, isTrue);
        expect(result.hasUpdate, isFalse);
        expect(result.releaseInfo, isNull);
      },
    );

    // ── 8. HTTP 404 + repo missing → checkFailed ──────────────────────
    test(
      'returns checkFailed when 404 on both release and repo endpoints',
      () async {
        final mockClient = MockClient((_) async {
          return http.Response('{"message":"Not Found"}', 404);
        });

        final service = UpdateServiceImpl(
          client: mockClient,
          appVersion: '1.0.0',
        );
        final result = await service.checkForUpdate();

        expect(result.status, UpdateCheckStatus.checkFailed);
        expect(result.errorMessage, contains('Repository not found'));
        expect(result.hasUpdate, isFalse);
      },
    );

    // ── 9. HTTP 500 → checkFailed (not releaseChannelEmpty) ───────────
    test('returns checkFailed for server errors', () async {
      final mockClient = MockClient((_) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.hasUpdate, isFalse);
      expect(result.errorMessage, contains('500'));
    });

    // ── 10. Invalid JSON response ─────────────────────────────────────
    test('returns checkFailed for malformed JSON body', () async {
      final mockClient = MockClient((_) async {
        return http.Response('not json at all', 200);
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.errorMessage, contains('Unable to parse'));
    });

    // ── 11. Missing required fields ───────────────────────────────────
    test('returns checkFailed when required fields are missing', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({'tag_name': 'v1.0.0'}), // missing html_url, published_at
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '0.9.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.errorMessage, contains('Incomplete release data'));
    });

    // ── 12. JSON is not a Map ─────────────────────────────────────────
    test('returns checkFailed when response is a JSON array', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode([1, 2, 3]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.errorMessage, contains('Unexpected response format'));
    });

    // ── 13. Network failure ───────────────────────────────────────────
    test('returns checkFailed for network errors', () async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('Connection refused');
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.hasUpdate, isFalse);
    });

    // ── 14. html_url is propagated ────────────────────────────────────
    test('propagates html_url in release info', () async {
      final customUrl =
          'https://github.com/psquare99/reelhouse/releases/tag/2.0.0';
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: 'v2.0.0', htmlUrl: customUrl)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.updateAvailable);
      expect(result.releaseInfo!.htmlUrl, customUrl);
    });

    // ── 15. Convenience getters ───────────────────────────────────────
    test('convenience getters are consistent', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: 'v2.0.0')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.hasUpdate, isTrue);
      expect(result.isUpToDate, isFalse);
      expect(result.isReleaseChannelEmpty, isFalse);
    });
  });
}
