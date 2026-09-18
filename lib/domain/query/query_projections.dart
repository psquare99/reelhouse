import '../models/availability_status.dart';
import '../models/identification_status.dart';
import '../models/watch_state.dart';

/// Lightweight read projection of a Movie optimized for cinema catalogues and grid surfaces.
///
/// Section 41:
/// - Bundles logical entity state with pre-joined availability detail to avoid N+1 UI queries.
class MovieLibraryItem {
  final String id;
  final String? title;
  final String? originalTitle;
  final String detectedTitle;
  final int? year;
  final int? detectedYear;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? rating;
  final int? runtime;
  final bool isFavorite;
  final bool isWatchlist;
  final WatchState watchState;
  final int playbackPositionSeconds;
  final DateTime? lastPlayedAt;
  final IdentificationStatus identificationStatus;
  final AvailabilityStatus availability;
  final int availableSourceCount;
  final List<String> genres;
  final int? tmdbCollectionId;
  final String? tmdbCollectionName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MovieLibraryItem({
    required this.id,
    this.title,
    this.originalTitle,
    required this.detectedTitle,
    this.year,
    this.detectedYear,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.rating,
    this.runtime,
    this.isFavorite = false,
    this.isWatchlist = false,
    this.watchState = WatchState.unwatched,
    this.playbackPositionSeconds = 0,
    this.lastPlayedAt,
    this.identificationStatus = IdentificationStatus.pending,
    this.availability = AvailabilityStatus.unavailable,
    this.availableSourceCount = 0,
    this.genres = const [],
    this.tmdbCollectionId,
    this.tmdbCollectionName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display title: prefers canonical [title], falls back to [detectedTitle].
  String get displayTitle =>
      (title != null && title!.isNotEmpty) ? title! : detectedTitle;

  /// Display year: prefers canonical [year], falls back to [detectedYear].
  int? get displayYear => year ?? detectedYear;

  bool get isPlayable => availability.isPlayable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieLibraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          originalTitle == other.originalTitle &&
          detectedTitle == other.detectedTitle &&
          year == other.year &&
          detectedYear == other.detectedYear &&
          posterPath == other.posterPath &&
          backdropPath == other.backdropPath &&
          overview == other.overview &&
          rating == other.rating &&
          runtime == other.runtime &&
          isFavorite == other.isFavorite &&
          isWatchlist == other.isWatchlist &&
          watchState == other.watchState &&
          playbackPositionSeconds == other.playbackPositionSeconds &&
          lastPlayedAt == other.lastPlayedAt &&
          identificationStatus == other.identificationStatus &&
          availability == other.availability &&
          availableSourceCount == other.availableSourceCount &&
          tmdbCollectionId == other.tmdbCollectionId &&
          tmdbCollectionName == other.tmdbCollectionName &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    originalTitle,
    detectedTitle,
    year,
    detectedYear,
    posterPath,
    backdropPath,
    overview,
    rating,
    runtime,
    isFavorite,
    isWatchlist,
    watchState,
    playbackPositionSeconds,
    lastPlayedAt,
    identificationStatus,
    availability,
    availableSourceCount,
    Object.hashAll(genres),
    tmdbCollectionId,
    tmdbCollectionName,
    createdAt,
    updatedAt,
  ]);

  @override
  String toString() =>
      'MovieLibraryItem($id, "$displayTitle", year: $displayYear, avail: $availability)';
}

