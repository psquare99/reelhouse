import '../models/identification_status.dart';
import '../models/watch_state.dart';

/// Generic logical availability filter.
///
/// Section 25:
/// - AVAILABLE: At least one valid physical MediaSource is currently usable.
/// - UNAVAILABLE: No associated physical MediaSource is currently usable (e.g. storage disconnected).
enum AvailabilityFilter {
  /// Item has at least one currently connected and available physical file copy.
  available,

  /// Item has zero currently connected and available physical file copies.
  unavailable;

  bool get isAvailable => this == AvailabilityFilter.available;
  bool get isUnavailable => this == AvailabilityFilter.unavailable;
}

/// Bounded range for release or air years.
///
/// Section 33:
/// - Represents inclusive range [startYear .. endYear].
class YearRange {
  final int? startYear;
  final int? endYear;

  const YearRange({
    this.startYear,
    this.endYear,
  }) : assert(
          startYear == null || endYear == null || startYear <= endYear,
          'startYear ($startYear) must be <= endYear ($endYear)',
        );

  const YearRange.exact(int year)
      : startYear = year,
        endYear = year;

  const YearRange.since(int year)
      : startYear = year,
        endYear = null;

  const YearRange.until(int year)
      : startYear = null,
        endYear = year;

  bool contains(int? year) {
    if (year == null) return false;
    if (startYear != null && year < startYear!) return false;
    if (endYear != null && year > endYear!) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearRange &&
          runtimeType == other.runtimeType &&
          startYear == other.startYear &&
          endYear == other.endYear;

  @override
  int get hashCode => Object.hash(startYear, endYear);

  @override
  String toString() => 'YearRange($startYear..$endYear)';
}

/// Bounded range for date timestamps.
class DateRange {
  final DateTime? start;
  final DateTime? end;

  DateRange({
    this.start,
    this.end,
  }) : assert(
          start == null || end == null || !start.isAfter(end),
          'start must be before or equal to end',
        );

  bool contains(DateTime? date) {
    if (date == null) return false;
    if (start != null && date.isBefore(start!)) return false;
    if (end != null && date.isAfter(end!)) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start..$end)';
}

/// Composable filter criteria for Movie queries.
///
/// Section 29–37:
/// - Combines filter dimensions with predictable AND semantics.
class MovieFilter {
  final Set<WatchState>? watchStates;
  final bool? isFavorite;
  final bool? isWatchlist;
  final AvailabilityFilter? availability;
  final Set<IdentificationStatus>? metadataStatuses;
  final YearRange? yearRange;
  final String? collectionId;
  final String? storageId;
  final String? sourceId;

  const MovieFilter({
    this.watchStates,
    this.isFavorite,
    this.isWatchlist,
    this.availability,
    this.metadataStatuses,
    this.yearRange,
    this.collectionId,
    this.storageId,
    this.sourceId,
  });

  static const MovieFilter empty = MovieFilter();

  bool get isEmpty =>
      watchStates == null &&
      isFavorite == null &&
      isWatchlist == null &&
      availability == null &&
      metadataStatuses == null &&
      yearRange == null &&
      collectionId == null &&
      storageId == null &&
      sourceId == null;

  bool get isNotEmpty => !isEmpty;

