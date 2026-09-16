import 'package:drift/drift.dart' hide NullsOrder;

import '../../../domain/models/availability_status.dart';
import '../../../domain/models/identification_status.dart';
import '../../../domain/models/watch_state.dart';
import '../../../domain/query/filter_spec.dart';
import '../../../domain/query/library_result.dart';
import '../../../domain/query/movie_query.dart';
import '../../../domain/query/query_projections.dart';
import '../../../domain/query/search_spec.dart';
import '../../../domain/query/sort_fields.dart';
import '../../../domain/query/sort_spec.dart';
import '../database.dart';

/// Database Query Engine for translating [MovieQuery] into optimized Drift / SQLite queries.
class MovieQueryEngine {
  final AppDatabase db;

  const MovieQueryEngine(this.db);

  /// Executes a one-shot query for movies returning a [LibraryResult] of [MovieLibraryItem].
  Future<LibraryResult<MovieLibraryItem>> query(MovieQuery query) async {
    final queryPlan = _buildQueryPlan(query);

    final dataRows = await db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {db.movies, db.mediaSources, db.storages, db.collectionItems},
        )
        .get();

    final countRow = await db
        .customSelect(
          queryPlan.countSql,
          variables: queryPlan.countVariables,
          readsFrom: {db.movies, db.mediaSources, db.storages, db.collectionItems},
        )
        .getSingle();

    final totalCount = countRow.read<int>('total');
    final items = dataRows.map(_mapRowToMovieItem).toList();