/// Lightweight read projection of a TV Show optimized for cinema catalogues and grid surfaces.
///
/// Section 41:
/// - Bundles logical show entity state, episode summary counts, and derived watch state.
class TvShowLibraryItem {
  final String id;
  final String? title;
  final String? originalTitle;
  final String detectedTitle;
  final DateTime? firstAirDate;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? rating;
  final bool isFavorite;
  final bool isWatchlist;
  final IdentificationStatus identificationStatus;
  final WatchState derivedWatchState;
  final AvailabilityStatus availability;
  final int totalSeasons;
  final int totalEpisodes;
  final int availableEpisodes;
  final List<String> genres;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TvShowLibraryItem({
    required this.id,
    this.title,
    this.originalTitle,
    required this.detectedTitle,
    this.firstAirDate,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.rating,
    this.isFavorite = false,
    this.isWatchlist = false,
    this.identificationStatus = IdentificationStatus.pending,
    this.derivedWatchState = WatchState.unwatched,
    this.availability = AvailabilityStatus.unavailable,
    this.totalSeasons = 0,
    this.totalEpisodes = 0,
    this.availableEpisodes = 0,
    this.genres = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display title: prefers canonical [title], falls back to [detectedTitle].
  String get displayTitle =>
      (title != null && title!.isNotEmpty) ? title! : detectedTitle;

  /// Display premiere year.
  int? get displayYear => firstAirDate?.year;

  bool get isPlayable => availability.isPlayable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvShowLibraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          originalTitle == other.originalTitle &&
          detectedTitle == other.detectedTitle &&
          firstAirDate == other.firstAirDate &&
          posterPath == other.posterPath &&
          backdropPath == other.backdropPath &&
          overview == other.overview &&
          rating == other.rating &&
          isFavorite == other.isFavorite &&
          isWatchlist == other.isWatchlist &&
          identificationStatus == other.identificationStatus &&
          derivedWatchState == other.derivedWatchState &&
          availability == other.availability &&
          totalSeasons == other.totalSeasons &&
          totalEpisodes == other.totalEpisodes &&
          availableEpisodes == other.availableEpisodes &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    originalTitle,
    detectedTitle,
    firstAirDate,
    posterPath,
    backdropPath,
    overview,
    rating,
    isFavorite,
    isWatchlist,
    identificationStatus,
    derivedWatchState,
    availability,
    totalSeasons,
    totalEpisodes,
    availableEpisodes,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'TvShowLibraryItem($id, "$displayTitle", year: $displayYear, avail: $availability)';
}

/// Canonical provider-derived grouping of related movies (e.g. Star Wars, Harry Potter).
class FranchiseLibraryItem {
  final int id;
  final String name;
  final String? posterPath;
  final String? backdropPath;
  final int movieCount;
  final int availableMovieCount;

  const FranchiseLibraryItem({
    required this.id,
    required this.name,
    this.posterPath,
    this.backdropPath,
    required this.movieCount,
    this.availableMovieCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FranchiseLibraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          posterPath == other.posterPath &&
          backdropPath == other.backdropPath &&
          movieCount == other.movieCount &&
          availableMovieCount == other.availableMovieCount;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    posterPath,
    backdropPath,
    movieCount,
    availableMovieCount,
  );

  @override
  String toString() =>
      'FranchiseLibraryItem($id, "$name", movies: $movieCount, available: $availableMovieCount)';
}

/// Lightweight read projection of an Episode optimized for season episode lists.
///
/// Section 41:
/// - Bundles episode entity metadata with availability status.
class EpisodeLibraryItem {
  final String id;
  final String seasonId;
  final String? showId;
  final String? showTitle;
  final String? showPosterPath;
  final int seasonNumber;
  final int episodeNumber;
  final String? name;
  final String? overview;
  final String? stillPath;
  final int? runtime;
  final DateTime? airDate;
  final double? rating;
  final WatchState watchState;
  final int playbackPositionSeconds;
  final DateTime? lastPlayedAt;
  final AvailabilityStatus availability;

  const EpisodeLibraryItem({
    required this.id,
    required this.seasonId,
    this.showId,
    this.showTitle,
    this.showPosterPath,
    required this.seasonNumber,
    required this.episodeNumber,
    this.name,
    this.overview,
    this.stillPath,
    this.runtime,
    this.airDate,
    this.rating,
    this.watchState = WatchState.unwatched,
    this.playbackPositionSeconds = 0,
    this.lastPlayedAt,
    this.availability = AvailabilityStatus.unavailable,
  });

  /// Formatted episode designation (e.g. "S01E05").
  String get episodeCode => isExtra
      ? 'EXTRA'
      : 'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';

  /// Display name: fallback to episode designation if title is null.
  String get displayName => (name != null && name!.isNotEmpty)
      ? name!
      : (isExtra ? 'Bonus Feature' : 'Episode $episodeNumber');

  bool get isExtra => seasonNumber < 0;
  bool get isPlayable => availability.isPlayable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeLibraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          seasonId == other.seasonId &&
          showId == other.showId &&
          showTitle == other.showTitle &&
          showPosterPath == other.showPosterPath &&
          seasonNumber == other.seasonNumber &&
          episodeNumber == other.episodeNumber &&
          name == other.name &&
          overview == other.overview &&
          stillPath == other.stillPath &&
          runtime == other.runtime &&
          airDate == other.airDate &&
          rating == other.rating &&
          watchState == other.watchState &&
          playbackPositionSeconds == other.playbackPositionSeconds &&
          lastPlayedAt == other.lastPlayedAt &&
          availability == other.availability;

  @override
  int get hashCode => Object.hashAll([
    id,
    seasonId,
    showId,
    showTitle,
    showPosterPath,
    seasonNumber,
    episodeNumber,
    name,
    overview,
    stillPath,
    runtime,
    airDate,
    rating,
    watchState,
    playbackPositionSeconds,
    lastPlayedAt,
    availability,
  ]);

  @override
  String toString() =>
      'EpisodeLibraryItem($episodeCode - "$displayName", avail: $availability)';
}

/// Lightweight read projection of a Season for show detail season tabs and lists.
class SeasonLibraryItem {
  final String id;
  final String showId;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? posterPath;
  final int episodeCount;
  final DateTime? airDate;

  const SeasonLibraryItem({
    required this.id,
    required this.showId,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.posterPath,
    this.episodeCount = 0,
    this.airDate,
  });

  bool get isExtra => seasonNumber < 0;

  /// Display name: fallback to "Extras", "Specials", or "Season X".
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (seasonNumber < 0) return 'Extras';
    if (seasonNumber == 0) return 'Specials';
    return 'Season $seasonNumber';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonLibraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          showId == other.showId &&
          seasonNumber == other.seasonNumber &&
          name == other.name &&
          overview == other.overview &&
          posterPath == other.posterPath &&
          episodeCount == other.episodeCount &&
          airDate == other.airDate;

  @override
  int get hashCode => Object.hash(
    id,
    showId,
    seasonNumber,
    name,
    overview,
    posterPath,
    episodeCount,
    airDate,
  );

  @override
  String toString() =>
      'SeasonLibraryItem($id, S$seasonNumber "$displayName", eps: $episodeCount)';
}

/// Lightweight read projection of a Collection with precomputed item counts.
class CollectionLibraryItem {
  final String id;
  final String name;
  final String? overview;
  final String? posterPath;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollectionLibraryItem({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.itemCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionLibraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          overview == other.overview &&
          posterPath == other.posterPath &&
          itemCount == other.itemCount &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    overview,
    posterPath,
    itemCount,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'CollectionLibraryItem($id, "$name", items: $itemCount)';
}
