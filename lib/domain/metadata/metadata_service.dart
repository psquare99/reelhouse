import '../../data/database/database.dart';
import '../../data/network/tmdb_api_client.dart';
import '../../data/network/tmdb_models.dart';
import 'image_cache_service.dart';
import 'metadata_matcher.dart';

/// Summary statistics for a batch metadata identification pass.
class MetadataPipelineSummary {
  final int totalProcessed;
  final int automaticallyMatched;
  final int routedToVerification;
  final int errors;

  const MetadataPipelineSummary({
    required this.totalProcessed,
    required this.automaticallyMatched,
    required this.routedToVerification,
    required this.errors,
  });

  @override
  String toString() =>
      'MetadataPipelineSummary(processed: $totalProcessed, matched: $automaticallyMatched, needsVerification: $routedToVerification, errors: $errors)';
}

/// Metadata Pipeline orchestrator for REELHOUSE.
///
/// Implements Sections 13, 14, 15, and 44:
/// - Fetches candidates from TMDB API with rate-limiting and backoff.
/// - Performs confidence evaluation.
/// - Automatically matches high-confidence media.
/// - Caches poster and backdrop images to local disk.
/// - Routes ambiguous or low-confidence media to the "Needs Verification" queue.
class MetadataService {
  final AppDatabase database;
  final TmdbApiClient tmdbClient;
  final MetadataMatcher matcher;
  final ImageCacheService imageCacheService;

  MetadataService({
    required this.database,
    required this.tmdbClient,
    this.matcher = const MetadataMatcher(),
    required this.imageCacheService,
  });

  /// Identifies and enriches a single [Movie].
  Future<MatchDecision<TmdbMovieSearchResult>> identifyMovie(
    Movie movie,
  ) async {
    if (!tmdbClient.hasApiKey) {
      return const MatchDecision(
        type: MatchDecisionType.needsVerification,
        reason: 'TMDB API key is not configured.',
      );
    }

    try {
      final searchTitle = movie.title ?? movie.detectedTitle;
      final searchYear = movie.year ?? movie.detectedYear;
      final candidates = await tmdbClient.searchMovies(
        searchTitle,
        year: searchYear,
      );

      final decision = matcher.evaluateMovieCandidates(
        detectedTitle: movie.detectedTitle,
        detectedYear: movie.detectedYear ?? movie.year,
        candidates: candidates,
      );

      if (decision.isAutomatic && decision.bestMatch != null) {
        await applyMovieMatch(movie.id, decision.bestMatch!);
      }

      return decision;
    } catch (e) {
      return MatchDecision(
        type: MatchDecisionType.needsVerification,
        reason: 'Identification error: $e',
      );
    }
  }

  /// Manually or automatically applies a chosen TMDB candidate to a [Movie].
  Future<void> applyMovieMatch(
    String movieId,
    TmdbMovieSearchResult candidate, {
    bool isManual = false,
  }) async {
    final details = await tmdbClient.getMovieDetails(candidate.id);
    final tmdbItem =
        details ??
        TmdbMovieDetails(
          id: candidate.id,
          title: candidate.title,
          originalTitle: candidate.originalTitle,
          overview: candidate.overview,
          releaseDate: candidate.releaseDate,
          releaseYear: candidate.releaseYear,
          posterPath: candidate.posterPath,
          backdropPath: candidate.backdropPath,
          voteAverage: candidate.voteAverage,
          voteCount: candidate.voteCount,
        );

    // Cache poster and backdrop locally on disk
    String? localPoster;
    if (tmdbItem.posterPath != null) {
      final remoteUrl = tmdbClient.getPosterUrl(tmdbItem.posterPath);
      localPoster = await imageCacheService.cachePoster(
        remoteUrl,
        'movie_$movieId',
      );
    }

    String? localBackdrop;
    if (tmdbItem.backdropPath != null) {
      final remoteUrl = tmdbClient.getBackdropUrl(tmdbItem.backdropPath);
      localBackdrop = await imageCacheService.cacheBackdrop(
        remoteUrl,
        'movie_$movieId',
      );
    }

    DateTime? parsedRelDate;
    if (tmdbItem.releaseDate != null) {
      parsedRelDate = DateTime.tryParse(tmdbItem.releaseDate!);
    }

    await database.updateMovieMetadata(
      movieId,
      tmdbId: tmdbItem.id,
      imdbId: tmdbItem.imdbId,
      originalTitle: tmdbItem.originalTitle,
      overview: tmdbItem.overview,
      runtime: tmdbItem.runtime,
      releaseDate: parsedRelDate,
      posterPath: localPoster ?? tmdbItem.posterPath,
      backdropPath: localBackdrop ?? tmdbItem.backdropPath,
      rating: tmdbItem.voteAverage,
      voteCount: tmdbItem.voteCount,
      metadataId: isManual
          ? 'manual:tmdb:${tmdbItem.id}'
          : 'tmdb:movie:${tmdbItem.id}',
    );
  }