    return LibraryResult<MovieLibraryItem>(
      items: items,
      totalCount: totalCount,
      hasMore: query.pagination != null
          ? (query.pagination!.offset + items.length) < totalCount
          : false,
      pagination: query.pagination,
    );
  }

  /// Returns a reactive stream of [LibraryResult] for movies.
  Stream<LibraryResult<MovieLibraryItem>> watch(MovieQuery query) {
    final queryPlan = _buildQueryPlan(query);

    return db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {db.movies, db.mediaSources, db.storages, db.collectionItems},
        )
        .watch()
        .asyncMap((dataRows) async {
          final countRow = await db
              .customSelect(
                queryPlan.countSql,
                variables: queryPlan.countVariables,
                readsFrom: {db.movies, db.mediaSources, db.storages, db.collectionItems},
              )
              .getSingle();

          final totalCount = countRow.read<int>('total');
          final items = dataRows.map(_mapRowToMovieItem).toList();

          return LibraryResult<MovieLibraryItem>(
            items: items,
            totalCount: totalCount,
            hasMore: query.pagination != null
                ? (query.pagination!.offset + items.length) < totalCount
                : false,
            pagination: query.pagination,
          );
        });
  }

  _MovieQueryPlan _buildQueryPlan(MovieQuery query) {
    final whereClauses = <String>[];
    final whereVariables = <Variable>[];

    // 1. Search filter
    if (query.search != null && query.search!.isNotEmpty) {
      final term = '%${query.search!.trimmedQuery.toLowerCase()}%';
      if (query.search!.mode == SearchMode.title) {
        whereClauses.add(
          '(LOWER(COALESCE(m.title, \'\')) LIKE ? OR LOWER(m.detected_title) LIKE ?)',
        );
        whereVariables.add(Variable<String>(term));
        whereVariables.add(Variable<String>(term));
      } else {
        whereClauses.add(
          '(LOWER(COALESCE(m.title, \'\')) LIKE ? OR LOWER(m.detected_title) LIKE ? OR LOWER(COALESCE(m.original_title, \'\')) LIKE ? OR LOWER(COALESCE(m.overview, \'\')) LIKE ?)',
        );
        whereVariables.add(Variable<String>(term));
        whereVariables.add(Variable<String>(term));
        whereVariables.add(Variable<String>(term));
        whereVariables.add(Variable<String>(term));
      }
    }

    final filter = query.filter;

    // 2. WatchState filter
    if (filter.watchStates != null && filter.watchStates!.isNotEmpty) {
      final placeholders = List.filled(filter.watchStates!.length, '?').join(', ');
      whereClauses.add('m.watch_state IN ($placeholders)');
      for (final state in filter.watchStates!) {
        whereVariables.add(Variable<String>(state.toDbString()));
      }
    }

    // 3. Favorite filter
    if (filter.isFavorite != null) {
      whereClauses.add('m.is_favorite = ?');
      whereVariables.add(Variable<bool>(filter.isFavorite!));
    }

    // 4. Watchlist filter
    if (filter.isWatchlist != null) {
      whereClauses.add('m.is_watchlist = ?');
      whereVariables.add(Variable<bool>(filter.isWatchlist!));
    }

    // 5. Metadata status filter
    if (filter.metadataStatuses != null && filter.metadataStatuses!.isNotEmpty) {
      final placeholders = List.filled(filter.metadataStatuses!.length, '?').join(', ');
      whereClauses.add('m.identification_status IN ($placeholders)');
      for (final status in filter.metadataStatuses!) {
        whereVariables.add(Variable<String>(status.toDbString()));
      }
    }

    // 6. Year range filter
    if (filter.yearRange != null) {
      if (filter.yearRange!.startYear != null) {
        whereClauses.add('COALESCE(m.year, m.detected_year) >= ?');
        whereVariables.add(Variable<int>(filter.yearRange!.startYear!));
      }
      if (filter.yearRange!.endYear != null) {
        whereClauses.add('COALESCE(m.year, m.detected_year) <= ?');
        whereVariables.add(Variable<int>(filter.yearRange!.endYear!));
      }
    }

    // 7. Collection membership filter
    if (filter.collectionId != null && filter.collectionId!.isNotEmpty) {
      whereClauses.add(
        'EXISTS (SELECT 1 FROM collection_items ci WHERE ci.movie_id = m.id AND ci.collection_id = ?)',
      );
      whereVariables.add(Variable<String>(filter.collectionId!));
    }

    // 8. Storage filter
    if (filter.storageId != null && filter.storageId!.isNotEmpty) {
      whereClauses.add(
        'EXISTS (SELECT 1 FROM media_sources ms WHERE ms.movie_id = m.id AND ms.storage_id = ?)',
      );
      whereVariables.add(Variable<String>(filter.storageId!));
    }

    // 9. Source filter
    if (filter.sourceId != null && filter.sourceId!.isNotEmpty) {
      whereClauses.add(
        'EXISTS (SELECT 1 FROM media_sources ms WHERE ms.movie_id = m.id AND ms.id = ?)',
      );
      whereVariables.add(Variable<String>(filter.sourceId!));
    }

    // 10. Availability filter
    if (filter.availability != null) {
      if (filter.availability == AvailabilityFilter.available) {
        whereClauses.add(
          'EXISTS (SELECT 1 FROM media_sources ms LEFT JOIN storages st ON st.id = ms.storage_id WHERE ms.movie_id = m.id AND ms.available = 1 AND (ms.source_type = \'localDevice\' OR st.available = 1))',
        );
      } else {
        whereClauses.add(
          'NOT EXISTS (SELECT 1 FROM media_sources ms LEFT JOIN storages st ON st.id = ms.storage_id WHERE ms.movie_id = m.id AND ms.available = 1 AND (ms.source_type = \'localDevice\' OR st.available = 1))',
        );
      }
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    // Count SQL (exact count with matching where filters)
    final countSql = 'SELECT COUNT(*) AS total FROM movies m $whereSql';
    final countVariables = List<Variable>.from(whereVariables);

    // Sorting clauses
    final orderTerms = <String>[];
    for (final sortClause in query.sort) {
      final colExpr = _mapSortFieldToSql(sortClause.field);
      final dir = sortClause.direction == SortDirection.asc ? 'ASC' : 'DESC';
      final nulls = sortClause.nullsOrder == NullsOrder.first ? 'NULLS FIRST' : 'NULLS LAST';
      orderTerms.add('$colExpr $dir $nulls');
    }
    // Deterministic tie-breaker
    orderTerms.add('m.id ASC');
    final orderSql = 'ORDER BY ${orderTerms.join(', ')}';

    // Data SQL
    final dataVariables = List<Variable>.from(whereVariables);
    var paginationSql = '';
    if (query.pagination != null) {
      paginationSql = 'LIMIT ? OFFSET ?';
      dataVariables.add(Variable<int>(query.pagination!.limit));
      dataVariables.add(Variable<int>(query.pagination!.offset));
    }

    final dataSql = '''
SELECT 
  m.id,
  m.title,
  m.detected_title,
  m.year,
  m.detected_year,
  m.poster_path,
  m.backdrop_path,
  m.rating,
  m.runtime,
  m.is_favorite,
  m.is_watchlist,
  m.watch_state,
  m.playback_position_seconds,
  m.identification_status,
  m.created_at,
  m.updated_at,
  COUNT(CASE WHEN ms.available = 1 AND (ms.source_type = 'localDevice' OR st.available = 1) THEN 1 ELSE NULL END) AS available_source_count,
  MAX(CASE WHEN ms.source_type = 'localDevice' AND ms.available = 1 THEN 1 ELSE 0 END) AS has_local,
  MAX(CASE WHEN ms.source_type = 'removableStorage' AND ms.available = 1 AND st.available = 1 THEN 1 ELSE 0 END) AS has_removable
FROM movies m
LEFT JOIN media_sources ms ON ms.movie_id = m.id
LEFT JOIN storages st ON st.id = ms.storage_id
$whereSql
GROUP BY m.id
$orderSql
$paginationSql
''';

    return _MovieQueryPlan(
      dataSql: dataSql,
      dataVariables: dataVariables,
      countSql: countSql,
      countVariables: countVariables,
    );
  }

  String _mapSortFieldToSql(MovieSortField field) {
    switch (field) {
      case MovieSortField.title:
        return 'COALESCE(m.title, m.detected_title) COLLATE NOCASE';
      case MovieSortField.releaseDate:
        return 'm.release_date';
      case MovieSortField.year:
        return 'COALESCE(m.year, m.detected_year)';
      case MovieSortField.rating:
        return 'm.rating';
      case MovieSortField.runtime:
        return 'm.runtime';
      case MovieSortField.createdAt:
        return 'm.created_at';
      case MovieSortField.updatedAt:
        return 'm.updated_at';
      case MovieSortField.watchState:
        return 'm.watch_state';
    }
  }

  MovieLibraryItem _mapRowToMovieItem(QueryRow row) {
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

    return MovieLibraryItem(
      id: row.read<String>('id'),
      title: row.readNullable<String>('title'),
      detectedTitle: row.read<String>('detected_title'),
      year: row.readNullable<int>('year'),
      detectedYear: row.readNullable<int>('detected_year'),
      posterPath: row.readNullable<String>('poster_path'),
      backdropPath: row.readNullable<String>('backdrop_path'),
      rating: row.readNullable<double>('rating'),
      runtime: row.readNullable<int>('runtime'),
      isFavorite: row.read<bool>('is_favorite'),
      isWatchlist: row.read<bool>('is_watchlist'),
      watchState: WatchState.fromString(row.read<String>('watch_state')),
      playbackPositionSeconds: row.read<int>('playback_position_seconds'),
      identificationStatus: IdentificationStatus.fromString(
        row.read<String>('identification_status'),
      ),
      availability: availability,
      availableSourceCount: row.read<int?>('available_source_count') ?? 0,
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
    );
  }
}

class _MovieQueryPlan {
  final String dataSql;
  final List<Variable> dataVariables;
  final String countSql;
  final List<Variable> countVariables;

  const _MovieQueryPlan({
    required this.dataSql,
    required this.dataVariables,
    required this.countSql,
    required this.countVariables,
  });
}
