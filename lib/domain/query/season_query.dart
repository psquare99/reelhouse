import 'filter_spec.dart';
import 'sort_fields.dart';
import 'sort_spec.dart';

/// Type-safe domain query contract for TV Seasons.
///
/// Sections 6, 7, 16–18:
/// - Represents query criteria for seasons, typically scoped to a parent show.
class SeasonQuery {
  final String? showId;
  final SeasonFilter filter;
  final List<SortClause<SeasonSortField>> sort;

  const SeasonQuery({
    this.showId,
    this.filter = SeasonFilter.empty,
    this.sort = const [
      SortClause(SeasonSortField.seasonNumber, direction: SortDirection.asc),
    ],
  });

  /// Factory for retrieving all seasons of a specific TV show in canonical order.
  factory SeasonQuery.forShow(String showId) => SeasonQuery(
    showId: showId,
    filter: SeasonFilter(showId: showId),
    sort: const [
      SortClause(SeasonSortField.seasonNumber, direction: SortDirection.asc),
    ],
  );

  SeasonQuery copyWith({
    String? showId,
    SeasonFilter? filter,
    List<SortClause<SeasonSortField>>? sort,
  }) {
    return SeasonQuery(
      showId: showId ?? this.showId,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonQuery &&
          runtimeType == other.runtimeType &&
          showId == other.showId &&
          filter == other.filter &&
          _listEquals(sort, other.sort);

  @override
  int get hashCode => Object.hash(showId, filter, Object.hashAll(sort));

  @override
  String toString() =>
      'SeasonQuery(showId: $showId, filter: $filter, sort: $sort)';

  static bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
