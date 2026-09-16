import 'package:drift/drift.dart' hide NullsOrder;

import '../../../domain/query/library_result.dart';
import '../../../domain/query/season_query.dart';
import '../../../domain/query/sort_fields.dart';
import '../../../domain/query/sort_spec.dart';
import '../database.dart';

/// Database Query Engine for translating [SeasonQuery] into optimized Drift / SQLite queries.
class SeasonQueryEngine {
  final AppDatabase db;

  const SeasonQueryEngine(this.db);

  /// Executes a one-shot query for seasons returning a [LibraryResult] of [Season].
  Future<LibraryResult<Season>> query(SeasonQuery query) async {
    final queryPlan = _buildQueryPlan(query);

    final dataRows = await db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {db.seasons},
        )
        .get();

    final countRow = await db
        .customSelect(
          queryPlan.countSql,
          variables: queryPlan.countVariables,
          readsFrom: {db.seasons},
        )
        .getSingle();

    final totalCount = countRow.read<int>('total');
    final items = dataRows.map(_mapRowToSeason).toList();

    return LibraryResult<Season>(
      items: items,
      totalCount: totalCount,
      hasMore: false,
    );
  }

  /// Returns a reactive stream of [LibraryResult] for seasons.
  Stream<LibraryResult<Season>> watch(SeasonQuery query) {
    final queryPlan = _buildQueryPlan(query);

    return db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {db.seasons},
        )
        .watch()
        .asyncMap((dataRows) async {
          final countRow = await db
              .customSelect(
                queryPlan.countSql,
                variables: queryPlan.countVariables,
                readsFrom: {db.seasons},
              )
              .getSingle();

          final totalCount = countRow.read<int>('total');
          final items = dataRows.map(_mapRowToSeason).toList();

          return LibraryResult<Season>(
            items: items,
            totalCount: totalCount,
            hasMore: false,
          );
        });
  }

  _SeasonQueryPlan _buildQueryPlan(SeasonQuery query) {
    final whereClauses = <String>[];
    final whereVariables = <Variable>[];

    final effectiveShowId = query.showId ?? query.filter.showId;
    if (effectiveShowId != null && effectiveShowId.isNotEmpty) {
      whereClauses.add('s.show_id = ?');
      whereVariables.add(Variable<String>(effectiveShowId));
    }

    if (query.filter.seasonNumbers != null && query.filter.seasonNumbers!.isNotEmpty) {
      final placeholders = List.filled(query.filter.seasonNumbers!.length, '?').join(', ');
      whereClauses.add('s.season_number IN ($placeholders)');
      for (final num in query.filter.seasonNumbers!) {
        whereVariables.add(Variable<int>(num));
      }
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final countSql = 'SELECT COUNT(*) AS total FROM seasons s $whereSql';
    final countVariables = List<Variable>.from(whereVariables);

    final orderTerms = <String>[];
    for (final sortClause in query.sort) {
      final colExpr = _mapSortFieldToSql(sortClause.field);
      final dir = sortClause.direction == SortDirection.asc ? 'ASC' : 'DESC';
      final nulls = sortClause.nullsOrder == NullsOrder.first ? 'NULLS FIRST' : 'NULLS LAST';
      orderTerms.add('$colExpr $dir $nulls');
    }
    orderTerms.add('s.id ASC');
    final orderSql = 'ORDER BY ${orderTerms.join(', ')}';

    final dataSql = '''
SELECT 
  s.id,
  s.show_id,
  s.season_number,
  s.name,
  s.overview,
  s.poster_path,
  s.air_date,
  s.tmdb_id
FROM seasons s
$whereSql
$orderSql
''';

    return _SeasonQueryPlan(
      dataSql: dataSql,
      dataVariables: List<Variable>.from(whereVariables),
      countSql: countSql,
      countVariables: countVariables,
    );
  }

  String _mapSortFieldToSql(SeasonSortField field) {
    switch (field) {
      case SeasonSortField.seasonNumber:
        return 's.season_number';
    }
  }

  Season _mapRowToSeason(QueryRow row) {
    return Season(
      id: row.read<String>('id'),
      showId: row.read<String>('show_id'),
      seasonNumber: row.read<int>('season_number'),
      name: row.readNullable<String>('name'),
      overview: row.readNullable<String>('overview'),
      posterPath: row.readNullable<String>('poster_path'),
      airDate: row.readNullable<DateTime>('air_date'),
      tmdbId: row.readNullable<int>('tmdb_id'),
    );
  }
}

class _SeasonQueryPlan {
  final String dataSql;
  final List<Variable> dataVariables;
  final String countSql;
  final List<Variable> countVariables;

  const _SeasonQueryPlan({
    required this.dataSql,
    required this.dataVariables,
    required this.countSql,
    required this.countVariables,
  });
}
