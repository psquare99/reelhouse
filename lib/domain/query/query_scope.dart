/// Contextual category or surface identifier for a library query.
///
/// Section 38 & 46–48:
/// - Represents semantic origin or high-level categorization of a query.
enum QueryScopeType {
  /// Unscoped library-wide catalogue.
  all,

  /// Curated user collection.
  collection,

  /// Personal favorites list.
  favorites,

  /// User watchlist.
  watchlist,

  /// Search results.
  search,

  /// Recently added / discovered media.
  recentlyAdded,

  /// Active playback in-progress queue.
  continueWatching,

  /// Unconsumed library titles.
  unwatched,

  /// Unidentified or ambiguous media needing user verification.
  needsVerification,

  /// Offline / local device storage items.
  offline,

  /// Custom or plugin-provided scope.
  custom;

  bool get isCollection => this == QueryScopeType.collection;
  bool get isSearch => this == QueryScopeType.search;
  bool get isSmartView =>
      this == QueryScopeType.continueWatching ||
      this == QueryScopeType.recentlyAdded ||
      this == QueryScopeType.favorites ||
      this == QueryScopeType.watchlist ||
      this == QueryScopeType.unwatched ||
      this == QueryScopeType.needsVerification ||
      this == QueryScopeType.offline;
}

/// Contextual scope descriptor for reusable queries and Smart Views.
///
/// Section 38:
/// - Provides domain context without forcing database schema mutations.
class QueryScope {
  final QueryScopeType type;
  final String? targetId;
  final String? label;

  const QueryScope(
    this.type, {
    this.targetId,
    this.label,
  });

  static const QueryScope all = QueryScope(QueryScopeType.all, label: 'All');
  static const QueryScope favorites = QueryScope(QueryScopeType.favorites, label: 'Favorites');
  static const QueryScope watchlist = QueryScope(QueryScopeType.watchlist, label: 'Watchlist');
  static const QueryScope recentlyAdded =
      QueryScope(QueryScopeType.recentlyAdded, label: 'Recently Added');
  static const QueryScope continueWatching =
      QueryScope(QueryScopeType.continueWatching, label: 'Continue Watching');
  static const QueryScope unwatched = QueryScope(QueryScopeType.unwatched, label: 'Unwatched');
  static const QueryScope needsVerification =
      QueryScope(QueryScopeType.needsVerification, label: 'Needs Verification');
  static const QueryScope offline = QueryScope(QueryScopeType.offline, label: 'Offline Library');

  factory QueryScope.collection(String collectionId, {String? label}) =>
      QueryScope(QueryScopeType.collection, targetId: collectionId, label: label ?? 'Collection');

  factory QueryScope.search(String query) =>
      QueryScope(QueryScopeType.search, targetId: query, label: 'Search "$query"');

  factory QueryScope.custom(String name, {String? targetId}) =>
      QueryScope(QueryScopeType.custom, targetId: targetId, label: name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryScope &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          targetId == other.targetId &&
          label == other.label;

  @override
  int get hashCode => Object.hash(type, targetId, label);

  @override
  String toString() => 'QueryScope($type, targetId: $targetId, label: $label)';
}
