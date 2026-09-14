import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'tmdb_models.dart';

/// Exception thrown when TMDB requests fail.
class TmdbApiException implements Exception {
  final String message;
  final int? statusCode;

  const TmdbApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'TmdbApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// HTTP client for The Movie Database (TMDB) API v3.
///
/// Implements throttling, rate-limit retry with exponential backoff,
/// and secure API key management.
class TmdbApiClient {
  static const String defaultBaseUrl = 'https://api.themoviedb.org/3';
  static const String defaultImageBaseUrl = 'https://image.tmdb.org/t/p';

  final String baseUrl;
  final String imageBaseUrl;
  final http.Client _httpClient;
  final Duration minRequestInterval;
  final int maxRetries;

  String? _apiKey;
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  TmdbApiClient({
    String? apiKey,
    http.Client? httpClient,
    this.baseUrl = defaultBaseUrl,
    this.imageBaseUrl = defaultImageBaseUrl,
    this.minRequestInterval = const Duration(milliseconds: 250),
    this.maxRetries = 3,
  }) : _httpClient = httpClient ?? http.Client(),
       _apiKey = apiKey ?? _resolveDefaultApiKey();

  static String? _resolveDefaultApiKey() {
    try {
      return Platform.environment['TMDB_API_KEY'];
    } catch (_) {
      return null;
    }
  }

  /// Whether an API key is configured.
  bool get hasApiKey => _apiKey != null && _apiKey!.trim().isNotEmpty;

  /// Updates or configures the active API key.
  void setApiKey(String? key) {
    _apiKey = key?.trim();
  }

  /// Alias for setApiKey.
  void updateApiKey(String? key) => setApiKey(key);

  /// Constructs a full poster image URL.
  String? getPosterUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return null;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$imageBaseUrl/$size$cleanPath';
  }

  /// Constructs a full backdrop image URL.
  String? getBackdropUrl(String? path, {String size = 'w1280'}) {
    if (path == null || path.isEmpty) return null;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$imageBaseUrl/$size$cleanPath';
  }

  /// Searches TMDB for movies matching [query] and optional [year].
  Future<List<TmdbMovieSearchResult>> searchMovies(
    String query, {
    int? year,
  }) async {
    final queryParams = <String, String>{
      'query': query,
      'include_adult': 'false',
    };
    if (year != null) {
      queryParams['primary_release_year'] = year.toString();
    }

    final data = await _getJson('/search/movie', queryParams);
    final results = data['results'];
    if (results is! List) return [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(TmdbMovieSearchResult.fromJson)
        .toList();
  }

  /// Fetches detailed metadata for a movie by its TMDB ID.
  Future<TmdbMovieDetails?> getMovieDetails(int tmdbId) async {
    try {
      final data = await _getJson('/movie/$tmdbId', {
        'append_to_response': 'external_ids',
      });
      return TmdbMovieDetails.fromJson(data);
    } on TmdbApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Searches TMDB for TV shows matching [query] and optional [firstAirYear].
  Future<List<TmdbTvSearchResult>> searchTvShows(
    String query, {
    int? firstAirYear,
  }) async {
    final queryParams = <String, String>{
      'query': query,
      'include_adult': 'false',
    };
    if (firstAirYear != null) {
      queryParams['first_air_date_year'] = firstAirYear.toString();
    }

    final data = await _getJson('/search/tv', queryParams);
    final results = data['results'];
    if (results is! List) return [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(TmdbTvSearchResult.fromJson)
        .toList();
  }

  /// Fetches detailed metadata for a TV show by its TMDB ID.
  Future<TmdbTvShowDetails?> getTvShowDetails(int tmdbId) async {
    try {
      final data = await _getJson('/tv/$tmdbId', {
        'append_to_response': 'external_ids',
      });
      return TmdbTvShowDetails.fromJson(data);
    } on TmdbApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Fetches episode metadata for a specific season of a TV show.
  Future<TmdbSeasonDetails?> getSeasonDetails(
    int seriesId,
    int seasonNumber,
  ) async {
    try {
      final data = await _getJson('/tv/$seriesId/season/$seasonNumber', {});
      return TmdbSeasonDetails.fromJson(data);
    } on TmdbApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Internal request executor with throttling, authentication, and exponential backoff.
  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, String> queryParameters,
  ) async {
    if (!hasApiKey) {
      throw const TmdbApiException(
        'TMDB API key is not configured. Please add your key in Settings.',
      );
    }

    final params = Map<String, String>.from(queryParameters);
    // Support either 32-character v3 API Key or Bearer Token
    final isBearer = _apiKey!.length > 40;
    if (!isBearer) {
      params['api_key'] = _apiKey!;
    }

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final headers = <String, String>{'Accept': 'application/json'};
    if (isBearer) {
      headers['Authorization'] = 'Bearer $_apiKey';
    }

    var attempt = 0;
    while (true) {
      attempt++;
      await _throttle();

      http.Response response;
      try {
        response = await _httpClient.get(uri, headers: headers);
      } catch (e) {
        if (attempt >= maxRetries) {
          throw TmdbApiException('Network error communicating with TMDB: $e');
        }
        await Future<void>.delayed(
          Duration(milliseconds: 500 * pow(2, attempt).toInt()),
        );
        continue;
      }

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw TmdbApiException('Failed to decode TMDB response JSON: $e');
        }
      }

      // Handle rate limits (HTTP 429)
      if (response.statusCode == 429) {
        if (attempt >= maxRetries) {
          throw const TmdbApiException('TMDB rate limit exceeded', 429);
        }
        final retryAfterSeconds =
            int.tryParse(response.headers['retry-after'] ?? '') ??
            pow(2, attempt).toInt();
        await Future<void>.delayed(Duration(seconds: retryAfterSeconds));
        continue;
      }

      if (response.statusCode >= 500 && attempt < maxRetries) {
        // Transient server error: retry with backoff
        await Future<void>.delayed(
          Duration(milliseconds: 500 * pow(2, attempt).toInt()),
        );
        continue;
      }

      throw TmdbApiException(
        'TMDB request failed: ${response.body}',
        response.statusCode,
      );
    }
  }

  Future<void> _throttle() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestTime);
    if (elapsed < minRequestInterval) {
      final waitTime = minRequestInterval - elapsed;
      await Future<void>.delayed(waitTime);
    }
    _lastRequestTime = DateTime.now();
  }

  void close() {
    _httpClient.close();
  }
}