  MovieFilter copyWith({
    Set<WatchState>? watchStates,
    bool? isFavorite,
    bool? isWatchlist,
    AvailabilityFilter? availability,
    Set<IdentificationStatus>? metadataStatuses,
    YearRange? yearRange,
    String? collectionId,
    String? storageId,
    String? sourceId,
  }) {
    return MovieFilter(
      watchStates: watchStates ?? this.watchStates,
      isFavorite: isFavorite ?? this.isFavorite,
      isWatchlist: isWatchlist ?? this.isWatchlist,
      availability: availability ?? this.availability,
      metadataStatuses: metadataStatuses ?? this.metadataStatuses,
      yearRange: yearRange ?? this.yearRange,
      collectionId: collectionId ?? this.collectionId,
      storageId: storageId ?? this.storageId,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieFilter &&
          runtimeType == other.runtimeType &&
          isFavorite == other.isFavorite &&
          isWatchlist == other.isWatchlist &&
          availability == other.availability &&
          yearRange == other.yearRange &&
          collectionId == other.collectionId &&
          storageId == other.storageId &&
          sourceId == other.sourceId &&
          _setEquals(watchStates, other.watchStates) &&
          _setEquals(metadataStatuses, other.metadataStatuses);

  @override
  int get hashCode => Object.hash(
        watchStates == null ? null : Object.hashAll(watchStates!),
        isFavorite,
        isWatchlist,
        availability,
        metadataStatuses == null ? null : Object.hashAll(metadataStatuses!),
        yearRange,
        collectionId,
        storageId,
        sourceId,
      );

  @override
  String toString() =>
      'MovieFilter(watch: $watchStates, fav: $isFavorite, watchl: $isWatchlist, avail: $availability, meta: $metadataStatuses, year: $yearRange, col: $collectionId, storage: $storageId, src: $sourceId)';

  static bool _setEquals<E>(Set<E>? a, Set<E>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

/// Composable filter criteria for TV Show queries.
///
/// Section 29–37:
/// - Note: TV show watchState filter matches against derived series watch state.
class TvShowFilter {
  final Set<WatchState>? watchStates;
  final bool? isFavorite;
  final bool? isWatchlist;
  final AvailabilityFilter? availability;
  final Set<IdentificationStatus>? metadataStatuses;
  final YearRange? yearRange;
  final String? collectionId;
  final String? storageId;
  final String? sourceId;

  const TvShowFilter({
    this.watchStates,
    this.isFavorite,
    this.isWatchlist,
    this.availability,
    this.metadataStatuses,
    this.yearRange,
    this.collectionId,
    this.storageId,
    this.sourceId,
  });

  static const TvShowFilter empty = TvShowFilter();

  bool get isEmpty =>
      watchStates == null &&
      isFavorite == null &&
      isWatchlist == null &&
      availability == null &&
      metadataStatuses == null &&
      yearRange == null &&
      collectionId == null &&
      storageId == null &&
      sourceId == null;

  bool get isNotEmpty => !isEmpty;

  TvShowFilter copyWith({
    Set<WatchState>? watchStates,
    bool? isFavorite,
    bool? isWatchlist,
    AvailabilityFilter? availability,
    Set<IdentificationStatus>? metadataStatuses,
    YearRange? yearRange,
    String? collectionId,
    String? storageId,
    String? sourceId,
  }) {
    return TvShowFilter(
      watchStates: watchStates ?? this.watchStates,
      isFavorite: isFavorite ?? this.isFavorite,
      isWatchlist: isWatchlist ?? this.isWatchlist,
      availability: availability ?? this.availability,
      metadataStatuses: metadataStatuses ?? this.metadataStatuses,
      yearRange: yearRange ?? this.yearRange,
      collectionId: collectionId ?? this.collectionId,
      storageId: storageId ?? this.storageId,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvShowFilter &&
          runtimeType == other.runtimeType &&
          isFavorite == other.isFavorite &&
          isWatchlist == other.isWatchlist &&
          availability == other.availability &&
          yearRange == other.yearRange &&
          collectionId == other.collectionId &&
          storageId == other.storageId &&
          sourceId == other.sourceId &&
          MovieFilter._setEquals(watchStates, other.watchStates) &&
          MovieFilter._setEquals(metadataStatuses, other.metadataStatuses);

  @override
  int get hashCode => Object.hash(
        watchStates == null ? null : Object.hashAll(watchStates!),
        isFavorite,
        isWatchlist,
        availability,
        metadataStatuses == null ? null : Object.hashAll(metadataStatuses!),
        yearRange,
        collectionId,
        storageId,
        sourceId,
      );

  @override
  String toString() =>
      'TvShowFilter(watch: $watchStates, fav: $isFavorite, watchl: $isWatchlist, avail: $availability, meta: $metadataStatuses, year: $yearRange, col: $collectionId, storage: $storageId, src: $sourceId)';
}

/// Filter criteria for Season queries.
class SeasonFilter {
  final String? showId;
  final Set<int>? seasonNumbers;

  const SeasonFilter({
    this.showId,
    this.seasonNumbers,
  });

  static const SeasonFilter empty = SeasonFilter();

  bool get isEmpty => showId == null && seasonNumbers == null;
  bool get isNotEmpty => !isEmpty;

  SeasonFilter copyWith({
    String? showId,
    Set<int>? seasonNumbers,
  }) {
    return SeasonFilter(
      showId: showId ?? this.showId,
      seasonNumbers: seasonNumbers ?? this.seasonNumbers,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonFilter &&
          runtimeType == other.runtimeType &&
          showId == other.showId &&
          MovieFilter._setEquals(seasonNumbers, other.seasonNumbers);

  @override
  int get hashCode => Object.hash(
        showId,
        seasonNumbers == null ? null : Object.hashAll(seasonNumbers!),
      );

  @override
  String toString() => 'SeasonFilter(showId: $showId, seasons: $seasonNumbers)';
}

/// Filter criteria for Episode queries.
class EpisodeFilter {
  final String? seasonId;
  final String? showId;
  final int? seasonNumber;
  final Set<WatchState>? watchStates;
  final AvailabilityFilter? availability;
  final String? storageId;

  const EpisodeFilter({
    this.seasonId,
    this.showId,
    this.seasonNumber,
    this.watchStates,
    this.availability,
    this.storageId,
  });

  static const EpisodeFilter empty = EpisodeFilter();

  bool get isEmpty =>
      seasonId == null &&
      showId == null &&
      seasonNumber == null &&
      watchStates == null &&
      availability == null &&
      storageId == null;

  bool get isNotEmpty => !isEmpty;

  EpisodeFilter copyWith({
    String? seasonId,
    String? showId,
    int? seasonNumber,
    Set<WatchState>? watchStates,
    AvailabilityFilter? availability,
    String? storageId,
  }) {
    return EpisodeFilter(
      seasonId: seasonId ?? this.seasonId,
      showId: showId ?? this.showId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      watchStates: watchStates ?? this.watchStates,
      availability: availability ?? this.availability,
      storageId: storageId ?? this.storageId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeFilter &&
          runtimeType == other.runtimeType &&
          seasonId == other.seasonId &&
          showId == other.showId &&
          seasonNumber == other.seasonNumber &&
          availability == other.availability &&
          storageId == other.storageId &&
          MovieFilter._setEquals(watchStates, other.watchStates);

  @override
  int get hashCode => Object.hash(
        seasonId,
        showId,
        seasonNumber,
        watchStates == null ? null : Object.hashAll(watchStates!),
        availability,
        storageId,
      );

  @override
  String toString() =>
      'EpisodeFilter(seasonId: $seasonId, showId: $showId, sNum: $seasonNumber, watch: $watchStates, avail: $availability, storage: $storageId)';
}

/// Filter criteria for Collection queries.
class CollectionFilter {
  final String? nameQuery;

  const CollectionFilter({
    this.nameQuery,
  });

  static const CollectionFilter empty = CollectionFilter();

  bool get isEmpty => nameQuery == null || nameQuery!.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  CollectionFilter copyWith({
    String? nameQuery,
  }) {
    return CollectionFilter(
      nameQuery: nameQuery ?? this.nameQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionFilter &&
          runtimeType == other.runtimeType &&
          nameQuery == other.nameQuery;

  @override
  int get hashCode => nameQuery.hashCode;

  @override
  String toString() => 'CollectionFilter(nameQuery: $nameQuery)';
}
