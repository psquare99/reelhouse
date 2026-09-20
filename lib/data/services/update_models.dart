/// Models for the GitHub Releases update-check feature (RC.7).
library;

/// The semantic result of an update check against the GitHub Releases API.
enum UpdateCheckStatus {
  /// A newer release is available.
  updateAvailable,

  /// The installed version matches the latest published release.
  upToDate,

  /// The installed version is newer than the latest published release.
  aheadOfRelease,

  /// The network request failed or the API returned an unexpected response.
  checkFailed,
}

/// Immutable snapshot of release information returned by GitHub.
class UpdateReleaseInfo {
  /// Semantic version string (e.g. `"1.2.3"`), always leading-v-normalised.
  final String version;

  /// The `tag_name` from the GitHub release payload.
  final String tagName;

  /// ISO-8601 publication timestamp.
  final String publishedAt;

  /// Full public URL of the release page.
  final String htmlUrl;

  /// Short markdown body / release notes (first 500 chars recommended).
  final String body;

  const UpdateReleaseInfo({
    required this.version,
    required this.tagName,
    required this.publishedAt,
    required this.htmlUrl,
    required this.body,
  });

  @override
  String toString() =>
      'UpdateReleaseInfo(version: $version, tag: $tagName, url: $htmlUrl)';
}

/// Full result returned by [UpdateService.checkForUpdate].
class UpdateCheckResult {
  final UpdateCheckStatus status;
  final UpdateReleaseInfo? releaseInfo;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.status,
    this.releaseInfo,
    this.errorMessage,
  });

  /// Convenience: true when status is [UpdateCheckStatus.updateAvailable].
  bool get hasUpdate => status == UpdateCheckStatus.updateAvailable;

  const UpdateCheckResult.updateAvailable(UpdateReleaseInfo info)
    : status = UpdateCheckStatus.updateAvailable,
      releaseInfo = info,
      errorMessage = null;

  const UpdateCheckResult.upToDate()
    : status = UpdateCheckStatus.upToDate,
      releaseInfo = null,
      errorMessage = null;

  const UpdateCheckResult.aheadOfRelease()
    : status = UpdateCheckStatus.aheadOfRelease,
      releaseInfo = null,
      errorMessage = null;

  const UpdateCheckResult.failed(String message)
    : status = UpdateCheckStatus.checkFailed,
      releaseInfo = null,
      errorMessage = message;

  @override
  String toString() =>
      'UpdateCheckResult(status: $status, release: $releaseInfo, error: $errorMessage)';
}
