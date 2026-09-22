import 'package:drift/drift.dart' hide NullsOrder;

import '../../../domain/models/availability_status.dart';
import '../../../domain/models/watch_state.dart';
import '../../../domain/query/episode_query.dart';
import '../../../domain/query/filter_spec.dart';
import '../../../domain/query/library_result.dart';
import '../../../domain/query/query_projections.dart';
import '../../../domain/query/search_spec.dart';
import '../../../domain/query/sort_fields.dart';
import '../../../domain/query/sort_spec.dart';
import '../database.dart';

/// Database Query Engine for translating [EpisodeQuery] into optimized Drift / SQLite queries.
class EpisodeQueryEngine {
  final AppDatabase db;

  const EpisodeQueryEngine(this.db);

  /// Executes a one-shot query for episodes returning a [LibraryResult] of [EpisodeLibraryItem].
  Future<LibraryResult<EpisodeLibraryItem>> query(EpisodeQuery query) async {
    final queryPlan = _buildQueryPlan(query);

    final dataRows = await db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {
            db.episodes,
            db.seasons,
            db.tvShows,
            db.mediaSources,
            db.storages,
          },
        )
        .get();

    final countRow = await db
        .customSelect(
          queryPlan.countSql,
          variables: queryPlan.countVariables,
          readsFrom: {
            db.episodes,
            db.seasons,
            db.tvShows,
            db.mediaSources,
            db.storages,
          },
        )
        .getSingle();

    final totalCount = countRow.read<int>('total');
    final items = dataRows.map(_mapRowToEpisodeItem).toList();

