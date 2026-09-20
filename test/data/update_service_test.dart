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
    });

    // ── 3. Ahead of release (installed 1.2.0 > remote 1.1.0) ──────────
    test(
      'returns aheadOfRelease when installed version exceeds remote',
      () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode(_releaseJson(tagName: 'v1.1.0')),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = UpdateServiceImpl(
          client: mockClient,
          appVersion: '1.2.0',
        );
        final result = await service.checkForUpdate();

        expect(result.status, UpdateCheckStatus.aheadOfRelease);
        expect(result.hasUpdate, isFalse);
      },
    );

    // ── 4. Minor version bump detection ───────────────────────────────
    test(
      'detects minor version bump (remote 1.0.1 > installed 1.0.0)',
      () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode(_releaseJson(tagName: 'v1.0.1')),
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
        expect(result.releaseInfo!.version, '1.0.1');
      },
    );

    // ── 5. Major version bump detection ───────────────────────────────
    test(
      'detects major version bump (remote 2.0.0 > installed 1.9.9)',
      () async {
        final mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode(_releaseJson(tagName: 'v2.0.0')),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = UpdateServiceImpl(
          client: mockClient,
          appVersion: '1.9.9',
        );
        final result = await service.checkForUpdate();

        expect(result.status, UpdateCheckStatus.updateAvailable);
        expect(result.releaseInfo!.version, '2.0.0');
      },
    );

    // ── 6. Tag name without "v" prefix ────────────────────────────────
    test('handles tag_name without leading "v" (e.g. "1.1.0")', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: '1.1.0')),
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
      expect(result.releaseInfo!.tagName, '1.1.0');
      expect(result.releaseInfo!.version, '1.1.0');
    });

    // ── 7. Network error → checkFailed ────────────────────────────────
    test('returns checkFailed on SocketException (offline)', () async {
      final mockClient = MockClient((_) async {
        throw Exception('connection refused');
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, isNotEmpty);
    });

    // ── 8. HTTP 403 → checkFailed ─────────────────────────────────────
    test('returns checkFailed on HTTP 403 (rate-limited)', () async {
      final mockClient = MockClient((_) async {
        return http.Response('{"message":"rate limit exceeded"}', 403);
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.errorMessage, contains('403'));
    });

    // ── 9. Malformed JSON → checkFailed ───────────────────────────────
    test('returns checkFailed on malformed JSON response', () async {
      final mockClient = MockClient((_) async {
        return http.Response('not json at all', 200);
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: '1.0.0',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.errorMessage, contains('parse'));
    });

    // ── 10. Unparseable installed version → checkFailed ───────────────
    test('returns checkFailed when installed version is unparseable', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: 'v1.1.0')),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = UpdateServiceImpl(
        client: mockClient,
        appVersion: 'not-a-version',
      );
      final result = await service.checkForUpdate();

      expect(result.status, UpdateCheckStatus.checkFailed);
      expect(result.errorMessage, contains('parse'));
    });

    // ── currentVersion getter ─────────────────────────────────────────
    test('currentVersion returns the app version supplied at construction', () {
      final service = UpdateServiceImpl(appVersion: '1.2.3');
      expect(service.currentVersion, '1.2.3');
    });

    // ── Release notes truncation ──────────────────────────────────────
    test('truncates release body to 500 characters when longer', () async {
      final longBody = 'A' * 600;
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_releaseJson(tagName: 'v1.1.0', body: longBody)),
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
      expect(result.releaseInfo!.body.length, 501); // 500 + ellipsis
      expect(result.releaseInfo!.body.endsWith('…'), isTrue);
    });
  });
}
