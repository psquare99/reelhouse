/// Abstract contract for the GitHub Releases update-check service (RC.7).
///
/// Implementations are expected to be stateless — no polling, no caching,
/// no background scheduling. The caller (Settings UI) owns the lifecycle.
library;

import '../../data/services/update_models.dart';

abstract class UpdateService {
  /// Queries the GitHub Releases API for the latest published release
  /// and compares it against the installed app version.
  ///
  /// Returns an [UpdateCheckResult] whose [UpdateCheckResult.status] field
  /// indicates whether an update is available, the app is already up-to-date,
  /// the app is ahead of the published release, or the check failed.
  ///
  /// This method is idempotent and safe to call repeatedly — it performs
  /// a single HTTP GET each time with no side-effects.
  Future<UpdateCheckResult> checkForUpdate();

  /// The application version string read from pubspec.yaml (e.g. `"1.0.0"`).
  ///
  /// Exposed so the caller can display it without a separate import.
  String get currentVersion;
}
