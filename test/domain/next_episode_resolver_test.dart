import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/models/availability_status.dart';
import 'package:reelhouse/domain/models/watch_state.dart';
import 'package:reelhouse/domain/query/query_projections.dart';
import 'package:reelhouse/domain/services/next_episode_resolver.dart';

void main() {
  const resolver = NextEpisodeResolver();

  EpisodeLibraryItem createEp({
    required String id,
    required int seasonNumber,
    required int episodeNumber,
    WatchState watchState = WatchState.unwatched,
  }) {
    return EpisodeLibraryItem(
      id: id,
      seasonId: 'season-$seasonNumber',
      showId: 'show-1',
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      name: 'Episode $episodeNumber',
      watchState: watchState,
      availability: AvailabilityStatus.availableLocally,
    );
  }

  group('NextEpisodeResolver', () {
    test('returns null for empty episode list', () {
      expect(resolver.resolveNextEpisode([]), isNull);
    });

    test('returns first episode (S01E01) when all episodes are unwatched', () {
      final episodes = [
        createEp(id: 'e2', seasonNumber: 1, episodeNumber: 2),
        createEp(id: 'e1', seasonNumber: 1, episodeNumber: 1),
        createEp(id: 'e3', seasonNumber: 1, episodeNumber: 3),
      ];

      final next = resolver.resolveNextEpisode(episodes);
      expect(next, isNotNull);
      expect(next!.id, 'e1');
      expect(next.seasonNumber, 1);
      expect(next.episodeNumber, 1);
    });

    test('prioritizes in-progress episode over unwatched earlier or later episodes', () {
      final episodes = [
        createEp(
          id: 'e1',
          seasonNumber: 1,
          episodeNumber: 1,
          watchState: WatchState.watched,
        ),
        createEp(
          id: 'e2',
          seasonNumber: 1,
          episodeNumber: 2,
          watchState: WatchState.inProgress,
        ),
        createEp(
          id: 'e3',
          seasonNumber: 1,
          episodeNumber: 3,
          watchState: WatchState.unwatched,
        ),
      ];

      final next = resolver.resolveNextEpisode(episodes);
      expect(next, isNotNull);
      expect(next!.id, 'e2');
      expect(next.watchState, WatchState.inProgress);
    });

    test('progresses across seasons when Season 1 is fully watched', () {
      final episodes = [
        createEp(
          id: 's1e1',
          seasonNumber: 1,
          episodeNumber: 1,
          watchState: WatchState.watched,
        ),
        createEp(
          id: 's1e2',
          seasonNumber: 1,
          episodeNumber: 2,
          watchState: WatchState.watched,
        ),
        createEp(
          id: 's2e1',
          seasonNumber: 2,
          episodeNumber: 1,
          watchState: WatchState.unwatched,
        ),
        createEp(
          id: 's2e2',
          seasonNumber: 2,
          episodeNumber: 2,
          watchState: WatchState.unwatched,
        ),
      ];

      final next = resolver.resolveNextEpisode(episodes);
      expect(next, isNotNull);
      expect(next!.id, 's2e1');
      expect(next.seasonNumber, 2);
      expect(next.episodeNumber, 1);
    });

    test('returns null when all regular episodes are watched', () {
      final episodes = [
        createEp(
          id: 's1e1',
          seasonNumber: 1,
          episodeNumber: 1,
          watchState: WatchState.watched,
        ),
        createEp(
          id: 's1e2',
          seasonNumber: 1,
          episodeNumber: 2,
          watchState: WatchState.watched,
        ),
      ];

      expect(resolver.resolveNextEpisode(episodes), isNull);
    });

    test('strictly excludes Season -1 Extras from next episode resolution', () {
      // Regular episodes: all watched
      // Extra: unwatched
      final episodes = [
        createEp(
          id: 's1e1',
          seasonNumber: 1,
          episodeNumber: 1,
          watchState: WatchState.watched,
        ),
        createEp(
          id: 'extra1',
          seasonNumber: -1,
          episodeNumber: 1,
          watchState: WatchState.unwatched,
        ),
      ];

      // Since all regular episodes are watched, resolver must return null and NOT the extra
      expect(resolver.resolveNextEpisode(episodes), isNull);
    });

    test('ignores in-progress extra when regular episodes exist', () {
      final episodes = [
        createEp(
          id: 's1e1',
          seasonNumber: 1,
          episodeNumber: 1,
          watchState: WatchState.unwatched,
        ),
        createEp(
          id: 'extra1',
          seasonNumber: -1,
          episodeNumber: 1,
          watchState: WatchState.inProgress,
        ),
      ];

      final next = resolver.resolveNextEpisode(episodes);
      expect(next, isNotNull);
      expect(next!.id, 's1e1');
      expect(next.seasonNumber, 1);
    });
  });
}
