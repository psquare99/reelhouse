import 'filter_spec.dart';
import 'pagination_spec.dart';
import 'query_scope.dart';
import 'search_spec.dart';
import 'sort_fields.dart';
import 'sort_spec.dart';
import '../models/identification_status.dart';
import '../models/watch_state.dart';

/// Type-safe domain query contract for TV Shows.
///
/// Sections 6, 7, 13–15, 29–48:
/// - UI-independent query specification.
/// - Composes search, filters (including derived watch state), sorting, pagination, and scope context.
class TvShowQuery {
  final SearchSpec? search;
  final TvShowFilter filter;
  final List<SortClause<TvShowSortField>> sort;
  final PaginationSpec? pagination;
  final QueryScope scope;

  const TvShowQuery({
    this.search,
    this.filter = TvShowFilter.empty,
    this.sort = const [
      SortClause(TvShowSortField.title, direction: SortDirection.asc),
    ],
    this.pagination,
    this.scope = QueryScope.all,
  });

  /// Factory for standard library-wide TV show catalogue.
  factory TvShowQuery.all({
    PaginationSpec? pagination,
    List<SortClause<TvShowSortField>>? sort,
  }) => TvShowQuery(
    pagination: pagination,
    sort:
        sort ??
        const [SortClause(TvShowSortField.title, direction: SortDirection.asc)],
  );

  /// Factory for Recently Added Smart View.
  factory TvShowQuery.recentlyAdded({int? limit}) => TvShowQuery(
    scope: QueryScope.recentlyAdded,
    sort: const [
      SortClause(TvShowSortField.createdAt, direction: SortDirection.desc),
    ],
    pagination: limit != null ? PaginationSpec(limit: limit) : null,
  );

  /// Factory for Favorites Smart View.
  factory TvShowQuery.favorites() => const TvShowQuery(
    scope: QueryScope.favorites,
    filter: TvShowFilter(isFavorite: true),
  );

  /// Factory for Watchlist Smart View.
  factory TvShowQuery.watchlist() => const TvShowQuery(
    scope: QueryScope.watchlist,
    filter: TvShowFilter(isWatchlist: true),
  );

  /// Factory for Unwatched Smart View.
  ///
  /// Matches shows whose derived watch state is unwatched.
  factory TvShowQuery.unwatched() => const TvShowQuery(
    scope: QueryScope.unwatched,
    filter: TvShowFilter(watchStates: {WatchState.unwatched}),
  );

  /// Factory for Needs Verification Smart View.
  factory TvShowQuery.needsVerification() => const TvShowQuery(
    scope: QueryScope.needsVerification,
    filter: TvShowFilter(
      metadataStatuses: {
        IdentificationStatus.pending,
        IdentificationStatus.needsVerification,
      },
    ),
  );

  /// Factory for Offline Library Smart View.
  factory TvShowQuery.offline() => const TvShowQuery(
    scope: QueryScope.offline,
    filter: TvShowFilter(availability: AvailabilityFilter.available),
  );

  /// Factory for Collection-scoped TV Show Query.
  factory TvShowQuery.forCollection(String collectionId, {String? label}) =>
      TvShowQuery(
        scope: QueryScope.collection(collectionId, label: label),
        filter: TvShowFilter(collectionId: collectionId),
      );

  /// Factory for TV Show Search Query.
  factory TvShowQuery.search(
    String query, {
    SearchMode mode = SearchMode.title,
  }) => TvShowQuery(
    scope: QueryScope.search(query),
    search: SearchSpec(query: query, mode: mode),
  );

  TvShowQuery copyWith({
    SearchSpec? search,
    TvShowFilter? filter,
    List<SortClause<TvShowSortField>>? sort,
    PaginationSpec? pagination,
    QueryScope? scope,
    bool clearSearch = false,
    bool clearPagination = false,
  }) {
    return TvShowQuery(
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
      other is TvShowQuery &&
          runtimeType == other.runtimeType &&
          search == other.search &&
          filter == other.filter &&
          pagination == other.pagination &&
          scope == other.scope &&
          _listEquals(sort, other.sort);

  @override
  int get hashCode =>
      Object.hash(search, filter, Object.hashAll(sort), pagination, scope);

  @override
  String toString() =>
      'TvShowQuery(search: $search, filter: $filter, sort: $sort, pagination: $pagination, scope: $scope)';

  static bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
