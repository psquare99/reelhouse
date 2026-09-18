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
      } else if (decision.needsVerification) {
        await database.updateMovieIdentificationStatus(
          movie.id,
          'NEEDS_VERIFICATION',
        );
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
    // Check if another Movie is already matched to this TMDB ID (Canonical Identity Convergence)
    final existingMovie = await database.findMovieByTmdbId(candidate.id);
    if (existingMovie != null && existingMovie.id != movieId) {
      await database.mergeMovies(
        sourceMovieId: movieId,
        targetMovieId: existingMovie.id,
      );
      return;
    }

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
    String? remotePosterUrl;
    if (tmdbItem.posterPath != null) {
      remotePosterUrl = tmdbClient.getPosterUrl(tmdbItem.posterPath);
      localPoster = await imageCacheService.cachePoster(
        remotePosterUrl,
        'movie_$movieId',
      );
    }

    String? localBackdrop;
    String? remoteBackdropUrl;
    if (tmdbItem.backdropPath != null) {
      remoteBackdropUrl = tmdbClient.getBackdropUrl(tmdbItem.backdropPath);
      localBackdrop = await imageCacheService.cacheBackdrop(
        remoteBackdropUrl,
        'movie_$movieId',
      );
    }

    DateTime? parsedRelDate;
    if (tmdbItem.releaseDate != null) {
      parsedRelDate = DateTime.tryParse(tmdbItem.releaseDate!);
    }

    await database.updateMovieMetadata(
      movieId,
      title: tmdbItem.title,
      year: tmdbItem.releaseYear,
      identificationStatus: 'IDENTIFIED',
      tmdbId: tmdbItem.id,
      imdbId: tmdbItem.imdbId,
      originalTitle: tmdbItem.originalTitle,
      overview: tmdbItem.overview,
      runtime: tmdbItem.runtime,
      releaseDate: parsedRelDate,
      posterPath: localPoster ?? remotePosterUrl ?? tmdbItem.posterPath,
      backdropPath: localBackdrop ?? remoteBackdropUrl ?? tmdbItem.backdropPath,
      rating: tmdbItem.voteAverage,
      voteCount: tmdbItem.voteCount,
      metadataId: isManual
          ? 'manual:tmdb:${tmdbItem.id}'
          : 'tmdb:movie:${tmdbItem.id}',
      metadataProvider: 'TMDB',
      providerItemId: tmdbItem.id.toString(),
      metadataUpdatedAt: DateTime.now(),
      genres: tmdbItem.genres.isNotEmpty ? tmdbItem.genres.join(', ') : null,
      tmdbCollectionId: tmdbItem.tmdbCollectionId,
      tmdbCollectionName: tmdbItem.tmdbCollectionName,
      tmdbCollectionPosterPath: tmdbItem.tmdbCollectionPosterPath != null
          ? tmdbClient.getPosterUrl(tmdbItem.tmdbCollectionPosterPath)
          : null,
      tmdbCollectionBackdropPath: tmdbItem.tmdbCollectionBackdropPath != null
          ? tmdbClient.getBackdropUrl(tmdbItem.tmdbCollectionBackdropPath)
          : null,
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
      } else if (decision.needsVerification) {
        await database.updateTvShowIdentificationStatus(
          show.id,
          'NEEDS_VERIFICATION',
        );
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
    // Check if another TvShow is already matched to this TMDB ID (Canonical Identity Convergence)
    final existingShow = await database.findTvShowByTmdbId(candidate.id);
    if (existingShow != null && existingShow.id != showId) {
      await database.mergeTvShows(
        sourceShowId: showId,
        targetShowId: existingShow.id,
      );

      final targetShow = await database.findTvShowById(existingShow.id);
      if (targetShow != null) {
        await enrichTvShowEpisodes(targetShow);
      }
      return;
    }

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
    String? remotePosterUrl;
    if (tmdbItem.posterPath != null) {
      remotePosterUrl = tmdbClient.getPosterUrl(tmdbItem.posterPath);
      localPoster = await imageCacheService.cachePoster(
        remotePosterUrl,
        'tv_$showId',
      );
    }

    String? localBackdrop;
    String? remoteBackdropUrl;
    if (tmdbItem.backdropPath != null) {
      remoteBackdropUrl = tmdbClient.getBackdropUrl(tmdbItem.backdropPath);
      localBackdrop = await imageCacheService.cacheBackdrop(
        remoteBackdropUrl,
        'tv_$showId',
      );
    }

    DateTime? firstAirDate;
    if (tmdbItem.firstAirDate != null) {
      firstAirDate = DateTime.tryParse(tmdbItem.firstAirDate!);
    }

    await database.updateTvShowMetadata(
      showId,
      title: tmdbItem.name,
      identificationStatus: 'IDENTIFIED',
      tmdbId: tmdbItem.id,
      imdbId: tmdbItem.imdbId,
      originalTitle: tmdbItem.originalName,
      overview: tmdbItem.overview,
      firstAirDate: firstAirDate,
      posterPath: localPoster ?? remotePosterUrl ?? tmdbItem.posterPath,
      backdropPath: localBackdrop ?? remoteBackdropUrl ?? tmdbItem.backdropPath,
      rating: tmdbItem.voteAverage,
      metadataId: isManual
          ? 'manual:tmdb:${tmdbItem.id}'
          : 'tmdb:tv:${tmdbItem.id}',
      metadataProvider: 'TMDB',
      providerItemId: tmdbItem.id.toString(),
      metadataUpdatedAt: DateTime.now(),
      genres: tmdbItem.genres.isNotEmpty ? tmdbItem.genres.join(', ') : null,
    );

    // Enrich existing seasons and episodes
    final updatedShow = await database.findTvShowById(showId);
    if (updatedShow != null) {
      await enrichTvShowEpisodes(updatedShow);
    }
  }

  /// Enriches seasons and episodes for an identified [TvShow] with TMDB metadata & stills.
  Future<int> enrichTvShowEpisodes(TvShow show) async {
    if (show.tmdbId == null) return 0;
    final tmdbId = show.tmdbId!;
    var enrichedCount = 0;

    final seasons = await (database.select(
      database.seasons,
    )..where((s) => s.showId.equals(show.id))).get();

    for (final season in seasons) {
      try {
        final seasonDetails = await tmdbClient.getSeasonDetails(
          tmdbId,
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

              String? localStill;
              String? remoteStillUrl;
              if (tmdbEp.stillPath != null && tmdbEp.stillPath!.isNotEmpty) {
                remoteStillUrl = tmdbClient.getBackdropUrl(
                  tmdbEp.stillPath,
                  size: 'w780',
                );
                localStill = await imageCacheService.cacheBackdrop(
                  remoteStillUrl,
                  'ep_${ep.id}',
                );
              }

              await database.updateEpisodeMetadata(
                ep.id,
                tmdbId: tmdbEp.id,
                name: tmdbEp.name,
                overview: tmdbEp.overview,
                runtime: tmdbEp.runtime,
                airDate: epAirDate,
                stillPath: localStill ?? remoteStillUrl ?? tmdbEp.stillPath,
                rating: tmdbEp.voteAverage,
              );
              enrichedCount++;
            }
          }
        }
      } catch (_) {
        // Continue gracefully if a season fetch fails
      }
    }

    return enrichedCount;
  }

  /// Enriches an already-identified [Movie] with missing metadata (genres, TMDB collections)
  /// without altering its canonical identity, local media sources, or watch state.
  Future<bool> enrichMovieMetadata(Movie movie) async {
    if (!tmdbClient.hasApiKey || movie.tmdbId == null) return false;

    try {
      final details = await tmdbClient.getMovieDetails(movie.tmdbId!);
      if (details == null) return false;

      await database.updateMovieMetadata(
        movie.id,
        tmdbId: details.id,
        genres: details.genres.isNotEmpty ? details.genres.join(', ') : null,
        tmdbCollectionId: details.tmdbCollectionId,
        tmdbCollectionName: details.tmdbCollectionName,
        tmdbCollectionPosterPath: details.tmdbCollectionPosterPath != null
            ? tmdbClient.getPosterUrl(details.tmdbCollectionPosterPath)
            : null,
        tmdbCollectionBackdropPath: details.tmdbCollectionBackdropPath != null
            ? tmdbClient.getBackdropUrl(details.tmdbCollectionBackdropPath)
            : null,
        imdbId: movie.imdbId ?? details.imdbId,
        runtime: movie.runtime ?? details.runtime,
        overview: movie.overview ?? details.overview,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Enriches an already-identified [TvShow] with missing metadata (genres)
  /// without altering its canonical identity, seasons, episodes, or sources.
  Future<bool> enrichTvShowMetadata(TvShow show) async {
    if (!tmdbClient.hasApiKey || show.tmdbId == null) return false;

    try {
      final details = await tmdbClient.getTvShowDetails(show.tmdbId!);
      if (details == null) return false;

      await database.updateTvShowMetadata(
        show.id,
        tmdbId: details.id,
        genres: details.genres.isNotEmpty ? details.genres.join(', ') : null,
        imdbId: show.imdbId ?? details.imdbId,
        overview: show.overview ?? details.overview,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// One-time or background backfill for existing identified media lacking newly supported metadata
  /// (such as genres or franchise collections added in schema v5).
  Future<MetadataPipelineSummary> backfillMissingMetadata({
    void Function(int current, int total, String currentTitle)? onProgress,
  }) async {
    final moviesNeedingMetadata = await database
        .getIdentifiedMoviesMissingGenres();
    final showsNeedingMetadata = await database
        .getIdentifiedTvShowsMissingGenres();
    final total = moviesNeedingMetadata.length + showsNeedingMetadata.length;

    var processed = 0;
    var matched = 0;
    var errors = 0;

    for (final movie in moviesNeedingMetadata) {
      processed++;
      onProgress?.call(processed, total, movie.title ?? movie.detectedTitle);

      try {
        final success = await enrichMovieMetadata(movie);
        if (success) {
          matched++;
        } else {
          errors++;
        }
      } catch (_) {
        errors++;
      }
    }

    for (final show in showsNeedingMetadata) {
      processed++;
      onProgress?.call(processed, total, show.title ?? show.detectedTitle);

      try {
        final success = await enrichTvShowMetadata(show);
        if (success) {
          matched++;
        } else {
          errors++;
        }
      } catch (_) {
        errors++;
      }
    }

    return MetadataPipelineSummary(
      totalProcessed: processed,
      automaticallyMatched: matched,
      routedToVerification: 0,
      errors: errors,
    );
  }

  /// Runs identification on all currently unmatched movies and shows,
  /// as well as enriching any identified TV shows with missing episode metadata,
  /// and backfilling metadata for existing identified media missing genres/collections.
  Future<MetadataPipelineSummary> identifyAllUnmatched({
    void Function(int current, int total, String currentTitle)? onProgress,
  }) async {
    final unmatchedMovies = await database.getUnmatchedMovies();
    final unmatchedShows = await database.getUnmatchedTvShows();
    final showsNeedingEpisodeEnrichment = await database
        .getIdentifiedTvShowsNeedingEpisodeEnrichment();
    final moviesNeedingMetadata = await database
        .getIdentifiedMoviesMissingGenres();
    final showsNeedingMetadata = await database
        .getIdentifiedTvShowsMissingGenres();

    final episodeEnrichmentShowIds = showsNeedingEpisodeEnrichment
        .map((s) => s.id)
        .toSet();
    final remainingShowsNeedingMetadata = showsNeedingMetadata
        .where((s) => !episodeEnrichmentShowIds.contains(s.id))
        .toList();

    final total =
        unmatchedMovies.length +
        unmatchedShows.length +
        showsNeedingEpisodeEnrichment.length +
        moviesNeedingMetadata.length +
        remainingShowsNeedingMetadata.length;

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

    for (final show in showsNeedingEpisodeEnrichment) {
      processed++;
      onProgress?.call(processed, total, show.title ?? show.detectedTitle);

      try {
        if (show.genres == null || show.genres!.trim().isEmpty) {
          await enrichTvShowMetadata(show);
        }
        final count = await enrichTvShowEpisodes(show);
        if (count > 0) {
          matched++;
        }
      } catch (_) {
        errors++;
      }
    }

    for (final movie in moviesNeedingMetadata) {
      processed++;
      onProgress?.call(processed, total, movie.title ?? movie.detectedTitle);

      try {
        final success = await enrichMovieMetadata(movie);
        if (success) {
          matched++;
        } else {
          errors++;
        }
      } catch (_) {
        errors++;
      }
    }

    for (final show in remainingShowsNeedingMetadata) {
      processed++;
      onProgress?.call(processed, total, show.title ?? show.detectedTitle);

      try {
        final success = await enrichTvShowMetadata(show);
        if (success) {
          matched++;
        } else {
          errors++;
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