  /// Identifies and enriches a single [TvShow] along with its seasons and episodes.
  Future<MatchDecision<TmdbTvSearchResult>> identifyTvShow(TvShow show) async {
    if (!tmdbClient.hasApiKey) {
      return const MatchDecision(
        type: MatchDecisionType.needsVerification,
        reason: 'TMDB API key is not configured.',
      );
    }

    try {
      final searchTitle = show.title ?? show.detectedTitle;
      final candidates = await tmdbClient.searchTvShows(searchTitle);

      final decision = matcher.evaluateTvCandidates(
        detectedTitle: show.detectedTitle,
        candidates: candidates,
      );

      if (decision.isAutomatic && decision.bestMatch != null) {
        await applyTvShowMatch(show.id, decision.bestMatch!);
      }

      return decision;
    } catch (e) {
      return MatchDecision(
        type: MatchDecisionType.needsVerification,
        reason: 'TV identification error: $e',
      );
    }
  }

  /// Manually or automatically applies a chosen TMDB candidate to a [TvShow].
  Future<void> applyTvShowMatch(
    String showId,
    TmdbTvSearchResult candidate, {
    bool isManual = false,
  }) async {
    final details = await tmdbClient.getTvShowDetails(candidate.id);
    final tmdbItem =
        details ??
        TmdbTvShowDetails(
          id: candidate.id,
          name: candidate.name,
          originalName: candidate.originalName,
          overview: candidate.overview,
          firstAirDate: candidate.firstAirDate,
          firstAirYear: candidate.firstAirYear,
          posterPath: candidate.posterPath,
          backdropPath: candidate.backdropPath,
          voteAverage: candidate.voteAverage,
          voteCount: candidate.voteCount,
        );

    String? localPoster;
    if (tmdbItem.posterPath != null) {
      final remoteUrl = tmdbClient.getPosterUrl(tmdbItem.posterPath);
      localPoster = await imageCacheService.cachePoster(
        remoteUrl,
        'tv_$showId',
      );
    }

    String? localBackdrop;
    if (tmdbItem.backdropPath != null) {
      final remoteUrl = tmdbClient.getBackdropUrl(tmdbItem.backdropPath);
      localBackdrop = await imageCacheService.cacheBackdrop(
        remoteUrl,
        'tv_$showId',
      );
    }

    DateTime? firstAirDate;
    if (tmdbItem.firstAirDate != null) {
      firstAirDate = DateTime.tryParse(tmdbItem.firstAirDate!);
    }

    await database.updateTvShowMetadata(
      showId,
      tmdbId: tmdbItem.id,
      imdbId: tmdbItem.imdbId,
      originalTitle: tmdbItem.originalName,
      overview: tmdbItem.overview,
      firstAirDate: firstAirDate,
      posterPath: localPoster ?? tmdbItem.posterPath,
      backdropPath: localBackdrop ?? tmdbItem.backdropPath,
      rating: tmdbItem.voteAverage,
      metadataId: isManual
          ? 'manual:tmdb:${tmdbItem.id}'
          : 'tmdb:tv:${tmdbItem.id}',
    );

    // Enrich existing seasons and episodes
    final seasons = await (database.select(
      database.seasons,
    )..where((s) => s.showId.equals(showId))).get();

    for (final season in seasons) {
      try {
        final seasonDetails = await tmdbClient.getSeasonDetails(
          tmdbItem.id,
          season.seasonNumber,
        );
        if (seasonDetails != null) {
          final episodes = await (database.select(
            database.episodes,
          )..where((e) => e.seasonId.equals(season.id))).get();

          for (final ep in episodes) {
            final tmdbEp = seasonDetails.episodes
                .cast<TmdbEpisodeDetails?>()
                .firstWhere(
                  (te) => te?.episodeNumber == ep.episodeNumber,
                  orElse: () => null,
                );
            if (tmdbEp != null) {
              DateTime? epAirDate;
              if (tmdbEp.airDate != null) {
                epAirDate = DateTime.tryParse(tmdbEp.airDate!);
              }

              await database.updateEpisodeMetadata(
                ep.id,
                tmdbId: tmdbEp.id,
                name: tmdbEp.name,
                overview: tmdbEp.overview,
                runtime: tmdbEp.runtime,
                airDate: epAirDate,
                rating: tmdbEp.voteAverage,
              );
            }
          }
        }
      } catch (_) {
        // Continue gracefully if a season fetch fails
      }
    }
  }

  /// Runs identification on all currently unmatched movies and shows in the database.
  Future<MetadataPipelineSummary> identifyAllUnmatched({
    void Function(int current, int total, String currentTitle)? onProgress,
  }) async {
    final unmatchedMovies = await database.getUnmatchedMovies();
    final unmatchedShows = await database.getUnmatchedTvShows();
    final total = unmatchedMovies.length + unmatchedShows.length;

    var processed = 0;
    var matched = 0;
    var routedToVerification = 0;
    var errors = 0;

    for (final movie in unmatchedMovies) {
      processed++;
      onProgress?.call(processed, total, movie.title ?? movie.detectedTitle);

      try {
        final decision = await identifyMovie(movie);
        if (decision.isAutomatic) {
          matched++;
        } else {
          routedToVerification++;
        }
      } catch (_) {
        errors++;
      }
    }

    for (final show in unmatchedShows) {
      processed++;
      onProgress?.call(processed, total, show.title ?? show.detectedTitle);

      try {
        final decision = await identifyTvShow(show);
        if (decision.isAutomatic) {
          matched++;
        } else {
          routedToVerification++;
        }
      } catch (_) {
        errors++;
      }
    }

    return MetadataPipelineSummary(
      totalProcessed: processed,
      automaticallyMatched: matched,
      routedToVerification: routedToVerification,
      errors: errors,
    );
  }
}
