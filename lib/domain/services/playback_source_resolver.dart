import '../models/playback_resolution.dart';
import 'availability_resolver.dart';

/// Evaluates media sources against the strictly defined playback priority:
///
/// Priority 1: Device-local copy (`PLAY OFFLINE`)
/// Priority 2: Connected original removable media (`PLAY`)
/// Priority 3: Neither available (`CONNECT DISK`)
class PlaybackSourceResolver {
  const PlaybackSourceResolver();

  PlaybackResolution resolve(List<SourceCheckInfo> sources) {
    if (sources.isEmpty) {
      return const PlaybackResolution(action: PlaybackAction.connectDisk);
    }

    // 1. Device-local copy (prefer if exists and available)
    for (final source in sources) {
      if (source.sourceType == 'localDevice' && source.isSourceAvailable) {
        return PlaybackResolution(
          action: PlaybackAction.playOffline,
          selectedSourceId: source.sourceId,
          storageName: source.storageName,
        );
      }
    }

    // 2. Connected original media
    for (final source in sources) {
      if (source.sourceType == 'removableStorage' &&
          source.isEffectivelyAvailable) {
        return PlaybackResolution(
          action: PlaybackAction.play,
          selectedSourceId: source.sourceId,
          storageName: source.storageName,
        );
      }
    }

    // 3. Neither available - show CONNECT [STORAGE_NAME]
    final primaryExternal = sources.firstWhere(
      (s) => s.sourceType == 'removableStorage',
      orElse: () => sources.first,
    );

    return PlaybackResolution(
      action: PlaybackAction.connectDisk,
      storageName: primaryExternal.storageName,
    );
  }
}
