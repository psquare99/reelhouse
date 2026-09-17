import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/models/availability_status.dart';
import 'package:reelhouse/domain/models/identification_status.dart';
import 'package:reelhouse/domain/query/query.dart';

void main() {
  group('WatchState', () {
    test('values and conversion methods work correctly', () {
      expect(WatchState.unwatched.isUnwatched, isTrue);
      expect(WatchState.inProgress.isInProgress, isTrue);
      expect(WatchState.watched.isWatched, isTrue);

      expect(WatchState.fromString('unwatched'), equals(WatchState.unwatched));
      expect(
        WatchState.fromString('IN_PROGRESS'),
        equals(WatchState.inProgress),
      );
      expect(WatchState.fromString('WATCHED'), equals(WatchState.watched));
      expect(
        WatchState.fromString('unknown_val'),
        equals(WatchState.unwatched),
      );

      expect(WatchState.unwatched.toDbString(), equals('UNWATCHED'));
      expect(WatchState.inProgress.toDbString(), equals('IN_PROGRESS'));
      expect(WatchState.watched.toDbString(), equals('WATCHED'));

      expect(WatchState.unwatched.displayLabel, equals('Unwatched'));
      expect(WatchState.inProgress.displayLabel, equals('In Progress'));
      expect(WatchState.watched.displayLabel, equals('Watched'));
    });
  });

  group('SearchSpec', () {
    test('construction, default mode, and trimming', () {
      const spec = SearchSpec(query: '  inception  ', mode: SearchMode.title);
      expect(spec.query, equals('  inception  '));
      expect(spec.trimmedQuery, equals('inception'));
      expect(spec.mode, equals(SearchMode.title));
      expect(spec.isEmpty, isFalse);
      expect(spec.isNotEmpty, isTrue);
    });

    test('all mode and copyWith', () {
      const spec = SearchSpec(query: 'Nolan', mode: SearchMode.all);
      expect(spec.mode, equals(SearchMode.all));

      final copied = spec.copyWith(query: 'Tarantino');
      expect(copied.query, equals('Tarantino'));
      expect(copied.mode, equals(SearchMode.all));
      expect(copied == spec, isFalse);
    });

    test('value equality and hashCode', () {
      const a = SearchSpec(query: 'batman', mode: SearchMode.title);
      const b = SearchSpec(query: 'batman', mode: SearchMode.title);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('SortSpec & SortClause', () {
    test('SortClause properties and defaults', () {
      const clause = SortClause(MovieSortField.title);
      expect(clause.field, equals(MovieSortField.title));
      expect(clause.direction, equals(SortDirection.asc));
      expect(clause.nulls, equals(NullsOrder.last));
      expect(clause.isAscending, isTrue);
      expect(clause.isDescending, isFalse);
    });

    test('SortClause descending and nulls first', () {
      const clause = SortClause(
        MovieSortField.releaseDate,
        direction: SortDirection.desc,
        nullsOrder: NullsOrder.first,
      );
      expect(clause.direction, equals(SortDirection.desc));
      expect(clause.nulls, equals(NullsOrder.first));
      expect(clause.isDescending, isTrue);
    });

    test('SortClause copyWith and equality', () {
      const a = SortClause(MovieSortField.title, direction: SortDirection.asc);
      final b = a.copyWith(direction: SortDirection.desc);
      expect(b.direction, equals(SortDirection.desc));
      expect(b.field, equals(MovieSortField.title));

      const c = SortClause(MovieSortField.title, direction: SortDirection.asc);
      expect(a, equals(c));
      expect(a.hashCode, equals(c.hashCode));
    });
  });

  group('FilterSpec Primitives', () {
    test('AvailabilityFilter booleans', () {
      expect(AvailabilityFilter.available.isAvailable, isTrue);
      expect(AvailabilityFilter.available.isUnavailable, isFalse);
      expect(AvailabilityFilter.unavailable.isUnavailable, isTrue);
    });

    test('YearRange bounds and contains logic', () {
      const exact = YearRange.exact(2024);
      expect(exact.startYear, equals(2024));
      expect(exact.endYear, equals(2024));
      expect(exact.contains(2024), isTrue);
      expect(exact.contains(2023), isFalse);

      const since = YearRange.since(2010);
      expect(since.contains(2009), isFalse);
      expect(since.contains(2010), isTrue);
      expect(since.contains(2025), isTrue);

      const until = YearRange.until(1999);
      expect(until.contains(1999), isTrue);
      expect(until.contains(2000), isFalse);

      const range = YearRange(startYear: 2000, endYear: 2010);
      expect(range.contains(1999), isFalse);
      expect(range.contains(2005), isTrue);
      expect(range.contains(2011), isFalse);
      expect(range.contains(null), isFalse);

      expect(
        () => YearRange(startYear: 2020, endYear: 2010),
        throwsAssertionError,
      );
    });

    test('DateRange bounds and contains logic', () {
      final now = DateTime(2026, 9, 16);
      final past = DateTime(2026, 1, 1);
      final future = DateTime(2026, 12, 31);

      final range = DateRange(start: past, end: future);
      expect(range.contains(now), isTrue);
      expect(range.contains(DateTime(2025, 12, 31)), isFalse);
      expect(range.contains(DateTime(2027, 1, 1)), isFalse);
      expect(range.contains(null), isFalse);

      expect(() => DateRange(start: future, end: past), throwsAssertionError);
    });
  });

  group('Entity Filters', () {
    test('MovieFilter empty and copyWith', () {
      const empty = MovieFilter.empty;
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);

      final populated = empty.copyWith(
        watchStates: {WatchState.watched},
        isFavorite: true,
        availability: AvailabilityFilter.available,
        yearRange: const YearRange.since(2000),
      );

      expect(populated.isEmpty, isFalse);
      expect(populated.watchStates, contains(WatchState.watched));
      expect(populated.isFavorite, isTrue);
      expect(populated.availability, equals(AvailabilityFilter.available));
      expect(populated.yearRange, equals(const YearRange.since(2000)));

      final copy2 = populated.copyWith(isFavorite: false);
      expect(copy2.isFavorite, isFalse);
      expect(copy2 == populated, isFalse);
    });

    test('TvShowFilter empty and copyWith', () {
      const filter = TvShowFilter(
        watchStates: {WatchState.inProgress},
        isWatchlist: true,
        metadataStatuses: {IdentificationStatus.identified},
      );
      expect(filter.isEmpty, isFalse);
      expect(filter.watchStates, contains(WatchState.inProgress));
      expect(filter.isWatchlist, isTrue);
      expect(
        filter.metadataStatuses,
        contains(IdentificationStatus.identified),
      );

      final copy = filter.copyWith(collectionId: 'col-123');
      expect(copy.collectionId, equals('col-123'));
      expect(copy.watchStates, contains(WatchState.inProgress));
    });

    test('SeasonFilter and EpisodeFilter properties', () {
      const sFilter = SeasonFilter(showId: 'show-1', seasonNumbers: {1, 2});
      expect(sFilter.showId, equals('show-1'));
      expect(sFilter.seasonNumbers, contains(2));

      const epFilter = EpisodeFilter(
        showId: 'show-1',
        seasonId: 'season-1',
        seasonNumber: 1,
        watchStates: {WatchState.unwatched},
        availability: AvailabilityFilter.available,
      );
      expect(epFilter.showId, equals('show-1'));
      expect(epFilter.seasonId, equals('season-1'));
      expect(epFilter.seasonNumber, equals(1));
      expect(epFilter.watchStates, contains(WatchState.unwatched));
      expect(epFilter.availability, equals(AvailabilityFilter.available));
    });

    test('CollectionFilter nameQuery and empty', () {
      const empty = CollectionFilter.empty;
      expect(empty.isEmpty, isTrue);

      const colFilter = CollectionFilter(nameQuery: 'Marvel');
      expect(colFilter.isEmpty, isFalse);
      expect(colFilter.nameQuery, equals('Marvel'));
    });
  });

  group('PaginationSpec', () {
    test('construction, defaults, and page calculations', () {
      const page1 = PaginationSpec(limit: 20, offset: 0);
      expect(page1.limit, equals(20));
      expect(page1.offset, equals(0));
      expect(page1.pageIndex, equals(0));
      expect(page1.pageNumber, equals(1));

      final page2 = page1.nextPage();
      expect(page2.offset, equals(20));
      expect(page2.pageIndex, equals(1));
      expect(page2.pageNumber, equals(2));

      final backToPage1 = page2.previousPage();
      expect(backToPage1.offset, equals(0));
      expect(backToPage1.pageIndex, equals(0));

      final cannotGoNegative = backToPage1.previousPage();
      expect(cannotGoNegative.offset, equals(0));
    });

    test('assertion on invalid limit and offset', () {
      expect(() => PaginationSpec(limit: 0), throwsAssertionError);
      expect(() => PaginationSpec(limit: -5), throwsAssertionError);
      expect(() => PaginationSpec(limit: 20, offset: -1), throwsAssertionError);
    });
  });

  group('QueryScope', () {
    test('constants and factories', () {
      expect(QueryScope.all.type, equals(QueryScopeType.all));
      expect(QueryScope.favorites.type, equals(QueryScopeType.favorites));
      expect(
        QueryScope.recentlyAdded.type,
        equals(QueryScopeType.recentlyAdded),
      );
      expect(
        QueryScope.continueWatching.type,
        equals(QueryScopeType.continueWatching),
      );
      expect(QueryScope.unwatched.type, equals(QueryScopeType.unwatched));
      expect(
        QueryScope.needsVerification.type,
        equals(QueryScopeType.needsVerification),
      );
      expect(QueryScope.offline.type, equals(QueryScopeType.offline));

      final colScope = QueryScope.collection('marvel-id', label: 'MCU');
      expect(colScope.type, equals(QueryScopeType.collection));
      expect(colScope.targetId, equals('marvel-id'));
      expect(colScope.label, equals('MCU'));
      expect(colScope.type.isCollection, isTrue);

      final searchScope = QueryScope.search('Nolan');
      expect(searchScope.type, equals(QueryScopeType.search));
      expect(searchScope.targetId, equals('Nolan'));
      expect(searchScope.type.isSearch, isTrue);

      expect(QueryScopeType.recentlyAdded.isSmartView, isTrue);
      expect(QueryScopeType.continueWatching.isSmartView, isTrue);
      expect(QueryScopeType.all.isSmartView, isFalse);
    });
  });

  group('LibraryResult', () {
    test('properties, hasMore, and mapping', () {
      final result = LibraryResult<String>(
        items: const ['Item 1', 'Item 2', 'Item 3'],
        totalCount: 10,
        hasMore: true,
        pagination: const PaginationSpec(limit: 3, offset: 0),
      );

      expect(result.length, equals(3));
      expect(result.isEmpty, isFalse);
      expect(result.isNotEmpty, isTrue);
      expect(result.hasMore, isTrue);
      expect(result[0], equals('Item 1'));

      final mapped = result.map((item) => item.toUpperCase());
      expect(mapped.items, equals(['ITEM 1', 'ITEM 2', 'ITEM 3']));
      expect(mapped.totalCount, equals(10));
      expect(mapped.hasMore, isTrue);
    });
  });

  group('Query Projections', () {
    test('MovieLibraryItem projections', () {
      final movieItem = MovieLibraryItem(
        id: 'm1',
        title: 'Inception',
        detectedTitle: 'Inception',
        year: 2010,
        posterPath: '/path.jpg',
        watchState: WatchState.inProgress,
        playbackPositionSeconds: 3600,
        isFavorite: true,
        isWatchlist: false,
        availability: AvailabilityStatus.availableLocally,
        availableSourceCount: 1,
        identificationStatus: IdentificationStatus.identified,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(movieItem.id, equals('m1'));
      expect(movieItem.displayTitle, equals('Inception'));
      expect(movieItem.displayYear, equals(2010));
      expect(movieItem.isPlayable, isTrue);
      expect(movieItem.watchState, equals(WatchState.inProgress));
    });

    test('TvShowLibraryItem projections', () {
      final showItem = TvShowLibraryItem(
        id: 'tv1',
        title: 'Severance',
        detectedTitle: 'Severance',
        firstAirDate: DateTime(2022, 2, 18),
        posterPath: '/sev.jpg',
        derivedWatchState: WatchState.inProgress,
        isFavorite: true,
        isWatchlist: true,
        availability: AvailabilityStatus.availableLocally,
        totalSeasons: 1,
        totalEpisodes: 9,
        availableEpisodes: 9,
        identificationStatus: IdentificationStatus.identified,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(showItem.id, equals('tv1'));
      expect(showItem.displayTitle, equals('Severance'));
      expect(showItem.displayYear, equals(2022));
      expect(showItem.totalSeasons, equals(1));
      expect(showItem.totalEpisodes, equals(9));
      expect(showItem.isPlayable, isTrue);
    });

    test('EpisodeLibraryItem projections', () {
      const epItem = EpisodeLibraryItem(
        id: 'ep1',
        showId: 'tv1',
        seasonId: 's1',
        seasonNumber: 1,
        episodeNumber: 1,
        name: 'Good News About Hell',
        stillPath: '/still.jpg',
        watchState: WatchState.watched,
        playbackPositionSeconds: 3200,
        availability: AvailabilityStatus.availableLocally,
      );

      expect(epItem.id, equals('ep1'));
      expect(epItem.episodeCode, equals('S01E01'));
      expect(epItem.displayName, equals('Good News About Hell'));
      expect(epItem.isPlayable, isTrue);
    });
  });

  group('MovieQuery', () {
    test('default construction', () {
      const query = MovieQuery();
      expect(query.filter.isEmpty, isTrue);
      expect(query.sort.length, equals(1));
      expect(query.sort.first.field, equals(MovieSortField.title));
      expect(query.sort.first.direction, equals(SortDirection.asc));
      expect(query.scope, equals(QueryScope.all));
      expect(query.search, isNull);
      expect(query.pagination, isNull);
    });

    test('Smart View and search factories', () {
      final recent = MovieQuery.recentlyAdded(limit: 10);
      expect(recent.scope.type, equals(QueryScopeType.recentlyAdded));
      expect(recent.sort.first.field, equals(MovieSortField.createdAt));
      expect(recent.sort.first.direction, equals(SortDirection.desc));
      expect(recent.pagination?.limit, equals(10));

      final cont = MovieQuery.continueWatching(limit: 5);
      expect(cont.scope.type, equals(QueryScopeType.continueWatching));
      expect(cont.filter.watchStates, contains(WatchState.inProgress));
      expect(cont.sort.first.field, equals(MovieSortField.updatedAt));
      expect(cont.sort.first.direction, equals(SortDirection.desc));

      final favs = MovieQuery.favorites();
      expect(favs.scope.type, equals(QueryScopeType.favorites));
      expect(favs.filter.isFavorite, isTrue);

      final wl = MovieQuery.watchlist();
      expect(wl.scope.type, equals(QueryScopeType.watchlist));
      expect(wl.filter.isWatchlist, isTrue);

      final unwatched = MovieQuery.unwatched();
      expect(unwatched.scope.type, equals(QueryScopeType.unwatched));
      expect(unwatched.filter.watchStates, contains(WatchState.unwatched));

      final verify = MovieQuery.needsVerification();
      expect(verify.scope.type, equals(QueryScopeType.needsVerification));
      expect(
        verify.filter.metadataStatuses,
        containsAll([
          IdentificationStatus.pending,
          IdentificationStatus.needsVerification,
        ]),
      );

      final offline = MovieQuery.offline();
      expect(offline.scope.type, equals(QueryScopeType.offline));
      expect(offline.filter.availability, equals(AvailabilityFilter.available));

      final col = MovieQuery.forCollection('col-1', label: 'Sci-Fi');
      expect(col.scope.type, equals(QueryScopeType.collection));
      expect(col.scope.targetId, equals('col-1'));
      expect(col.filter.collectionId, equals('col-1'));

      final search = MovieQuery.search('Dune');
      expect(search.scope.type, equals(QueryScopeType.search));
      expect(search.search?.query, equals('Dune'));
    });

    test('copyWith and value equality', () {
      final q1 = MovieQuery.all();
      final q2 = q1.copyWith(
        filter: const MovieFilter(isFavorite: true),
        pagination: const PaginationSpec(limit: 25),
      );

      expect(q2.filter.isFavorite, isTrue);
      expect(q2.pagination?.limit, equals(25));
      expect(q1 == q2, isFalse);

      final q3 = q2.copyWith(clearPagination: true);
      expect(q3.pagination, isNull);
    });
  });

  group('TvShowQuery', () {
    test('default construction and Smart View factories', () {
      const query = TvShowQuery();
      expect(query.filter.isEmpty, isTrue);
      expect(query.sort.first.field, equals(TvShowSortField.title));
      expect(query.scope, equals(QueryScope.all));

      final recent = TvShowQuery.recentlyAdded(limit: 12);
      expect(recent.scope.type, equals(QueryScopeType.recentlyAdded));
      expect(recent.sort.first.field, equals(TvShowSortField.createdAt));
      expect(recent.pagination?.limit, equals(12));

      final unwatched = TvShowQuery.unwatched();
      expect(unwatched.filter.watchStates, contains(WatchState.unwatched));

      final col = TvShowQuery.forCollection('col-tv');
      expect(col.filter.collectionId, equals('col-tv'));

      final search = TvShowQuery.search('Severance');
      expect(search.search?.query, equals('Severance'));
    });

    test('copyWith and value equality', () {
      const q1 = TvShowQuery();
      final q2 = q1.copyWith(
        search: const SearchSpec(query: 'Office'),
        filter: const TvShowFilter(isFavorite: true),
      );

      expect(q2.search?.query, equals('Office'));
      expect(q2.filter.isFavorite, isTrue);

      final q3 = q2.copyWith(clearSearch: true);
      expect(q3.search, isNull);
    });
  });

  group('SeasonQuery & EpisodeQuery', () {
    test('SeasonQuery defaults and forShow factory', () {
      final q = SeasonQuery.forShow('show-123');
      expect(q.showId, equals('show-123'));
      expect(q.filter.showId, equals('show-123'));
      expect(q.sort.first.field, equals(SeasonSortField.seasonNumber));
      expect(q.sort.first.direction, equals(SortDirection.asc));
    });

    test('EpisodeQuery forSeason and continueWatching factories', () {
      final seasonQ = EpisodeQuery.forSeason(
        'season-123',
        showId: 'show-123',
        seasonNumber: 2,
      );
      expect(seasonQ.seasonId, equals('season-123'));
      expect(seasonQ.showId, equals('show-123'));
      expect(seasonQ.filter.seasonNumber, equals(2));
      expect(seasonQ.sort.first.field, equals(EpisodeSortField.episodeNumber));

      final contQ = EpisodeQuery.continueWatching(limit: 10);
      expect(contQ.scope.type, equals(QueryScopeType.continueWatching));
      expect(contQ.filter.watchStates, contains(WatchState.inProgress));
      expect(contQ.sort.first.field, equals(EpisodeSortField.createdAt));
      expect(contQ.sort.first.direction, equals(SortDirection.desc));
      expect(contQ.pagination?.limit, equals(10));
    });
  });

  group('CollectionQuery', () {
    test('all and search factories', () {
      final all = CollectionQuery.all(
        pagination: const PaginationSpec(limit: 50),
      );
      expect(all.pagination?.limit, equals(50));
      expect(all.sort.first.field, equals(CollectionSortField.name));

      final search = CollectionQuery.search('Animation');
      expect(search.search?.query, equals('Animation'));
      expect(search.filter.nameQuery, equals('Animation'));
    });
  });
}
