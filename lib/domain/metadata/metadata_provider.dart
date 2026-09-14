/// Standardized candidate model across all metadata providers (TMDB, OMDb, TVmaze).
class ProviderCandidate {
  final String providerId; // 'TMDB' | 'OMDb' | 'TVmaze'
  final String providerItemId; // External ID on that provider
  final String title;
  final String? originalTitle;
  final int? year;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final double? rating;
  final int? voteCount;

  const ProviderCandidate({
    required this.providerId,
    required this.providerItemId,
    required this.title,
    this.originalTitle,
    this.year,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.voteCount,
  });

  @override
  String toString() =>
      'ProviderCandidate($providerId:$providerItemId, "$title" ($year))';
}

/// Detailed movie data returned by a metadata provider.
class ProviderMovieDetails {
  final String providerId;
  final String providerItemId;
  final String title;
  final String? originalTitle;
  final String? overview;
  final int? releaseYear;
  final DateTime? releaseDate;
  final int? runtime;
  final String? posterUrl;
  final String? backdropUrl;
  final double? rating;
  final int? voteCount;
  final String? imdbId;

  const ProviderMovieDetails({
    required this.providerId,
    required this.providerItemId,
    required this.title,
    this.originalTitle,
    this.overview,
    this.releaseYear,
    this.releaseDate,
    this.runtime,
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.voteCount,
    this.imdbId,
  });
}

/// Detailed TV show data returned by a metadata provider.
class ProviderTvDetails {
  final String providerId;
  final String providerItemId;
  final String title;
  final String? originalTitle;
  final String? overview;
  final DateTime? firstAirDate;
  final String? posterUrl;
  final String? backdropUrl;
  final double? rating;
  final String? imdbId;

  const ProviderTvDetails({
    required this.providerId,
    required this.providerItemId,
    required this.title,
    this.originalTitle,
    this.overview,
    this.firstAirDate,
    this.posterUrl,
    this.backdropUrl,
    this.rating,
    this.imdbId,
  });
}

/// Standard contract for metadata providers (TMDB, OMDb, TVmaze).
///
/// Designed to support primary and fallback metadata sources while
/// maintaining strict source provenance.
abstract class MetadataProvider {
  /// Unique identifier of the provider (e.g. 'TMDB', 'OMDb', 'TVmaze').
  String get id;

  /// User-facing display name.
  String get displayName;

  /// Whether this provider is currently configured and operational.
  bool get isConfigured;

  /// Search movies by title and optional year.
  Future<List<ProviderCandidate>> searchMovies(String title, {int? year});

  /// Search TV shows by title.
  Future<List<ProviderCandidate>> searchTvShows(String title);

  /// Fetch full movie details by provider item ID.
  Future<ProviderMovieDetails?> getMovieDetails(String providerItemId);

  /// Fetch full TV show details by provider item ID.
  Future<ProviderTvDetails?> getTvShowDetails(String providerItemId);
}
