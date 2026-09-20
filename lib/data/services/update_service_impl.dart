/// Concrete [UpdateService] that queries the GitHub Releases API.
///
/// Uses an injected [http.Client] for testability — no singletons, no
/// global state, no background polling.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/services/update_service.dart';
import 'update_models.dart';

/// Semantic version parts parsed from a `"major.minor.patch"` string.
class _SemVer {
  final int major;
  final int minor;
  final int patch;

  const _SemVer(this.major, this.minor, this.patch);

  /// Returns `null` when the string cannot be parsed.
  static _SemVer? tryParse(String version) {
    // Strip a leading "v" or "V" if present.
    final cleaned = version.startsWith(RegExp(r'[vV]'))
        ? version.substring(1)
        : version;

    // Ignore build metadata after "+…" and pre-release after "-…".
    final core = cleaned.split(RegExp(r'[+\-]')).first;
    final parts = core.split('.');
    if (parts.length != 3) return null;

    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null)) return null;

    return _SemVer(nums[0]!, nums[1]!, nums[2]!);
  }

  /// Negative / zero / positive comparison.
  int compareTo(_SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}

/// Configuration constants for the GitHub Releases endpoint.
const String _githubOwner = 'psquare99';
const String _githubRepo = 'reelhouse';
const String _latestReleaseUrl =
    'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

/// Concrete implementation of [UpdateService].
///
/// Calls `GET /repos/{owner}/{repo}/releases/latest` on the public GitHub
/// API — no authentication required for public repositories.
class UpdateServiceImpl implements UpdateService {
  final http.Client _client;

  /// The application version string, typically read from `pubspec.yaml`.
  final String _appVersion;

  /// Optional override for the latest-release URL (useful in tests).
  final String latestReleaseUrl;

  /// Optional request timeout.
  final Duration timeout;

  UpdateServiceImpl({
    http.Client? client,
    String appVersion = '1.0.0',
    this.latestReleaseUrl = _latestReleaseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       // ignore: prefer_initializing_formals
       _appVersion = appVersion;

  @override
  String get currentVersion => _appVersion;

  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    final parsed = _SemVer.tryParse(_appVersion);
    if (parsed == null) {
      return const UpdateCheckResult.failed(
        'Unable to parse installed app version.',
      );
    }

    http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(latestReleaseUrl),
            headers: {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(timeout);
    } on SocketException {
      return const UpdateCheckResult.failed(
        'Network error. Check your internet connection and try again.',
      );
    } on TimeoutException {
      return const UpdateCheckResult.failed(
        'Request timed out. The GitHub API may be temporarily unavailable.',
      );
    } on http.ClientException {
      return const UpdateCheckResult.failed(
        'Network error. Check your internet connection and try again.',
      );
    } catch (e) {
      return UpdateCheckResult.failed('Unexpected error: $e');
    }

    // Handle non-2xx responses.
    if (response.statusCode != 200) {
      return UpdateCheckResult.failed(
        'GitHub API returned status ${response.statusCode}.',
      );
    }

    // Parse JSON payload.
    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      return const UpdateCheckResult.failed(
        'Unable to parse the GitHub API response.',
      );
    }

    if (json is! Map<String, dynamic>) {
      return const UpdateCheckResult.failed(
        'Unexpected response format from GitHub.',
      );
    }

    // Extract required fields.
    final tagName = json['tag_name'] as String?;
    final htmlUrl = json['html_url'] as String?;
    final publishedAt = json['published_at'] as String?;
    final body = json['body'] as String? ?? '';

    if (tagName == null || htmlUrl == null || publishedAt == null) {
      return const UpdateCheckResult.failed(
        'Incomplete release data from GitHub.',
      );
    }

    final remoteVersion = _SemVer.tryParse(tagName);
    if (remoteVersion == null) {
      return UpdateCheckResult.failed(
        'Unable to parse version from tag "$tagName".',
      );
    }

    final comparison = parsed.compareTo(remoteVersion);

    if (comparison < 0) {
      // Remote is newer — update available.
      final info = UpdateReleaseInfo(
        version: remoteVersion.toString(),
        tagName: tagName,
        publishedAt: publishedAt,
        htmlUrl: htmlUrl,
        body: body.length > 500 ? '${body.substring(0, 500)}…' : body,
      );
      return UpdateCheckResult.updateAvailable(info);
    } else if (comparison == 0) {
      return const UpdateCheckResult.upToDate();
    } else {
      return const UpdateCheckResult.aheadOfRelease();
    }
  }
}
