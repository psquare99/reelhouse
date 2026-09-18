import 'filter_spec.dart';
import 'pagination_spec.dart';
import 'query_scope.dart';
import 'search_spec.dart';
import 'sort_fields.dart';
import 'sort_spec.dart';
import '../models/watch_state.dart';

/// Type-safe domain query contract for Episodes.
///
/// Sections 6, 7, 19–21, 29–48:
/// - Represents queries for episodes across a season, show, or playback queue.
class EpisodeQuery {
  final String? seasonId;
  final String? showId;
  final SearchSpec? search;
  final EpisodeFilter filter;
  final List<SortClause<EpisodeSortField>> sort;
  final PaginationSpec? pagination;
  final QueryScope scope;

  const EpisodeQuery({
    this.seasonId,
    this.showId,
    this.search,
    this.filter = EpisodeFilter.empty,
    this.sort = const [
      SortClause(EpisodeSortField.seasonNumber, direction: SortDirection.asc),
      SortClause(EpisodeSortField.episodeNumber, direction: SortDirection.asc),
    ],
    this.pagination,
    this.scope = QueryScope.all,
  });

  /// Factory for retrieving all episodes of a specific season.
  factory EpisodeQuery.forSeason(
    String seasonId, {
    String? showId,
    int? seasonNumber,
  }) => EpisodeQuery(
    seasonId: seasonId,
    showId: showId,
    filter: EpisodeFilter(
      seasonId: seasonId,
      showId: showId,
      seasonNumber: seasonNumber,
    ),
    sort: const [
      SortClause(EpisodeSortField.episodeNumber, direction: SortDirection.asc),
    ],
  );

  /// Factory for in-progress Continue Watching episode queue.
  factory EpisodeQuery.continueWatching({int? limit}) => EpisodeQuery(
    scope: QueryScope.continueWatching,
    filter: const EpisodeFilter(watchStates: {WatchState.inProgress}),
    sort: const [
      SortClause(EpisodeSortField.createdAt, direction: SortDirection.desc),
    ],
    pagination: limit != null ? PaginationSpec(limit: limit) : null,
  );

  /// Factory for Recently Played episode queue.
  factory EpisodeQuery.recentlyPlayed({int? limit}) => EpisodeQuery(
    scope: QueryScope.recentlyPlayed,
    filter: const EpisodeFilter(hasBeenPlayed: true),
    sort: const [
      SortClause(EpisodeSortField.lastPlayedAt, direction: SortDirection.desc),
    ],
    pagination: limit != null ? PaginationSpec(limit: limit) : null,
  );

  /// Factory for Episode Search Query.
  factory EpisodeQuery.search(
    String query, {
    SearchMode mode = SearchMode.title,
  }) => EpisodeQuery(
    scope: QueryScope.search(query),
    search: SearchSpec(query: query, mode: mode),
  );

  EpisodeQuery copyWith({
    String? seasonId,
    String? showId,
    SearchSpec? search,
    EpisodeFilter? filter,
    List<SortClause<EpisodeSortField>>? sort,
    PaginationSpec? pagination,
    QueryScope? scope,
    bool clearSeasonId = false,
    bool clearShowId = false,
    bool clearSearch = false,
    bool clearPagination = false,
  }) {
    return EpisodeQuery(
      seasonId: clearSeasonId ? null : (seasonId ?? this.seasonId),
      showId: clearShowId ? null : (showId ?? this.showId),
      search: clearSearch ? null : (search ?? this.search),
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      pagination: clearPagination ? null : (pagination ?? this.pagination),
      scope: scope ?? this.scope,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeQuery &&
          runtimeType == other.runtimeType &&
          seasonId == other.seasonId &&
          showId == other.showId &&
          search == other.search &&
          filter == other.filter &&
          pagination == other.pagination &&
          scope == other.scope &&
          _listEquals(sort, other.sort);

  @override
  int get hashCode => Object.hash(
    seasonId,
    showId,
    search,
    filter,
    Object.hashAll(sort),
    pagination,
    scope,
  );

  @override
  String toString() =>
      'EpisodeQuery(seasonId: $seasonId, showId: $showId, search: $search, filter: $filter, sort: $sort, pagination: $pagination, scope: $scope)';

  static bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
