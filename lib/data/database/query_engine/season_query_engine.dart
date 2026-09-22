import 'package:drift/drift.dart' hide NullsOrder;

import '../../../domain/query/library_result.dart';
import '../../../domain/query/query_projections.dart';
import '../../../domain/query/season_query.dart';
import '../../../domain/query/sort_fields.dart';
import '../../../domain/query/sort_spec.dart';
import '../database.dart';

/// Database Query Engine for translating [SeasonQuery] into optimized Drift / SQLite queries.
class SeasonQueryEngine {
  final AppDatabase db;

  const SeasonQueryEngine(this.db);

  /// Executes a one-shot query for seasons returning a [LibraryResult] of [SeasonLibraryItem].
  Future<LibraryResult<SeasonLibraryItem>> query(SeasonQuery query) async {
    final queryPlan = _buildQueryPlan(query);

    final dataRows = await db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {db.seasons, db.episodes, db.mediaSources},
        )
        .get();

    final countRow = await db
        .customSelect(
          queryPlan.countSql,
          variables: queryPlan.countVariables,
          readsFrom: {db.seasons, db.episodes},
        )
        .getSingle();

    final totalCount = countRow.read<int>('total');
    final items = dataRows.map(_mapRowToSeasonItem).toList();

    return LibraryResult<SeasonLibraryItem>(
      items: items,
      totalCount: totalCount,
      hasMore: false,
    );
  }

  /// Returns a reactive stream of [LibraryResult] for seasons.
  Stream<LibraryResult<SeasonLibraryItem>> watch(SeasonQuery query) {
    final queryPlan = _buildQueryPlan(query);

    return db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {db.seasons, db.episodes, db.mediaSources},
        )
        .watch()
        .asyncMap((dataRows) async {
          final countRow = await db
              .customSelect(
                queryPlan.countSql,
                variables: queryPlan.countVariables,
                readsFrom: {db.seasons, db.episodes},
              )
              .getSingle();

          final totalCount = countRow.read<int>('total');
          final items = dataRows.map(_mapRowToSeasonItem).toList();

          return LibraryResult<SeasonLibraryItem>(
            items: items,
            totalCount: totalCount,
            hasMore: false,
          );
        });
  }

  _SeasonQueryPlan _buildQueryPlan(SeasonQuery query) {
    final whereClauses = <String>[];
    final whereVariables = <Variable>[];

    if (query.filter.id != null && query.filter.id!.isNotEmpty) {
      whereClauses.add('s.id = ?');
      whereVariables.add(Variable<String>(query.filter.id!));
    }

    final effectiveShowId = query.showId ?? query.filter.showId;
    if (effectiveShowId != null && effectiveShowId.isNotEmpty) {
      whereClauses.add('s.show_id = ?');
      whereVariables.add(Variable<String>(effectiveShowId));
    }

    if (query.filter.seasonNumbers != null &&
        query.filter.seasonNumbers!.isNotEmpty) {
      final placeholders = List.filled(
        query.filter.seasonNumbers!.length,
        '?',
      ).join(', ');
      whereClauses.add('s.season_number IN ($placeholders)');
      for (final num in query.filter.seasonNumbers!) {
        whereVariables.add(Variable<int>(num));
      }
    }

    final whereSql = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final countSql = 'SELECT COUNT(*) AS total FROM seasons s $whereSql';
    final countVariables = List<Variable>.from(whereVariables);

    final orderTerms = <String>[];
    for (final sortClause in query.sort) {
      if (sortClause.field == SeasonSortField.seasonNumber) {
        final dir = sortClause.direction == SortDirection.asc ? 'ASC' : 'DESC';
        // Specials (0) first, Normal seasons (1..N) middle, Extras (-1) last
        orderTerms.add(
          'CASE WHEN s.season_number = 0 THEN 0 WHEN s.season_number > 0 THEN 1 ELSE 2 END $dir',
        );
        orderTerms.add('s.season_number $dir');
      } else {
        final colExpr = _mapSortFieldToSql(sortClause.field);
        final dir = sortClause.direction == SortDirection.asc ? 'ASC' : 'DESC';
        final nulls = sortClause.nullsOrder == NullsOrder.first
            ? 'NULLS FIRST'
            : 'NULLS LAST';
        orderTerms.add('$colExpr $dir $nulls');
      }
    }
    orderTerms.add('s.id ASC');
    final orderSql = 'ORDER BY ${orderTerms.join(', ')}';

    final dataVariables = List<Variable>.from(whereVariables);

    final dataSql =
        '''
SELECT 
  s.id,
  s.show_id,
  s.season_number,
  s.name,
  s.overview,
  s.poster_path,
  s.air_date,
  COUNT(DISTINCT e.id) AS episode_count,
  COUNT(DISTINCT CASE WHEN ms.source_type = 'localDevice' AND ms.available = 1 THEN e.id END) AS offline_episode_count
FROM seasons s
LEFT JOIN episodes e ON e.season_id = s.id
LEFT JOIN media_sources ms ON ms.episode_id = e.id
$whereSql
GROUP BY s.id
$orderSql
''';

    return _SeasonQueryPlan(
      dataSql: dataSql,
      dataVariables: dataVariables,
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

  SeasonLibraryItem _mapRowToSeasonItem(QueryRow row) {
    return SeasonLibraryItem(
      id: row.read<String>('id'),
      showId: row.read<String>('show_id'),
      seasonNumber: row.read<int>('season_number'),
      name: row.readNullable<String>('name'),
      overview: row.readNullable<String>('overview'),
      posterPath: row.readNullable<String>('poster_path'),
      episodeCount: row.read<int?>('episode_count') ?? 0,
      offlineEpisodeCount: row.read<int?>('offline_episode_count') ?? 0,
      airDate: row.readNullable<DateTime>('air_date'),
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
