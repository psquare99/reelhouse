import '../../data/network/tmdb_api_client.dart';
import 'metadata_provider.dart';

/// TMDB (The Movie Database) primary implementation of [MetadataProvider].
class TmdbMetadataProvider implements MetadataProvider {
  final TmdbApiClient apiClient;

  const TmdbMetadataProvider({required this.apiClient});

  @override
  String get id => 'TMDB';

  @override
  String get displayName => 'The Movie Database (TMDB)';

  @override
  bool get isConfigured => apiClient.hasApiKey;

  @override
  Future<List<ProviderCandidate>> searchMovies(
    String title, {
    int? year,
  }) async {
    final results = await apiClient.searchMovies(title, year: year);
    return results.map((r) {
      return ProviderCandidate(
        providerId: id,
        providerItemId: r.id.toString(),
        title: r.title,
        originalTitle: r.originalTitle,
        year: r.releaseYear,
        overview: r.overview,
        posterUrl: apiClient.getPosterUrl(r.posterPath),
        backdropUrl: apiClient.getBackdropUrl(r.backdropPath),
        rating: r.voteAverage,
        voteCount: r.voteCount,
      );
    }).toList();
  }

  @override
  Future<List<ProviderCandidate>> searchTvShows(String title) async {
    final results = await apiClient.searchTvShows(title);
    return results.map((r) {
      return ProviderCandidate(
        providerId: id,
        providerItemId: r.id.toString(),
        title: r.name,
        originalTitle: r.originalName,
        year: r.firstAirYear,
        overview: r.overview,
        posterUrl: apiClient.getPosterUrl(r.posterPath),
        backdropUrl: apiClient.getBackdropUrl(r.backdropPath),
        rating: r.voteAverage,
        voteCount: r.voteCount,
      );
    }).toList();
  }

  @override
  Future<ProviderMovieDetails?> getMovieDetails(String providerItemId) async {
    final tmdbId = int.tryParse(providerItemId);
    if (tmdbId == null) return null;

    final details = await apiClient.getMovieDetails(tmdbId);
    if (details == null) return null;

    DateTime? releaseDate;
    if (details.releaseDate != null) {
      releaseDate = DateTime.tryParse(details.releaseDate!);
    }

    return ProviderMovieDetails(
      providerId: id,
      providerItemId: details.id.toString(),
      title: details.title,
      originalTitle: details.originalTitle,
      overview: details.overview,
      releaseYear: details.releaseYear,
      releaseDate: releaseDate,
      runtime: details.runtime,
      posterUrl: apiClient.getPosterUrl(details.posterPath),
      backdropUrl: apiClient.getBackdropUrl(details.backdropPath),
      rating: details.voteAverage,
      voteCount: details.voteCount,
      imdbId: details.imdbId,
      genres: details.genres,
      tmdbCollectionId: details.tmdbCollectionId,
      tmdbCollectionName: details.tmdbCollectionName,
      tmdbCollectionPosterPath: apiClient.getPosterUrl(
        details.tmdbCollectionPosterPath,
      ),
      tmdbCollectionBackdropPath: apiClient.getBackdropUrl(
        details.tmdbCollectionBackdropPath,
      ),
    );
  }

  @override
  Future<ProviderTvDetails?> getTvShowDetails(String providerItemId) async {
    final tmdbId = int.tryParse(providerItemId);
    if (tmdbId == null) return null;

    final details = await apiClient.getTvShowDetails(tmdbId);
    if (details == null) return null;

    DateTime? firstAirDate;
    if (details.firstAirDate != null) {
      firstAirDate = DateTime.tryParse(details.firstAirDate!);
    }

    return ProviderTvDetails(
      providerId: id,
      providerItemId: details.id.toString(),
      title: details.name,
      originalTitle: details.originalName,
      overview: details.overview,
      firstAirDate: firstAirDate,
      posterUrl: apiClient.getPosterUrl(details.posterPath),
      backdropUrl: apiClient.getBackdropUrl(details.backdropPath),
      rating: details.voteAverage,
      imdbId: details.imdbId,
      genres: details.genres,
    );
  }
}
