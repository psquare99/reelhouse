/// Database-independent pagination specification.
///
/// Section 39:
/// - [limit]: Maximum number of items to return (must be > 0).
/// - [offset]: Number of items to skip from the beginning of the result set (must be >= 0).
class PaginationSpec {
  final int limit;
  final int offset;

  const PaginationSpec({
    required this.limit,
    this.offset = 0,
  })  : assert(limit > 0, 'limit must be greater than 0'),
        assert(offset >= 0, 'offset must be non-negative');

  /// Creates a pagination specification for the first page with a given [limit].
  const PaginationSpec.firstPage({this.limit = 50}) : offset = 0;

  /// Returns a new [PaginationSpec] pointing to the next consecutive page.
  PaginationSpec nextPage() => PaginationSpec(limit: limit, offset: offset + limit);

  /// Returns a new [PaginationSpec] pointing to the previous page (clamped to offset 0).
  PaginationSpec previousPage() =>
      PaginationSpec(limit: limit, offset: offset >= limit ? offset - limit : 0);

  /// Current zero-indexed page number.
  int get pageIndex => offset ~/ limit;

  /// Current 1-indexed human-readable page number.
  int get pageNumber => pageIndex + 1;

  PaginationSpec copyWith({
    int? limit,
    int? offset,
  }) {
    return PaginationSpec(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginationSpec &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(limit, offset);

  @override
  String toString() => 'PaginationSpec(limit: $limit, offset: $offset, page: $pageNumber)';
}
