/// Search scope/mode for query evaluation.
///
/// Section 8:
/// - TITLE: Matches against title fields only (canonical title and detected title).
/// - ALL: Matches across title fields, original title, and overview text.
enum SearchMode {
  /// Matches against title fields only (canonical title and detected title).
  title,

  /// Matches across title fields, original title, and overview text.
  all;

  bool get isTitleOnly => this == SearchMode.title;
  bool get isAllFields => this == SearchMode.all;
}

/// Type-safe search specification for library queries.
///
/// Section 8 & 9:
/// - Operates offline without network access.
/// - Case-insensitive matching.
/// - Searches canonical title and filesystem detected title.
/// - Read-only constraint; never mutates metadata or invokes identification.
class SearchSpec {
  final String query;
  final SearchMode mode;

  const SearchSpec({
    required this.query,
    this.mode = SearchMode.all,
  });

  /// Factory for empty search.
  static const SearchSpec empty = SearchSpec(query: '', mode: SearchMode.all);

  /// Whether this search specification has a non-empty trimmed query string.
  bool get isNotEmpty => query.trim().isNotEmpty;

  /// Whether this search specification is empty or whitespace-only.
  bool get isEmpty => query.trim().isEmpty;

  /// Normalized trimmed query string.
  String get trimmedQuery => query.trim();

  SearchSpec copyWith({
    String? query,
    SearchMode? mode,
  }) {
    return SearchSpec(
      query: query ?? this.query,
      mode: mode ?? this.mode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSpec &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          mode == other.mode;

  @override
  int get hashCode => Object.hash(query, mode);

  @override
  String toString() => 'SearchSpec(query: "$query", mode: $mode)';
}
