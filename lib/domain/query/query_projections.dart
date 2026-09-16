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
  final String detectedTitle;
  final int? year;
  final int? detectedYear;
  final String? posterPath;
  final String? backdropPath;
  final double? rating;
  final int? runtime;
  final bool isFavorite;
  final bool isWatchlist;
  final WatchState watchState;
  final int playbackPositionSeconds;
  final IdentificationStatus identificationStatus;
  final AvailabilityStatus availability;
  final int availableSourceCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MovieLibraryItem({
    required this.id,
    this.title,
    required this.detectedTitle,
    this.year,
    this.detectedYear,
    this.posterPath,
    this.backdropPath,
    this.rating,
    this.runtime,
    this.isFavorite = false,
    this.isWatchlist = false,
    this.watchState = WatchState.unwatched,
    this.playbackPositionSeconds = 0,
    this.identificationStatus = IdentificationStatus.pending,
    this.availability = AvailabilityStatus.unavailable,
    this.availableSourceCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display title: prefers canonical [title], falls back to [detectedTitle].
  String get displayTitle => (title != null && title!.isNotEmpty) ? title! : detectedTitle;

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
          detectedTitle == other.detectedTitle &&
          year == other.year &&
          detectedYear == other.detectedYear &&
          posterPath == other.posterPath &&
          backdropPath == other.backdropPath &&
          rating == other.rating &&
          runtime == other.runtime &&
          isFavorite == other.isFavorite &&
          isWatchlist == other.isWatchlist &&
          watchState == other.watchState &&
          playbackPositionSeconds == other.playbackPositionSeconds &&
          identificationStatus == other.identificationStatus &&
          availability == other.availability &&
          availableSourceCount == other.availableSourceCount &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        detectedTitle,
        year,
        detectedYear,
        posterPath,
        backdropPath,
        rating,
        runtime,
        isFavorite,
        isWatchlist,
        watchState,
        playbackPositionSeconds,
        identificationStatus,
        availability,
        availableSourceCount,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'MovieLibraryItem($id, "$displayTitle", year: $displayYear, avail: $availability)';
}

/// Lightweight read projection of a TV Show optimized for cinema catalogues and grid surfaces.
///
/// Section 41:
/// - Bundles logical show entity state, episode summary counts, and derived watch state.
class TvShowLibraryItem {
  final String id;
  final String? title;
  final String detectedTitle;
  final DateTime? firstAirDate;
  final String? posterPath;
  final String? backdropPath;
  final double? rating;
  final bool isFavorite;
  final bool isWatchlist;
  final IdentificationStatus identificationStatus;
  final WatchState derivedWatchState;
  final AvailabilityStatus availability;
  final int totalSeasons;
  final int totalEpisodes;
  final int availableEpisodes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TvShowLibraryItem({
    required this.id,
    this.title,
    required this.detectedTitle,
    this.firstAirDate,
    this.posterPath,
    this.backdropPath,
    this.rating,
    this.isFavorite = false,
    this.isWatchlist = false,
    this.identificationStatus = IdentificationStatus.pending,
    this.derivedWatchState = WatchState.unwatched,
    this.availability = AvailabilityStatus.unavailable,
    this.totalSeasons = 0,
    this.totalEpisodes = 0,
    this.availableEpisodes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display title: prefers canonical [title], falls back to [detectedTitle].
  String get displayTitle => (title != null && title!.isNotEmpty) ? title! : detectedTitle;

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
          detectedTitle == other.detectedTitle &&
          firstAirDate == other.firstAirDate &&
          posterPath == other.posterPath &&
          backdropPath == other.backdropPath &&
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
        detectedTitle,
        firstAirDate,
        posterPath,
        backdropPath,
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
      'TvShowLibraryItem($id, "$displayTitle", seasons: $totalSeasons, eps: $totalEpisodes, avail: $availability)';
}

/// Lightweight read projection of an Episode optimized for season episode lists.
///
/// Section 41:
/// - Bundles episode entity metadata with availability status.
class EpisodeLibraryItem {
  final String id;
  final String seasonId;
  final String? showId;
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
  final AvailabilityStatus availability;

  const EpisodeLibraryItem({
    required this.id,
    required this.seasonId,
    this.showId,
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
    this.availability = AvailabilityStatus.unavailable,
  });

  /// Formatted episode designation (e.g. "S01E05").
  String get episodeCode =>
      'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';

  /// Display name: fallback to episode designation if title is null.
  String get displayName => (name != null && name!.isNotEmpty) ? name! : 'Episode $episodeNumber';

  bool get isPlayable => availability.isPlayable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeLibraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          seasonId == other.seasonId &&
          showId == other.showId &&
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
          availability == other.availability;

  @override
  int get hashCode => Object.hash(
        id,
        seasonId,
        showId,
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
        availability,
      );

  @override
  String toString() => 'EpisodeLibraryItem($episodeCode - "$displayName", avail: $availability)';
}
