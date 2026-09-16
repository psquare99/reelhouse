import 'package:drift/drift.dart' hide NullsOrder;

import '../../../domain/query/collection_query.dart';
import '../../../domain/query/library_result.dart';
import '../../../domain/query/sort_fields.dart';
import '../../../domain/query/sort_spec.dart';
import '../database.dart';

/// Database Query Engine for translating [CollectionQuery] into optimized Drift / SQLite queries.
class CollectionQueryEngine {
  final AppDatabase db;

  const CollectionQueryEngine(this.db);

  /// Executes a one-shot query for collections returning a [LibraryResult] of [Collection].
  Future<LibraryResult<Collection>> query(CollectionQuery query) async {
    final queryPlan = _buildQueryPlan(query);

    final dataRows = await db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {db.collections},
        )
        .get();

    final countRow = await db
        .customSelect(
          queryPlan.countSql,
          variables: queryPlan.countVariables,
          readsFrom: {db.collections},
        )
        .getSingle();

    final totalCount = countRow.read<int>('total');
    final items = dataRows.map(_mapRowToCollection).toList();

    return LibraryResult<Collection>(
      items: items,
      totalCount: totalCount,
      hasMore: query.pagination != null
          ? (query.pagination!.offset + items.length) < totalCount
          : false,
      pagination: query.pagination,
    );
  }

  /// Returns a reactive stream of [LibraryResult] for collections.
  Stream<LibraryResult<Collection>> watch(CollectionQuery query) {
    final queryPlan = _buildQueryPlan(query);

    return db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {db.collections},
        )
        .watch()
        .asyncMap((dataRows) async {
          final countRow = await db
              .customSelect(
                queryPlan.countSql,
                variables: queryPlan.countVariables,
                readsFrom: {db.collections},
              )
              .getSingle();

          final totalCount = countRow.read<int>('total');
          final items = dataRows.map(_mapRowToCollection).toList();

          return LibraryResult<Collection>(
            items: items,
            totalCount: totalCount,
            hasMore: query.pagination != null
                ? (query.pagination!.offset + items.length) < totalCount
                : false,
            pagination: query.pagination,
          );
        });
  }

  _CollectionQueryPlan _buildQueryPlan(CollectionQuery query) {
    final whereClauses = <String>[];
    final whereVariables = <Variable>[];

    // 1. Search spec
    if (query.search != null && query.search!.isNotEmpty) {
      final term = '%${query.search!.trimmedQuery.toLowerCase()}%';
      whereClauses.add('(LOWER(c.name) LIKE ? OR LOWER(COALESCE(c.overview, \'\')) LIKE ?)');
      whereVariables.add(Variable<String>(term));
      whereVariables.add(Variable<String>(term));
    }

    // 2. Filter nameQuery
    if (query.filter.nameQuery != null && query.filter.nameQuery!.trim().isNotEmpty) {
      final term = '%${query.filter.nameQuery!.trim().toLowerCase()}%';
      whereClauses.add('LOWER(c.name) LIKE ?');
      whereVariables.add(Variable<String>(term));
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final countSql = 'SELECT COUNT(*) AS total FROM collections c $whereSql';
    final countVariables = List<Variable>.from(whereVariables);

    final orderTerms = <String>[];
    for (final sortClause in query.sort) {
      final colExpr = _mapSortFieldToSql(sortClause.field);
      final dir = sortClause.direction == SortDirection.asc ? 'ASC' : 'DESC';
      final nulls = sortClause.nullsOrder == NullsOrder.first ? 'NULLS FIRST' : 'NULLS LAST';
      orderTerms.add('$colExpr $dir $nulls');
    }
    orderTerms.add('c.id ASC');
    final orderSql = 'ORDER BY ${orderTerms.join(', ')}';

    final dataVariables = List<Variable>.from(whereVariables);
    var paginationSql = '';
    if (query.pagination != null) {
      paginationSql = 'LIMIT ? OFFSET ?';
      dataVariables.add(Variable<int>(query.pagination!.limit));
      dataVariables.add(Variable<int>(query.pagination!.offset));
    }

    final dataSql = '''
SELECT 
  c.id,
  c.name,
  c.overview,
  c.poster_path,
  c.created_at,
  c.updated_at
FROM collections c
$whereSql
$orderSql
$paginationSql
''';

    return _CollectionQueryPlan(
      dataSql: dataSql,
      dataVariables: dataVariables,
      countSql: countSql,
      countVariables: countVariables,
    );
  }

  String _mapSortFieldToSql(CollectionSortField field) {
    switch (field) {
      case CollectionSortField.name:
        return 'c.name COLLATE NOCASE';
      case CollectionSortField.createdAt:
        return 'c.created_at';
      case CollectionSortField.updatedAt:
        return 'c.updated_at';
    }
  }

  Collection _mapRowToCollection(QueryRow row) {
    return Collection(
      id: row.read<String>('id'),
      name: row.read<String>('name'),
      overview: row.readNullable<String>('overview'),
      posterPath: row.readNullable<String>('poster_path'),
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
    );
  }
}

class _CollectionQueryPlan {
  final String dataSql;
  final List<Variable> dataVariables;
  final String countSql;
  final List<Variable> countVariables;

  const _CollectionQueryPlan({
    required this.dataSql,
    required this.dataVariables,
    required this.countSql,
    required this.countVariables,
  });
}
