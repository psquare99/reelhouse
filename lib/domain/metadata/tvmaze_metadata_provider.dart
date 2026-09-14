import 'dart:convert';

import 'package:http/http.dart' as http;

import 'metadata_provider.dart';

/// TVmaze public API fallback implementation of [MetadataProvider].
///
/// ### Evaluated Fallback Profile:
/// - **Role**: Primary fallback for TV Shows and episode hierarchies.
/// - **Licensing / Pricing**: 100% Free, open-access community API. No API key required.
/// - **Rate Limits**: 20 requests per 10-second window per IP (HTTP 429 response when exceeded).
/// - **Coverage Strengths**: Exceptionally comprehensive television show, season, and
///   episode data. Rich episode-level descriptions, still images, and original air dates.
/// - **Coverage Limitations**: Strictly television — no movie metadata.
/// - **Fallback Policy**: Activates automatically when TMDB TV searches return no candidates
///   or encounter network / rate-limit failures.
class TvmazeMetadataProvider implements MetadataProvider {
  static const String defaultBaseUrl = 'https://api.tvmaze.com';

  final String baseUrl;
  final http.Client _httpClient;

  TvmazeMetadataProvider({
    this.baseUrl = defaultBaseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  String get id => 'TVmaze';

  @override
  String get displayName => 'TVmaze Open API';

  @override
  bool get isConfigured => true; // Open access; no API key needed

  @override
  Future<List<ProviderCandidate>> searchMovies(
    String title, {
    int? year,
  }) async {
    // TVmaze is strictly television content.
    return [];
  }

  @override
  Future<List<ProviderCandidate>> searchTvShows(String title) async {
    try {
      final uri = Uri.parse('$baseUrl/search/shows')
          .replace(queryParameters: {'q': title});
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      if (data is! List) return [];

      return data
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final show = item['show'] as Map<String, dynamic>?;
            if (show == null) return null;

            final premiered = show['premiered'] as String?;
            int? year;
            if (premiered != null && premiered.length >= 4) {
              year = int.tryParse(premiered.substring(0, 4));
            }

            final image = show['image'] as Map<String, dynamic>?;
            final poster = (image?['medium'] ?? image?['original']) as String?;
            final ratingMap = show['rating'] as Map<String, dynamic>?;
            final rating = (ratingMap?['average'] as num?)?.toDouble();

            final rawSummary = show['summary'] as String?;
            final cleanSummary = rawSummary
                ?.replaceAll(RegExp(r'<[^>]*>'), '')
                .trim();

            return ProviderCandidate(
              providerId: id,
              providerItemId: show['id'].toString(),
              title: show['name'] as String? ?? '',
              year: year,
              overview: cleanSummary,
              posterUrl: poster,
              rating: rating,
            );
          })
          .whereType<ProviderCandidate>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ProviderMovieDetails?> getMovieDetails(String providerItemId) async {
    // TVmaze does not support movies.
    return null;
  }

  @override
  Future<ProviderTvDetails?> getTvShowDetails(String providerItemId) async {
    try {
      final uri = Uri.parse('$baseUrl/shows/$providerItemId');
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) return null;

      final show = json.decode(response.body);
      if (show is! Map<String, dynamic>) return null;

      final premiered = show['premiered'] as String?;
      DateTime? firstAirDate;
      if (premiered != null) {
        firstAirDate = DateTime.tryParse(premiered);
      }

      final image = show['image'] as Map<String, dynamic>?;
      final poster = (image?['medium'] ?? image?['original']) as String?;
      final backdrop = image?['original'] as String?;
      final ratingMap = show['rating'] as Map<String, dynamic>?;
      final rating = (ratingMap?['average'] as num?)?.toDouble();

      final externals = show['externals'] as Map<String, dynamic>?;
      final imdbId = externals?['imdb'] as String?;

      final rawSummary = show['summary'] as String?;
      final cleanSummary = rawSummary
          ?.replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();

      return ProviderTvDetails(
        providerId: id,
        providerItemId: providerItemId,
        title: show['name'] as String? ?? '',
        overview: cleanSummary,
        firstAirDate: firstAirDate,
        posterUrl: poster,
        backdropUrl: backdrop,
        rating: rating,
        imdbId: imdbId,
      );
    } catch (_) {
      return null;
    }
  }
}
