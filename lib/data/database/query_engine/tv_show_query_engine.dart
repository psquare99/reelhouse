import 'package:drift/drift.dart' hide NullsOrder;

import '../../../domain/models/availability_status.dart';
import '../../../domain/models/genre_definition.dart';
import '../../../domain/models/identification_status.dart';
import '../../../domain/models/watch_state.dart';
import '../../../domain/query/filter_spec.dart';
import '../../../domain/query/library_result.dart';
import '../../../domain/query/query_projections.dart';
import '../../../domain/query/search_spec.dart';
import '../../../domain/query/sort_fields.dart';
import '../../../domain/query/sort_spec.dart';
import '../../../domain/query/tv_show_query.dart';
import '../database.dart';

/// Database Query Engine for translating [TvShowQuery] into optimized Drift / SQLite queries.
class TvShowQueryEngine {
  final AppDatabase db;

  const TvShowQueryEngine(this.db);

  /// Executes a one-shot query for TV shows returning a [LibraryResult] of [TvShowLibraryItem].
  Future<LibraryResult<TvShowLibraryItem>> query(TvShowQuery query) async {
    final queryPlan = _buildQueryPlan(query);

    final dataRows = await db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {
            db.tvShows,
            db.seasons,
            db.episodes,
            db.mediaSources,
            db.storages,
            db.collectionItems,
          },
        )
        .get();

    final countRow = await db
        .customSelect(
          queryPlan.countSql,
          variables: queryPlan.countVariables,
          readsFrom: {
            db.tvShows,
            db.seasons,
            db.episodes,
            db.mediaSources,
            db.storages,
            db.collectionItems,
          },
        )
        .getSingle();

    final totalCount = countRow.read<int>('total');
    final items = dataRows.map(_mapRowToTvShowItem).toList();

