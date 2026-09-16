/// Sortable fields for Movie queries.
///
/// Section 13:
/// - TITLE: Canonical title (or fallback detectedTitle).
/// - RELEASE_DATE: Canonical release date.
/// - YEAR: Canonical release year (or fallback detectedYear).
/// - RATING: Community/critic rating.
/// - RUNTIME: Film duration in minutes.
/// - CREATED_AT: Timestamp when discovered and indexed in library.
/// - UPDATED_AT: Timestamp when last modified (e.g. watch state progress).
/// - WATCH_STATE: User consumption state ('UNWATCHED', 'IN_PROGRESS', 'WATCHED').
enum MovieSortField {
  title,
  releaseDate,
  year,
  rating,
  runtime,
  createdAt,
  updatedAt,
  watchState;

  String get displayName {
    switch (this) {
      case MovieSortField.title:
        return 'Title';
      case MovieSortField.releaseDate:
        return 'Release Date';
      case MovieSortField.year:
        return 'Year';
      case MovieSortField.rating:
        return 'Rating';
      case MovieSortField.runtime:
        return 'Runtime';
      case MovieSortField.createdAt:
        return 'Recently Added';
      case MovieSortField.updatedAt:
        return 'Recently Updated';
      case MovieSortField.watchState:
        return 'Watch State';
    }
  }
}

/// Sortable fields for TV Show queries.
///
/// Section 14:
/// - TITLE: Canonical title (or fallback detectedTitle).
/// - FIRST_AIR_DATE: Series premiere air date.
/// - LAST_AIR_DATE: Most recent season air date.
/// - RATING: Community/critic rating.
/// - CREATED_AT: Timestamp when discovered and indexed in library.
/// - UPDATED_AT: Timestamp when last modified.
/// - WATCH_STATE: Derived series consumption state.
enum TvShowSortField {
  title,
  firstAirDate,
  lastAirDate,
  rating,
  createdAt,
  updatedAt,
  watchState;

  String get displayName {
    switch (this) {
      case TvShowSortField.title:
        return 'Title';
      case TvShowSortField.firstAirDate:
        return 'First Air Date';
      case TvShowSortField.lastAirDate:
        return 'Last Air Date';
      case TvShowSortField.rating:
        return 'Rating';
      case TvShowSortField.createdAt:
        return 'Recently Added';
      case TvShowSortField.updatedAt:
        return 'Recently Updated';
      case TvShowSortField.watchState:
        return 'Watch State';
    }
  }
}

/// Sortable fields for Season queries.
///
/// Section 15:
/// - SEASON_NUMBER: Season number ascending (1, 2, 3, ...).
enum SeasonSortField {
  seasonNumber;

  String get displayName => 'Season Number';
}

/// Sortable fields for Episode queries.
///
/// Section 16:
/// - SEASON_NUMBER: Season index.
/// - EPISODE_NUMBER: Episode index within season.
/// - AIR_DATE: Episode broadcast date.
/// - TITLE: Episode name.
/// - CREATED_AT: Timestamp when indexed.
/// - WATCH_STATE: Episode consumption state.
enum EpisodeSortField {
  seasonNumber,
  episodeNumber,
  airDate,
  title,
  createdAt,
  watchState;

  String get displayName {
    switch (this) {
      case EpisodeSortField.seasonNumber:
        return 'Season';
      case EpisodeSortField.episodeNumber:
        return 'Episode';
      case EpisodeSortField.airDate:
        return 'Air Date';
      case EpisodeSortField.title:
        return 'Title';
      case EpisodeSortField.createdAt:
        return 'Recently Added';
      case EpisodeSortField.watchState:
        return 'Watch State';
    }
  }
}

/// Sortable fields for Collection queries.
///
/// Section 47:
/// - NAME: Collection display name.
/// - CREATED_AT: Creation timestamp.
/// - UPDATED_AT: Last curation timestamp.
enum CollectionSortField {
  name,
  createdAt,
  updatedAt;

  String get displayName {
    switch (this) {
      case CollectionSortField.name:
        return 'Name';
      case CollectionSortField.createdAt:
        return 'Date Created';
      case CollectionSortField.updatedAt:
        return 'Recently Updated';
    }
  }
}
