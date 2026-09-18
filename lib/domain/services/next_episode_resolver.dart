import '../models/watch_state.dart';
import '../query/query_projections.dart';

/// Pure domain resolver for determining the appropriate "Next Episode" to watch for a TV Show.
///
/// Rules:
/// - Excludes Extras (`seasonNumber < 0`). Extras are bonus materials and must NEVER be resolved as Next Episode.
/// - Prioritizes currently `IN_PROGRESS` episodes across the series (resume playback).
/// - If no episode is in progress, finds the earliest `UNWATCHED` episode in season/episode order.
/// - If all canonical episodes are `WATCHED`, returns `null`.
class NextEpisodeResolver {
  const NextEpisodeResolver();

  /// Resolves the next episode from a flat list of episodes belonging to a TV show.
  ///
  /// Episodes may be in any order and may contain bonus/extras content.
  EpisodeLibraryItem? resolveNextEpisode(List<EpisodeLibraryItem> episodes) {
    // 1. Exclude extras (seasonNumber < 0)
    final canonicalEpisodes = episodes
        .where((e) => e.seasonNumber >= 0)
        .toList();
    if (canonicalEpisodes.isEmpty) return null;

    // 2. Sort episodes canonical by seasonNumber ASC, episodeNumber ASC
    canonicalEpisodes.sort((a, b) {
      final sComp = a.seasonNumber.compareTo(b.seasonNumber);
      if (sComp != 0) return sComp;
      return a.episodeNumber.compareTo(b.episodeNumber);
    });

    // 3. First check: Is there an in-progress episode? (Resume current episode)
    for (final ep in canonicalEpisodes) {
      if (ep.watchState == WatchState.inProgress) {
        return ep;
      }
    }

    // 4. Second check: Find the first unwatched episode
    for (final ep in canonicalEpisodes) {
      if (ep.watchState == WatchState.unwatched) {
        return ep;
      }
    }

    // 5. All canonical episodes are watched
    return null;
  }
}
