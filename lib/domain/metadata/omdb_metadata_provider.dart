import 'dart:convert';

import 'package:http/http.dart' as http;

import 'metadata_provider.dart';

/// OMDb API fallback implementation of [MetadataProvider].
///
/// ### Evaluated Fallback Profile:
/// - **Role**: Secondary fallback for Movies (IMDb identifiers, IMDb ratings).
/// - **Licensing / Pricing**: Free tier permits up to 1,000 requests per day.
///   Requires a personal API key from omdbapi.com.
/// - **Coverage Strengths**: Authoritative IMDb IDs, Rotten Tomatoes & Metacritic scores.
/// - **Coverage Limitations**: Lacks high-resolution backdrop fanart, lacks multi-language
///   localized titles, and TV episode hierarchies require extensive nested queries.
/// - **Fallback Policy**: Never replaces existing TMDB metadata with lower-resolution
///   OMDb artwork. Used strictly when TMDB lookup fails or is rate-limited.
class OmdbMetadataProvider implements MetadataProvider {
  static const String defaultBaseUrl = 'https://www.omdbapi.com';

  final String baseUrl;
  final String? apiKey;
  final http.Client _httpClient;

  OmdbMetadataProvider({
    this.baseUrl = defaultBaseUrl,
    this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  String get id => 'OMDb';

  @override
  String get displayName => 'Open Movie Database (OMDb)';

  @override
  bool get isConfigured => apiKey != null && apiKey!.trim().isNotEmpty;

  @override
  Future<List<ProviderCandidate>> searchMovies(
    String title, {
    int? year,
  }) async {
    if (!isConfigured) return [];

    try {
      final queryParams = <String, String>{
        's': title,
        'type': 'movie',
        'apikey': apiKey!,
      };
      if (year != null) {
        queryParams['y'] = year.toString();
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic> || data['Response'] == 'False') {
        return [];
      }

      final searchList = data['Search'];
      if (searchList is! List) return [];

      return searchList
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final yearStr = item['Year'] as String?;
            final parsedYear = yearStr != null
                ? int.tryParse(yearStr.replaceAll(RegExp(r'\D'), ''))
                : null;
            final poster = item['Poster'] as String?;
            final validPoster = (poster != null && poster != 'N/A')
                ? poster
                : null;

            return ProviderCandidate(
              providerId: id,
              providerItemId: item['imdbID'] as String? ?? '',
              title: item['Title'] as String? ?? '',
              year: parsedYear,
              posterUrl: validPoster,
            );
          })
          .where((c) => c.providerItemId.isNotEmpty && c.title.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ProviderCandidate>> searchTvShows(String title) async {
    if (!isConfigured) return [];

    try {
      final queryParams = <String, String>{
        's': title,
        'type': 'series',
        'apikey': apiKey!,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic> || data['Response'] == 'False') {
        return [];
      }

      final searchList = data['Search'];
      if (searchList is! List) return [];

      return searchList
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final yearStr = item['Year'] as String?;
            final parsedYear = yearStr != null
                ? int.tryParse(
                    yearStr.split('–').first.replaceAll(RegExp(r'\D'), ''),
                  )
                : null;
            final poster = item['Poster'] as String?;
            final validPoster = (poster != null && poster != 'N/A')
                ? poster
                : null;

            return ProviderCandidate(
              providerId: id,
              providerItemId: item['imdbID'] as String? ?? '',
              title: item['Title'] as String? ?? '',
              year: parsedYear,
              posterUrl: validPoster,
            );
          })
          .where((c) => c.providerItemId.isNotEmpty && c.title.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ProviderMovieDetails?> getMovieDetails(String providerItemId) async {
    if (!isConfigured) return null;

    try {
      final queryParams = <String, String>{
        'i': providerItemId,
        'plot': 'full',
        'apikey': apiKey!,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic> || data['Response'] == 'False') {
        return null;
      }

      final yearStr = data['Year'] as String?;
      final parsedYear = yearStr != null
          ? int.tryParse(yearStr.replaceAll(RegExp(r'\D'), ''))
          : null;
      final poster = data['Poster'] as String?;
      final validPoster = (poster != null && poster != 'N/A') ? poster : null;
      final ratingStr = data['imdbRating'] as String?;
      final rating = (ratingStr != null && ratingStr != 'N/A')
          ? double.tryParse(ratingStr)
          : null;
      final votesStr = data['imdbVotes'] as String?;
      final voteCount = (votesStr != null && votesStr != 'N/A')
          ? int.tryParse(votesStr.replaceAll(',', ''))
          : null;

      int? runtimeMinutes;
      final runtimeStr = data['Runtime'] as String?;
      if (runtimeStr != null && runtimeStr != 'N/A') {
        final match = RegExp(r'(\d+)').firstMatch(runtimeStr);
        if (match != null) {
          runtimeMinutes = int.tryParse(match.group(1)!);
        }
      }

      return ProviderMovieDetails(
        providerId: id,
        providerItemId: providerItemId,
        title: data['Title'] as String? ?? '',
        overview: data['Plot'] != 'N/A' ? data['Plot'] as String? : null,
        releaseYear: parsedYear,
        runtime: runtimeMinutes,
        posterUrl: validPoster,
        rating: rating,
        voteCount: voteCount,
        imdbId: providerItemId.startsWith('tt') ? providerItemId : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ProviderTvDetails?> getTvShowDetails(String providerItemId) async {
    if (!isConfigured) return null;

    try {
      final queryParams = <String, String>{
        'i': providerItemId,
        'plot': 'full',
        'apikey': apiKey!,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic> || data['Response'] == 'False') {
        return null;
      }

      final poster = data['Poster'] as String?;
      final validPoster = (poster != null && poster != 'N/A') ? poster : null;
      final ratingStr = data['imdbRating'] as String?;
      final rating = (ratingStr != null && ratingStr != 'N/A')
          ? double.tryParse(ratingStr)
          : null;

      return ProviderTvDetails(
        providerId: id,
        providerItemId: providerItemId,
        title: data['Title'] as String? ?? '',
        overview: data['Plot'] != 'N/A' ? data['Plot'] as String? : null,
        posterUrl: validPoster,
        rating: rating,
        imdbId: providerItemId.startsWith('tt') ? providerItemId : null,
      );
    } catch (_) {
      return null;
    }
  }
}
