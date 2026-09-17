import 'filter_spec.dart';
import 'pagination_spec.dart';
import 'query_scope.dart';
import 'search_spec.dart';
import 'sort_fields.dart';
import 'sort_spec.dart';

/// Type-safe domain query contract for Collections.
///
/// Sections 6, 7, 22–24:
/// - Represents queries for user and smart collections.
class CollectionQuery {
  final SearchSpec? search;
  final CollectionFilter filter;
  final List<SortClause<CollectionSortField>> sort;
  final PaginationSpec? pagination;
  final QueryScope scope;

  const CollectionQuery({
    this.search,
    this.filter = CollectionFilter.empty,
    this.sort = const [
      SortClause(CollectionSortField.name, direction: SortDirection.asc),
    ],
    this.pagination,
    this.scope = QueryScope.all,
  });

  /// Factory for retrieving all collections in alphabetical order.
  factory CollectionQuery.all({
    PaginationSpec? pagination,
    List<SortClause<CollectionSortField>>? sort,
  }) => CollectionQuery(
    pagination: pagination,
    sort:
        sort ??
        const [
          SortClause(CollectionSortField.name, direction: SortDirection.asc),
        ],
  );

  /// Factory for searching collections by name.
  factory CollectionQuery.search(String query) => CollectionQuery(
    scope: QueryScope.search(query),
    search: SearchSpec(query: query),
    filter: CollectionFilter(nameQuery: query),
  );

  CollectionQuery copyWith({
    SearchSpec? search,
    CollectionFilter? filter,
    List<SortClause<CollectionSortField>>? sort,
    PaginationSpec? pagination,
    QueryScope? scope,
    bool clearSearch = false,
    bool clearPagination = false,
  }) {
    return CollectionQuery(
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
      other is CollectionQuery &&
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
      'CollectionQuery(search: $search, filter: $filter, sort: $sort, pagination: $pagination, scope: $scope)';

  static bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
