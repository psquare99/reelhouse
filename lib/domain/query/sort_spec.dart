/// Direction for query sorting.
///
/// Section 11:
/// - ASC: Ascending (A-Z, oldest first, lowest to highest).
/// - DESC: Descending (Z-A, newest first, highest to lowest).
enum SortDirection {
  asc,
  desc;

  bool get isAscending => this == SortDirection.asc;
  bool get isDescending => this == SortDirection.desc;
}

/// Null ordering policy for deterministic sorting when metadata fields may be null.
///
/// Section 12:
/// - Default REELHOUSE rule: NULL values appear last in both ASC and DESC order.
enum NullsOrder {
  /// Null values appear at the beginning of the result set.
  first,

  /// Null values appear at the end of the result set (default REELHOUSE policy).
  last;

  bool get isFirst => this == NullsOrder.first;
  bool get isLast => this == NullsOrder.last;
}

/// A single typed sorting clause specifying an entity field, direction, and null placement.
///
/// Section 11 & 12:
/// - Type-safe [field] avoids raw SQL string leakage.
/// - Deterministic [nullsOrder] defaults to [NullsOrder.last].
class SortClause<F> {
  final F field;
  final SortDirection direction;
  final NullsOrder nullsOrder;

  const SortClause(
    this.field, {
    this.direction = SortDirection.asc,
    this.nullsOrder = NullsOrder.last,
  });

  bool get isAscending => direction.isAscending;
  bool get isDescending => direction.isDescending;
  NullsOrder get nulls => nullsOrder;

  SortClause<F> copyWith({
    F? field,
    SortDirection? direction,
    NullsOrder? nullsOrder,
  }) {
    return SortClause<F>(
      field ?? this.field,
      direction: direction ?? this.direction,
      nullsOrder: nullsOrder ?? this.nullsOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortClause<F> &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          direction == other.direction &&
          nullsOrder == other.nullsOrder;

  @override
  int get hashCode => Object.hash(field, direction, nullsOrder);

  @override
  String toString() => 'SortClause($field, $direction, nulls: $nullsOrder)';
}
