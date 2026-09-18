import 'filter_spec.dart';
import 'pagination_spec.dart';
import 'query_scope.dart';
import 'search_spec.dart';
import 'sort_fields.dart';
import 'sort_spec.dart';
import '../models/identification_status.dart';
import '../models/watch_state.dart';

/// Type-safe domain query contract for Movies.
///
/// Sections 6, 7, 10–12, 29–48:
/// - UI-independent query specification.
/// - Composes search, filters, multi-field sorting, pagination, and scope context.
class MovieQuery {
  final SearchSpec? search;
  final MovieFilter filter;
  final List<SortClause<MovieSortField>> sort;
  final PaginationSpec? pagination;
  final QueryScope scope;

  const MovieQuery({
    this.search,
    this.filter = MovieFilter.empty,
    this.sort = const [
      SortClause(MovieSortField.title, direction: SortDirection.asc),
    ],
    this.pagination,
    this.scope = QueryScope.all,
  });

  /// Factory for standard library-wide movie list.
  factory MovieQuery.all({
    PaginationSpec? pagination,
    List<SortClause<MovieSortField>>? sort,
  }) => MovieQuery(
    pagination: pagination,
    sort:
        sort ??
        const [SortClause(MovieSortField.title, direction: SortDirection.asc)],
  );

  /// Factory for Recently Added Smart View.
  factory MovieQuery.recentlyAdded({int? limit}) => MovieQuery(
    scope: QueryScope.recentlyAdded,
    sort: const [
      SortClause(MovieSortField.createdAt, direction: SortDirection.desc),
    ],
    pagination: limit != null ? PaginationSpec(limit: limit) : null,
  );

  /// Factory for Recently Played Smart View.
  factory MovieQuery.recentlyPlayed({int? limit}) => MovieQuery(
    scope: QueryScope.recentlyPlayed,
    filter: const MovieFilter(hasBeenPlayed: true),
    sort: const [
      SortClause(MovieSortField.lastPlayedAt, direction: SortDirection.desc),
    ],
    pagination: limit != null ? PaginationSpec(limit: limit) : null,
  );

  /// Factory for Continue Watching Smart View.
  factory MovieQuery.continueWatching({int? limit}) => MovieQuery(
    scope: QueryScope.continueWatching,
    filter: const MovieFilter(watchStates: {WatchState.inProgress}),
    sort: const [
      SortClause(MovieSortField.updatedAt, direction: SortDirection.desc),
    ],
    pagination: limit != null ? PaginationSpec(limit: limit) : null,
  );

  /// Factory for Favorites Smart View.
  factory MovieQuery.favorites() => const MovieQuery(
    scope: QueryScope.favorites,
    filter: MovieFilter(isFavorite: true),
  );

  /// Factory for Watchlist Smart View.
  factory MovieQuery.watchlist() => const MovieQuery(
    scope: QueryScope.watchlist,
    filter: MovieFilter(isWatchlist: true),
  );

  /// Factory for Unwatched Smart View.
  factory MovieQuery.unwatched() => const MovieQuery(
    scope: QueryScope.unwatched,
    filter: MovieFilter(watchStates: {WatchState.unwatched}),
  );

  /// Factory for Needs Verification Smart View.
  factory MovieQuery.needsVerification() => const MovieQuery(
    scope: QueryScope.needsVerification,
    filter: MovieFilter(
      metadataStatuses: {
        IdentificationStatus.pending,
        IdentificationStatus.needsVerification,
      },
    ),
  );

  /// Factory for Offline Library Smart View.
  factory MovieQuery.offline() => const MovieQuery(
    scope: QueryScope.offline,
    filter: MovieFilter(availability: AvailabilityFilter.available),
  );

  /// Factory for Collection-scoped Movie Query.
  factory MovieQuery.forCollection(String collectionId, {String? label}) =>
      MovieQuery(
        scope: QueryScope.collection(collectionId, label: label),
        filter: MovieFilter(collectionId: collectionId),
      );

  /// Factory for Movie Search Query.
  factory MovieQuery.search(
    String query, {
    SearchMode mode = SearchMode.title,
  }) => MovieQuery(
    scope: QueryScope.search(query),
    search: SearchSpec(query: query, mode: mode),
  );

  MovieQuery copyWith({
    SearchSpec? search,
    MovieFilter? filter,
    List<SortClause<MovieSortField>>? sort,
    PaginationSpec? pagination,
    QueryScope? scope,
    bool clearSearch = false,
    bool clearPagination = false,
  }) {
    return MovieQuery(
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
      other is MovieQuery &&
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
      'MovieQuery(search: $search, filter: $filter, sort: $sort, pagination: $pagination, scope: $scope)';

  static bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