    return LibraryResult<EpisodeLibraryItem>(
      items: items,
      totalCount: totalCount,
      hasMore: query.pagination != null
          ? (query.pagination!.offset + items.length) < totalCount
          : false,
      pagination: query.pagination,
    );
  }

  /// Returns a reactive stream of [LibraryResult] for episodes.
  Stream<LibraryResult<EpisodeLibraryItem>> watch(EpisodeQuery query) {
    final queryPlan = _buildQueryPlan(query);

    return db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {
            db.episodes,
            db.seasons,
            db.tvShows,
            db.mediaSources,
            db.storages,
          },
        )
        .watch()
        .asyncMap((dataRows) async {
          final countRow = await db
              .customSelect(
                queryPlan.countSql,
                variables: queryPlan.countVariables,
                readsFrom: {
                  db.episodes,
                  db.seasons,
                  db.tvShows,
                  db.mediaSources,
                  db.storages,
                },
              )
              .getSingle();

          final totalCount = countRow.read<int>('total');
          final items = dataRows.map(_mapRowToEpisodeItem).toList();

          return LibraryResult<EpisodeLibraryItem>(
            items: items,
            totalCount: totalCount,
            hasMore: query.pagination != null
                ? (query.pagination!.offset + items.length) < totalCount
                : false,
            pagination: query.pagination,
          );
        });
  }

  _EpisodeQueryPlan _buildQueryPlan(EpisodeQuery query) {
    final whereClauses = <String>[];
    final whereVariables = <Variable>[];

    if (query.filter.id != null && query.filter.id!.isNotEmpty) {
      whereClauses.add('e.id = ?');
      whereVariables.add(Variable<String>(query.filter.id!));
    }

    final effectiveSeasonId = query.seasonId ?? query.filter.seasonId;
    if (effectiveSeasonId != null && effectiveSeasonId.isNotEmpty) {
      whereClauses.add('e.season_id = ?');
      whereVariables.add(Variable<String>(effectiveSeasonId));
    }

    final effectiveShowId = query.showId ?? query.filter.showId;
    if (effectiveShowId != null && effectiveShowId.isNotEmpty) {
      whereClauses.add('s.show_id = ?');
      whereVariables.add(Variable<String>(effectiveShowId));
    }

    if (query.filter.seasonNumber != null) {
      whereClauses.add('s.season_number = ?');
      whereVariables.add(Variable<int>(query.filter.seasonNumber!));
    }

    // Search filter
    if (query.search != null && query.search!.isNotEmpty) {
      final term = '%${query.search!.trimmedQuery.toLowerCase()}%';
      if (query.search!.mode == SearchMode.title) {
        whereClauses.add('LOWER(COALESCE(e.name, \'\')) LIKE ?');
        whereVariables.add(Variable<String>(term));
      } else {
        whereClauses.add(
          '(LOWER(COALESCE(e.name, \'\')) LIKE ? OR LOWER(COALESCE(e.overview, \'\')) LIKE ?)',
        );
        whereVariables.add(Variable<String>(term));
        whereVariables.add(Variable<String>(term));
      }
    }

    if (query.filter.watchStates != null &&
        query.filter.watchStates!.isNotEmpty) {
      final placeholders = List.filled(
        query.filter.watchStates!.length,
        '?',
      ).join(', ');
      whereClauses.add('e.watch_state IN ($placeholders)');
      for (final state in query.filter.watchStates!) {
        whereVariables.add(Variable<String>(state.toDbString()));
      }
    }

    if (query.filter.storageId != null && query.filter.storageId!.isNotEmpty) {
      whereClauses.add(
        'EXISTS (SELECT 1 FROM media_sources ms2 WHERE ms2.episode_id = e.id AND ms2.storage_id = ?)',
      );
      whereVariables.add(Variable<String>(query.filter.storageId!));
    }

    if (query.filter.availability != null) {
      if (query.filter.availability == AvailabilityFilter.available) {
        whereClauses.add(
          'EXISTS (SELECT 1 FROM media_sources ms2 LEFT JOIN storages st2 ON st2.id = ms2.storage_id WHERE ms2.episode_id = e.id AND ms2.available = 1 AND (ms2.source_type = \'localDevice\' OR st2.available = 1))',
        );
      } else {
        whereClauses.add(
          'NOT EXISTS (SELECT 1 FROM media_sources ms2 LEFT JOIN storages st2 ON st2.id = ms2.storage_id WHERE ms2.episode_id = e.id AND ms2.available = 1 AND (ms2.source_type = \'localDevice\' OR st2.available = 1))',
        );
      }
    }

    if (query.filter.hasBeenPlayed == true) {
      whereClauses.add('e.last_played_at IS NOT NULL');
    }

    final whereSql = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final countSql =
        '''
SELECT COUNT(*) AS total 
FROM episodes e 
INNER JOIN seasons s ON s.id = e.season_id 
$whereSql
''';
    final countVariables = List<Variable>.from(whereVariables);

    final orderTerms = <String>[];
    for (final sortClause in query.sort) {
      final colExpr = _mapSortFieldToSql(sortClause.field);
      final dir = sortClause.direction == SortDirection.asc ? 'ASC' : 'DESC';
      final nulls = sortClause.nullsOrder == NullsOrder.first
          ? 'NULLS FIRST'
          : 'NULLS LAST';
      orderTerms.add('$colExpr $dir $nulls');
    }
    orderTerms.add('e.id ASC');
    final orderSql = 'ORDER BY ${orderTerms.join(', ')}';

    final dataVariables = List<Variable>.from(whereVariables);
    var paginationSql = '';
    if (query.pagination != null) {
      paginationSql = 'LIMIT ? OFFSET ?';
      dataVariables.add(Variable<int>(query.pagination!.limit));
      dataVariables.add(Variable<int>(query.pagination!.offset));
    }

    final dataSql =
        '''
SELECT 
  e.id,
  e.season_id,
  s.show_id,
  COALESCE(t.title, t.detected_title) AS show_title,
  t.poster_path AS show_poster_path,
  s.season_number,
  e.episode_number,
  e.name,
  e.overview,
  e.still_path,
  e.runtime,
  e.air_date,
  e.rating,
  e.watch_state,
  e.playback_position_seconds,
  e.last_played_at,
  COUNT(CASE WHEN ms.available = 1 AND (ms.source_type = 'localDevice' OR st.available = 1) THEN 1 ELSE NULL END) AS available_source_count,
  MAX(CASE WHEN ms.source_type = 'localDevice' AND ms.available = 1 THEN 1 ELSE 0 END) AS has_local,
  MAX(CASE WHEN ms.source_type = 'removableStorage' AND ms.available = 1 AND st.available = 1 THEN 1 ELSE 0 END) AS has_removable
FROM episodes e
INNER JOIN seasons s ON s.id = e.season_id
LEFT JOIN tv_shows t ON t.id = s.show_id
LEFT JOIN media_sources ms ON ms.episode_id = e.id
LEFT JOIN storages st ON st.id = ms.storage_id
$whereSql
GROUP BY e.id
$orderSql
$paginationSql
''';

    return _EpisodeQueryPlan(
      dataSql: dataSql,
      dataVariables: dataVariables,
      countSql: countSql,
      countVariables: countVariables,
    );
  }

  String _mapSortFieldToSql(EpisodeSortField field) {
    switch (field) {
      case EpisodeSortField.seasonNumber:
        return 's.season_number';
      case EpisodeSortField.episodeNumber:
        return 'e.episode_number';
      case EpisodeSortField.airDate:
        return 'e.air_date';
      case EpisodeSortField.title:
        return 'COALESCE(e.name, \'\') COLLATE NOCASE';
      case EpisodeSortField.createdAt:
        return 'e.air_date';
      case EpisodeSortField.lastPlayedAt:
        return 'e.last_played_at';
      case EpisodeSortField.watchState:
        return 'e.watch_state';
    }
  }

  EpisodeLibraryItem _mapRowToEpisodeItem(QueryRow row) {
    final hasLocal = (row.read<int?>('has_local') ?? 0) == 1;
    final hasRemovable = (row.read<int?>('has_removable') ?? 0) == 1;

    final AvailabilityStatus availability;
    if (hasLocal && hasRemovable) {
      availability = AvailabilityStatus.availableOnMultipleSources;
    } else if (hasLocal) {
      availability = AvailabilityStatus.availableLocally;
    } else if (hasRemovable) {
      availability = AvailabilityStatus.availableOnRemovableStorage;
    } else {
      availability = AvailabilityStatus.unavailable;
    }

    return EpisodeLibraryItem(
      id: row.read<String>('id'),
      seasonId: row.read<String>('season_id'),
      showId: row.readNullable<String>('show_id'),
      showTitle: row.readNullable<String>('show_title'),
      showPosterPath: row.readNullable<String>('show_poster_path'),
      seasonNumber: row.read<int>('season_number'),
      episodeNumber: row.read<int>('episode_number'),
      name: row.readNullable<String>('name'),
      overview: row.readNullable<String>('overview'),
      stillPath: row.readNullable<String>('still_path'),
      runtime: row.readNullable<int>('runtime'),
      airDate: row.readNullable<DateTime>('air_date'),
      rating: row.readNullable<double>('rating'),
      watchState: WatchState.fromString(row.read<String>('watch_state')),
      playbackPositionSeconds: row.read<int>('playback_position_seconds'),
      lastPlayedAt: row.readNullable<DateTime>('last_played_at'),
      availability: availability,
      isOffline: hasLocal,
    );
  }
}

class _EpisodeQueryPlan {
  final String dataSql;
  final List<Variable> dataVariables;
  final String countSql;
  final List<Variable> countVariables;

  const _EpisodeQueryPlan({
    required this.dataSql,
    required this.dataVariables,
    required this.countSql,
    required this.countVariables,
  });
}
