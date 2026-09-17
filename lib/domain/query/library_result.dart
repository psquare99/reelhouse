import 'pagination_spec.dart';

/// Structured result set returned by library query operations.
///
/// Section 40:
/// - [items]: Typed result items (entities or read projections).
/// - [totalCount]: Total matching item count across all pages.
/// - [hasMore]: Whether subsequent pages exist beyond the current [pagination].
/// - [pagination]: Pagination parameters applied to this result set.
class LibraryResult<T> {
  final List<T> items;
  final int totalCount;
  final bool hasMore;
  final PaginationSpec? pagination;

  const LibraryResult({
    required this.items,
    required this.totalCount,
    this.hasMore = false,
    this.pagination,
  });

  /// Factory for an empty result set.
  static LibraryResult<T> empty<T>() =>
      const LibraryResult(items: [], totalCount: 0, hasMore: false);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  T operator [](int index) => items[index];

  /// Transforms each item in this result set using [mapper].
  LibraryResult<R> map<R>(R Function(T item) mapper) {
    return LibraryResult<R>(
      items: items.map(mapper).toList(),
      totalCount: totalCount,
      hasMore: hasMore,
      pagination: pagination,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryResult<T> &&
          runtimeType == other.runtimeType &&
          totalCount == other.totalCount &&
          hasMore == other.hasMore &&
          pagination == other.pagination &&
          _listEquals(items, other.items);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(items), totalCount, hasMore, pagination);

  @override
  String toString() =>
      'LibraryResult<$T>(items: ${items.length}, total: $totalCount, hasMore: $hasMore)';

  static bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