    return LibraryResult<TvShowLibraryItem>(
      items: items,
      totalCount: totalCount,
      hasMore: query.pagination != null
          ? (query.pagination!.offset + items.length) < totalCount
          : false,
      pagination: query.pagination,
    );
  }

  /// Returns a reactive stream of [LibraryResult] for TV shows.
  Stream<LibraryResult<TvShowLibraryItem>> watch(TvShowQuery query) {
    final queryPlan = _buildQueryPlan(query);

    return db
        .customSelect(
          queryPlan.dataSql,
          variables: queryPlan.dataVariables,
          readsFrom: {
            db.tvShows,
            db.seasons,
            db.episodes,
            db.mediaSources,
            db.storages,
            db.collectionItems,
          },
        )
        .watch()
        .asyncMap((dataRows) async {
          final countRow = await db
              .customSelect(
                queryPlan.countSql,
                variables: queryPlan.countVariables,
                readsFrom: {
                  db.tvShows,
                  db.seasons,
                  db.episodes,
                  db.mediaSources,
                  db.storages,
                  db.collectionItems,
                },
              )
              .getSingle();

          final totalCount = countRow.read<int>('total');
          final items = dataRows.map(_mapRowToTvShowItem).toList();

          return LibraryResult<TvShowLibraryItem>(
            items: items,
            totalCount: totalCount,
            hasMore: query.pagination != null
                ? (query.pagination!.offset + items.length) < totalCount
                : false,
            pagination: query.pagination,
          );
        });
  }

  _TvShowQueryPlan _buildQueryPlan(TvShowQuery query) {
    final whereClauses = <String>[];
    final whereVariables = <Variable>[];

    final filter = query.filter;

    // 0. ID filter
    if (filter.id != null && filter.id!.isNotEmpty) {
      whereClauses.add('t.id = ?');
      whereVariables.add(Variable<String>(filter.id!));
    }

    // 1. Search filter
    if (query.search != null && query.search!.isNotEmpty) {
      final term = '%${query.search!.trimmedQuery.toLowerCase()}%';
      if (query.search!.mode == SearchMode.title) {
        whereClauses.add(
          '(LOWER(COALESCE(t.title, \'\')) LIKE ? OR LOWER(t.detected_title) LIKE ?)',
        );
        whereVariables.add(Variable<String>(term));
        whereVariables.add(Variable<String>(term));
      } else {
        whereClauses.add(
          '(LOWER(COALESCE(t.title, \'\')) LIKE ? OR LOWER(t.detected_title) LIKE ? OR LOWER(COALESCE(t.original_title, \'\')) LIKE ? OR LOWER(COALESCE(t.overview, \'\')) LIKE ?)',
        );
        whereVariables.add(Variable<String>(term));
        whereVariables.add(Variable<String>(term));
        whereVariables.add(Variable<String>(term));
        whereVariables.add(Variable<String>(term));
      }
    }

    // 2. Derived WatchState filter
    if (filter.watchStates != null && filter.watchStates!.isNotEmpty) {
      final stateBranches = <String>[];
      for (final state in filter.watchStates!) {
        switch (state) {
          case WatchState.unwatched:
            stateBranches.add(
              '(NOT EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id WHERE s2.show_id = t.id AND s2.season_number >= 0) OR NOT EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id WHERE s2.show_id = t.id AND s2.season_number >= 0 AND (e2.watch_state = \'WATCHED\' OR e2.watch_state = \'IN_PROGRESS\')))',
            );
            break;
          case WatchState.watched:
            stateBranches.add(
              '(EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id WHERE s2.show_id = t.id AND s2.season_number >= 0) AND NOT EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id WHERE s2.show_id = t.id AND s2.season_number >= 0 AND e2.watch_state != \'WATCHED\'))',
            );
            break;
          case WatchState.inProgress:
            stateBranches.add(
              '(EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id WHERE s2.show_id = t.id AND s2.season_number >= 0 AND (e2.watch_state = \'WATCHED\' OR e2.watch_state = \'IN_PROGRESS\')) AND EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id WHERE s2.show_id = t.id AND s2.season_number >= 0 AND e2.watch_state != \'WATCHED\'))',
            );
            break;
        }
      }
      if (stateBranches.isNotEmpty) {
        whereClauses.add('(${stateBranches.join(' OR ')})');
      }
    }

    // 3. Favorite filter
    if (filter.isFavorite != null) {
      whereClauses.add('t.is_favorite = ?');
      whereVariables.add(Variable<bool>(filter.isFavorite!));
    }

    // 4. Watchlist filter
    if (filter.isWatchlist != null) {
      whereClauses.add('t.is_watchlist = ?');
      whereVariables.add(Variable<bool>(filter.isWatchlist!));
    }

    // 5. Metadata status filter
    if (filter.metadataStatuses != null &&
        filter.metadataStatuses!.isNotEmpty) {
      final placeholders = List.filled(
        filter.metadataStatuses!.length,
        '?',
      ).join(', ');
      whereClauses.add('t.identification_status IN ($placeholders)');
      for (final status in filter.metadataStatuses!) {
        whereVariables.add(Variable<String>(status.toDbString()));
      }
    }

    // 6. Year range filter (matching firstAirDate premiere year)
    if (filter.yearRange != null) {
      if (filter.yearRange!.startYear != null) {
        whereClauses.add('t.first_air_date >= ?');
        whereVariables.add(
          Variable<DateTime>(DateTime(filter.yearRange!.startYear!, 1, 1)),
        );
      }
      if (filter.yearRange!.endYear != null) {
        whereClauses.add('t.first_air_date <= ?');
        whereVariables.add(
          Variable<DateTime>(
            DateTime(filter.yearRange!.endYear!, 12, 31, 23, 59, 59, 999),
          ),
        );
      }
    }

    // 7. Collection membership filter
    if (filter.collectionId != null && filter.collectionId!.isNotEmpty) {
      whereClauses.add(
        'EXISTS (SELECT 1 FROM collection_items ci WHERE ci.tv_show_id = t.id AND ci.collection_id = ?)',
      );
      whereVariables.add(Variable<String>(filter.collectionId!));
    }

    // 8. Storage filter
    if (filter.storageId != null && filter.storageId!.isNotEmpty) {
      whereClauses.add(
        'EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id JOIN media_sources ms2 ON ms2.episode_id = e2.id WHERE s2.show_id = t.id AND ms2.storage_id = ?)',
      );
      whereVariables.add(Variable<String>(filter.storageId!));
    }

    // 9. Source filter
    if (filter.sourceId != null && filter.sourceId!.isNotEmpty) {
      whereClauses.add(
        'EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id JOIN media_sources ms2 ON ms2.episode_id = e2.id WHERE s2.show_id = t.id AND ms2.id = ?)',
      );
      whereVariables.add(Variable<String>(filter.sourceId!));
    }

    // 10. Availability filter
    if (filter.availability != null) {
      if (filter.availability == AvailabilityFilter.available) {
        whereClauses.add(
          'EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id JOIN media_sources ms2 ON ms2.episode_id = e2.id LEFT JOIN storages st2 ON st2.id = ms2.storage_id WHERE s2.show_id = t.id AND ms2.available = 1 AND (ms2.source_type = \'localDevice\' OR st2.available = 1))',
        );
      } else {
        whereClauses.add(
          'NOT EXISTS (SELECT 1 FROM seasons s2 JOIN episodes e2 ON e2.season_id = s2.id JOIN media_sources ms2 ON ms2.episode_id = e2.id LEFT JOIN storages st2 ON st2.id = ms2.storage_id WHERE s2.show_id = t.id AND ms2.available = 1 AND (ms2.source_type = \'localDevice\' OR st2.available = 1))',
        );
      }
    }

    // 11. Genre filter
    if (filter.genre != null && filter.genre!.trim().isNotEmpty) {
      final matchingValues = GenreResolver.resolveMatchingValues(filter.genre!);
      if (matchingValues.isNotEmpty) {
        final genreBranches = <String>[];
        for (final val in matchingValues) {
          final normalized = val.trim().toLowerCase();
          genreBranches.add(
            '''(',' || REPLACE(REPLACE(LOWER(COALESCE(t.genres, '')), ', ', ','), ' ,', ',') || ',') LIKE ?''',
          );
          whereVariables.add(Variable<String>('%,$normalized,%'));
        }
        whereClauses.add('(${genreBranches.join(' OR ')})');
      }
    }

    final whereSql = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    // Count SQL
    final countSql = 'SELECT COUNT(*) AS total FROM tv_shows t $whereSql';
    final countVariables = List<Variable>.from(whereVariables);

    // Sorting clauses
    final orderTerms = <String>[];
    for (final sortClause in query.sort) {
      final colExpr = _mapSortFieldToSql(sortClause.field);
      final dir = sortClause.direction == SortDirection.asc ? 'ASC' : 'DESC';
      final nulls = sortClause.nullsOrder == NullsOrder.first
          ? 'NULLS FIRST'
          : 'NULLS LAST';
      orderTerms.add('$colExpr $dir $nulls');
    }
    // Deterministic tie-breaker
    orderTerms.add('t.id ASC');
    final orderSql = 'ORDER BY ${orderTerms.join(', ')}';

    // Data SQL
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
  t.id,
  t.title,
  t.original_title,
  t.detected_title,
  t.first_air_date,
  t.poster_path,
  t.backdrop_path,
  t.overview,
  t.rating,
  t.genres,
  t.is_favorite,
  t.is_watchlist,
  t.identification_status,
  t.created_at,
  t.updated_at,
  COUNT(DISTINCT CASE WHEN s.season_number >= 0 THEN s.id END) AS total_seasons,
  COUNT(DISTINCT CASE WHEN s.season_number >= 0 THEN e.id END) AS total_episodes,
  COUNT(DISTINCT CASE WHEN s.season_number >= 0 AND ms.available = 1 AND (ms.source_type = 'localDevice' OR st.available = 1) THEN e.id END) AS available_episodes,
  COUNT(DISTINCT CASE WHEN s.season_number >= 0 AND e.watch_state = 'WATCHED' THEN e.id END) AS watched_episodes,
  COUNT(DISTINCT CASE WHEN s.season_number >= 0 AND e.watch_state = 'IN_PROGRESS' THEN e.id END) AS in_progress_episodes,
  MAX(CASE WHEN ms.source_type = 'localDevice' AND ms.available = 1 THEN 1 ELSE 0 END) AS has_local,
  MAX(CASE WHEN ms.source_type = 'removableStorage' AND ms.available = 1 AND st.available = 1 THEN 1 ELSE 0 END) AS has_removable
FROM tv_shows t
LEFT JOIN seasons s ON s.show_id = t.id
LEFT JOIN episodes e ON e.season_id = s.id
LEFT JOIN media_sources ms ON ms.episode_id = e.id
LEFT JOIN storages st ON st.id = ms.storage_id
$whereSql
GROUP BY t.id
$orderSql
$paginationSql
''';

    return _TvShowQueryPlan(
      dataSql: dataSql,
      dataVariables: dataVariables,
      countSql: countSql,
      countVariables: countVariables,
    );
  }

  String _mapSortFieldToSql(TvShowSortField field) {
    switch (field) {
      case TvShowSortField.title:
        return 'COALESCE(t.title, t.detected_title) COLLATE NOCASE';
      case TvShowSortField.firstAirDate:
        return 't.first_air_date';
      case TvShowSortField.lastAirDate:
        return '(SELECT MAX(s2.air_date) FROM seasons s2 WHERE s2.show_id = t.id AND s2.season_number >= 0)';
      case TvShowSortField.rating:
        return 't.rating';
      case TvShowSortField.createdAt:
        return 't.created_at';
      case TvShowSortField.updatedAt:
        return 't.updated_at';
      case TvShowSortField.watchState:
        return '''
CASE 
  WHEN COUNT(DISTINCT CASE WHEN s.season_number >= 0 THEN e.id END) = 0 THEN 0
  WHEN COUNT(DISTINCT CASE WHEN s.season_number >= 0 AND e.watch_state = 'WATCHED' THEN e.id END) = COUNT(DISTINCT CASE WHEN s.season_number >= 0 THEN e.id END) THEN 2
  WHEN COUNT(DISTINCT CASE WHEN s.season_number >= 0 AND e.watch_state IN ('WATCHED', 'IN_PROGRESS') THEN e.id END) > 0 THEN 1
  ELSE 0
END''';
    }
  }

  TvShowLibraryItem _mapRowToTvShowItem(QueryRow row) {
    final totalEpisodes = row.read<int?>('total_episodes') ?? 0;
    final watchedEpisodes = row.read<int?>('watched_episodes') ?? 0;
    final inProgressEpisodes = row.read<int?>('in_progress_episodes') ?? 0;

    final WatchState derivedWatchState;
    if (totalEpisodes == 0) {
      derivedWatchState = WatchState.unwatched;
    } else if (watchedEpisodes == totalEpisodes) {
      derivedWatchState = WatchState.watched;
    } else if (watchedEpisodes > 0 || inProgressEpisodes > 0) {
      derivedWatchState = WatchState.inProgress;
    } else {
      derivedWatchState = WatchState.unwatched;
    }

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

    final rawGenres = row.readNullable<String>('genres');
    final genresList = rawGenres != null && rawGenres.isNotEmpty
        ? rawGenres
              .split(',')
              .map((g) => g.trim())
              .where((g) => g.isNotEmpty)
              .toList()
        : const <String>[];

    return TvShowLibraryItem(
      id: row.read<String>('id'),
      title: row.readNullable<String>('title'),
      originalTitle: row.readNullable<String>('original_title'),
      detectedTitle: row.read<String>('detected_title'),
      firstAirDate: row.readNullable<DateTime>('first_air_date'),
      posterPath: row.readNullable<String>('poster_path'),
      backdropPath: row.readNullable<String>('backdrop_path'),
      overview: row.readNullable<String>('overview'),
      rating: row.readNullable<double>('rating'),
      genres: genresList,
      isFavorite: row.read<bool>('is_favorite'),
      isWatchlist: row.read<bool>('is_watchlist'),
      identificationStatus: IdentificationStatus.fromString(
        row.read<String>('identification_status'),
      ),
      derivedWatchState: derivedWatchState,
      availability: availability,
      totalSeasons: row.read<int?>('total_seasons') ?? 0,
      totalEpisodes: totalEpisodes,
      availableEpisodes: row.read<int?>('available_episodes') ?? 0,
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
    );
  }
}

class _TvShowQueryPlan {
  final String dataSql;
  final List<Variable> dataVariables;
  final String countSql;
  final List<Variable> countVariables;

  const _TvShowQueryPlan({
    required this.dataSql,
    required this.dataVariables,
    required this.countSql,
    required this.countVariables,
  });
}
