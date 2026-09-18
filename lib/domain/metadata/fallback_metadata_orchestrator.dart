import 'metadata_diagnostics.dart';
import 'metadata_matcher.dart';
import 'metadata_provider.dart';

/// Successful or diagnostic outcome from orchestrated movie identification.
class OrchestratedMovieResult {
  final bool isSuccess;
  final ProviderMovieDetails? details;
  final String? providerId;
  final String? providerItemId;
  final double confidence;
  final bool isFallbackUsed;
  final MetadataDiagnostic diagnostic;
  final List<ProviderCandidate> candidates;

  const OrchestratedMovieResult({
    required this.isSuccess,
    this.details,
    this.providerId,
    this.providerItemId,
    this.confidence = 0.0,
    this.isFallbackUsed = false,
    required this.diagnostic,
    this.candidates = const [],
  });
}

/// Successful or diagnostic outcome from orchestrated TV show identification.
class OrchestratedTvResult {
  final bool isSuccess;
  final ProviderTvDetails? details;
  final String? providerId;
  final String? providerItemId;
  final double confidence;
  final bool isFallbackUsed;
  final MetadataDiagnostic diagnostic;
  final List<ProviderCandidate> candidates;

  const OrchestratedTvResult({
    required this.isSuccess,
    this.details,
    this.providerId,
    this.providerItemId,
    this.confidence = 0.0,
    this.isFallbackUsed = false,
    required this.diagnostic,
    this.candidates = const [],
  });
}

/// Coordinates primary and fallback metadata providers with confidence scoring,
/// strict source provenance tracking, and actionable failure diagnostics.
///
/// ### Architecture & Governance Rules:
/// 1. **Primary First**: TMDB is always consulted first for rich multi-asset metadata.
/// 2. **Fallback Safety**: Fallbacks (OMDb for movies, TVmaze for TV) are queried
///    only when primary is unconfigured, rate-limited, unreachable, or returns 0 candidates.
/// 3. **Confidence Gating**: Fallback candidates must pass through [MetadataMatcher]
///    confidence scoring (>= 85%) before acceptance; lower confidence requires user verification.
/// 4. **Provenance Tracking**: Preserves [providerId] ('TMDB', 'OMDb', 'TVmaze') and
///    [providerItemId] for every matched record in the cinema database.
class FallbackMetadataOrchestrator {
  final MetadataProvider primaryProvider;
  final MetadataProvider? movieFallbackProvider;
  final MetadataProvider? tvFallbackProvider;
  final MetadataMatcher matcher;

  const FallbackMetadataOrchestrator({
    required this.primaryProvider,
    this.movieFallbackProvider,
    this.tvFallbackProvider,
    this.matcher = const MetadataMatcher(),
  });

  /// Identifies movie metadata with automatic fallback when primary yields no confident match.
  Future<OrchestratedMovieResult> identifyMovie({
    required String mediaId,
    required String detectedTitle,
    int? detectedYear,
  }) async {
    // 1. Query Primary Provider (TMDB)
    List<ProviderCandidate> primaryCandidates = [];
    bool primaryFailed = false;

    if (primaryProvider.isConfigured) {
      try {
        primaryCandidates = await primaryProvider.searchMovies(
          detectedTitle,
          year: detectedYear,
        );
      } catch (_) {
        primaryFailed = true;
      }
    } else {
      primaryFailed = true;
    }

    if (primaryCandidates.isNotEmpty) {
      final decision = matcher.evaluateProviderCandidates(
        detectedTitle: detectedTitle,
        detectedYear: detectedYear,
        candidates: primaryCandidates,
      );

      if (decision.isAutomatic && decision.bestMatch != null) {
        final details = await primaryProvider.getMovieDetails(
          decision.bestMatch!.providerItemId,
        );
        if (details != null) {
          return OrchestratedMovieResult(
            isSuccess: true,
            details: details,
            providerId: primaryProvider.id,
            providerItemId: decision.bestMatch!.providerItemId,
            confidence: decision.confidence,
            isFallbackUsed: false,
            diagnostic: MetadataDiagnostic(
              mediaId: mediaId,
              detectedTitle: detectedTitle,
              detectedYear: detectedYear,
              category: MetadataFailureCategory.providerUnknownTitle,
              providerId: primaryProvider.id,
              message: 'Successfully identified via ${primaryProvider.id}',
              candidatesCount: primaryCandidates.length,
              topConfidence: decision.confidence,
            ),
            candidates: decision.candidates,
          );
        }
      }

      // If ambiguous on primary, check if ordering prefix stripped candidate matches on primary
      final strippedCandidate =
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(detectedTitle);
      if (strippedCandidate != null && strippedCandidate != detectedTitle) {
        try {
          final altPrimaryCandidates = await primaryProvider.searchMovies(
            strippedCandidate,
            year: detectedYear,
          );
          if (altPrimaryCandidates.isNotEmpty) {
            final altDecision = matcher.evaluateProviderCandidates(
              detectedTitle: strippedCandidate,
              detectedYear: detectedYear,
              candidates: altPrimaryCandidates,
            );
            if (altDecision.isAutomatic && altDecision.bestMatch != null) {
              final details = await primaryProvider.getMovieDetails(
                altDecision.bestMatch!.providerItemId,
              );
              if (details != null) {
                return OrchestratedMovieResult(
                  isSuccess: true,
                  details: details,
                  providerId: primaryProvider.id,
                  providerItemId: altDecision.bestMatch!.providerItemId,
                  confidence: altDecision.confidence,
                  isFallbackUsed: false,
                  diagnostic: MetadataDiagnostic(
                    mediaId: mediaId,
                    detectedTitle: detectedTitle,
                    detectedYear: detectedYear,
                    category: MetadataFailureCategory.providerUnknownTitle,
                    providerId: primaryProvider.id,
                    message:
                        'Successfully identified via ${primaryProvider.id} using normalized candidate',
                    candidatesCount: altPrimaryCandidates.length,
                    topConfidence: altDecision.confidence,
                  ),
                  candidates: altDecision.candidates,
                );
              }
            }
          }
        } catch (_) {}
      }

      // If still ambiguous or below threshold on primary, report diagnostic without querying fallback
      if (decision.needsVerification) {
        return OrchestratedMovieResult(
          isSuccess: false,
          confidence: decision.confidence,
          isFallbackUsed: false,
          diagnostic: MetadataDiagnostic(
            mediaId: mediaId,
            detectedTitle: detectedTitle,
            detectedYear: detectedYear,
            category: MetadataFailureCategory.matchingAmbiguity,
            providerId: primaryProvider.id,
            message: decision.reason,
            candidatesCount: primaryCandidates.length,
            topConfidence: decision.confidence,
          ),
          candidates: decision.candidates,
        );
      }
    }

    // 1b. If primary returned 0 candidates, check if stripped candidate on primary finds anything
    final strippedCandidate =
        MetadataMatcher.extractOrderingPrefixStrippedCandidate(detectedTitle);
    if (primaryProvider.isConfigured &&
        strippedCandidate != null &&
        strippedCandidate != detectedTitle) {
      try {
        final altPrimaryCandidates = await primaryProvider.searchMovies(
          strippedCandidate,
          year: detectedYear,
        );
        if (altPrimaryCandidates.isNotEmpty) {
          final altDecision = matcher.evaluateProviderCandidates(
            detectedTitle: strippedCandidate,
            detectedYear: detectedYear,
            candidates: altPrimaryCandidates,
          );
          if (altDecision.isAutomatic && altDecision.bestMatch != null) {
            final details = await primaryProvider.getMovieDetails(
              altDecision.bestMatch!.providerItemId,
            );
            if (details != null) {
              return OrchestratedMovieResult(
                isSuccess: true,
                details: details,
                providerId: primaryProvider.id,
                providerItemId: altDecision.bestMatch!.providerItemId,
                confidence: altDecision.confidence,
                isFallbackUsed: false,
                diagnostic: MetadataDiagnostic(
                  mediaId: mediaId,
                  detectedTitle: detectedTitle,
                  detectedYear: detectedYear,
                  category: MetadataFailureCategory.providerUnknownTitle,
                  providerId: primaryProvider.id,
                  message:
                      'Successfully identified via ${primaryProvider.id} using normalized candidate',
                  candidatesCount: altPrimaryCandidates.length,
                  topConfidence: altDecision.confidence,
                ),
                candidates: altDecision.candidates,
              );
            }
          }
        }
      } catch (_) {}
    }

    // 2. Primary failed or returned 0 candidates -> Query Movie Fallback (OMDb)
    if (movieFallbackProvider != null && movieFallbackProvider!.isConfigured) {
      List<ProviderCandidate> fallbackCandidates = [];
      try {
        fallbackCandidates = await movieFallbackProvider!.searchMovies(
          detectedTitle,
          year: detectedYear,
        );
      } catch (_) {}

      // Try normalized candidate on fallback provider if primary search yielded nothing
      if (fallbackCandidates.isEmpty &&
          strippedCandidate != null &&
          strippedCandidate != detectedTitle) {
        try {
          fallbackCandidates = await movieFallbackProvider!.searchMovies(
            strippedCandidate,
            year: detectedYear,
          );
        } catch (_) {}
      }

      if (fallbackCandidates.isNotEmpty) {
        final fallbackDecision = matcher.evaluateProviderCandidates(
          detectedTitle: strippedCandidate ?? detectedTitle,
          detectedYear: detectedYear,
          candidates: fallbackCandidates,
        );

        if (fallbackDecision.isAutomatic &&
            fallbackDecision.bestMatch != null) {
          final fallbackDetails = await movieFallbackProvider!.getMovieDetails(
            fallbackDecision.bestMatch!.providerItemId,
          );
          if (fallbackDetails != null) {
            return OrchestratedMovieResult(
              isSuccess: true,
              details: fallbackDetails,
              providerId: movieFallbackProvider!.id,
              providerItemId: fallbackDecision.bestMatch!.providerItemId,
              confidence: fallbackDecision.confidence,
              isFallbackUsed: true,
              diagnostic: MetadataDiagnostic(
                mediaId: mediaId,
                detectedTitle: detectedTitle,
                detectedYear: detectedYear,
                category: MetadataFailureCategory.providerUnknownTitle,
                providerId: movieFallbackProvider!.id,
                message:
                    'Identified via fallback provider ${movieFallbackProvider!.id}',
                candidatesCount: fallbackCandidates.length,
                topConfidence: fallbackDecision.confidence,
              ),
              candidates: fallbackDecision.candidates,
            );
          }
        }

        if (fallbackDecision.needsVerification) {
          return OrchestratedMovieResult(
            isSuccess: false,
            confidence: fallbackDecision.confidence,
            isFallbackUsed: true,
            diagnostic: MetadataDiagnostic(
              mediaId: mediaId,
              detectedTitle: detectedTitle,
              detectedYear: detectedYear,
              category: MetadataFailureCategory.matchingAmbiguity,
              providerId: movieFallbackProvider!.id,
              message: fallbackDecision.reason,
              candidatesCount: fallbackCandidates.length,
              topConfidence: fallbackDecision.confidence,
            ),
            candidates: fallbackDecision.candidates,
          );
        }
      }
    }

    // 3. Both failed or unknown
    final failureCategory = primaryFailed
        ? (!primaryProvider.isConfigured
              ? MetadataFailureCategory.missingApiKey
              : MetadataFailureCategory.networkError)
        : MetadataFailureCategory.providerUnknownTitle;

    return OrchestratedMovieResult(
      isSuccess: false,
      diagnostic: MetadataDiagnostic(
        mediaId: mediaId,
        detectedTitle: detectedTitle,
        detectedYear: detectedYear,
        category: failureCategory,
        providerId: primaryProvider.id,
        message: 'No confident matches found on primary or fallback metadata providers.',
      ),
    );
  }

  /// Identifies TV show metadata with automatic fallback (TVmaze) when primary yields no confident match.
  Future<OrchestratedTvResult> identifyTvShow({
    required String mediaId,
    required String detectedTitle,
    int? detectedYear,
  }) async {
    // 1. Query Primary Provider (TMDB)
    List<ProviderCandidate> primaryCandidates = [];
    bool primaryFailed = false;

    if (primaryProvider.isConfigured) {
      try {
        primaryCandidates = await primaryProvider.searchTvShows(detectedTitle);
      } catch (_) {
        primaryFailed = true;
      }
    } else {
      primaryFailed = true;
    }

    if (primaryCandidates.isNotEmpty) {
      final decision = matcher.evaluateProviderCandidates(
        detectedTitle: detectedTitle,
        detectedYear: detectedYear,
        candidates: primaryCandidates,
      );

      if (decision.isAutomatic && decision.bestMatch != null) {
        final details = await primaryProvider.getTvShowDetails(
          decision.bestMatch!.providerItemId,
        );
        if (details != null) {
          return OrchestratedTvResult(
            isSuccess: true,
            details: details,
            providerId: primaryProvider.id,
            providerItemId: decision.bestMatch!.providerItemId,
            confidence: decision.confidence,
            isFallbackUsed: false,
            diagnostic: MetadataDiagnostic(
              mediaId: mediaId,
              detectedTitle: detectedTitle,
              detectedYear: detectedYear,
              category: MetadataFailureCategory.providerUnknownTitle,
              providerId: primaryProvider.id,
              message: 'Successfully identified via ${primaryProvider.id}',
              candidatesCount: primaryCandidates.length,
              topConfidence: decision.confidence,
            ),
            candidates: decision.candidates,
          );
        }
      }

      // If ambiguous on primary, check if ordering prefix stripped candidate matches on primary
      final strippedCandidate =
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(detectedTitle);
      if (strippedCandidate != null && strippedCandidate != detectedTitle) {
        try {
          final altPrimaryCandidates = await primaryProvider.searchTvShows(
            strippedCandidate,
          );
          if (altPrimaryCandidates.isNotEmpty) {
            final altDecision = matcher.evaluateProviderCandidates(
              detectedTitle: strippedCandidate,
              detectedYear: detectedYear,
              candidates: altPrimaryCandidates,
            );
            if (altDecision.isAutomatic && altDecision.bestMatch != null) {
              final details = await primaryProvider.getTvShowDetails(
                altDecision.bestMatch!.providerItemId,
              );
              if (details != null) {
                return OrchestratedTvResult(
                  isSuccess: true,
                  details: details,
                  providerId: primaryProvider.id,
                  providerItemId: altDecision.bestMatch!.providerItemId,
                  confidence: altDecision.confidence,
                  isFallbackUsed: false,
                  diagnostic: MetadataDiagnostic(
                    mediaId: mediaId,
                    detectedTitle: detectedTitle,
                    detectedYear: detectedYear,
                    category: MetadataFailureCategory.providerUnknownTitle,
                    providerId: primaryProvider.id,
                    message:
                        'Successfully identified via ${primaryProvider.id} using normalized candidate',
                    candidatesCount: altPrimaryCandidates.length,
                    topConfidence: altDecision.confidence,
                  ),
                  candidates: altDecision.candidates,
                );
              }
            }
          }
        } catch (_) {}
      }

      if (decision.needsVerification) {
        return OrchestratedTvResult(
          isSuccess: false,
          confidence: decision.confidence,
          isFallbackUsed: false,
          diagnostic: MetadataDiagnostic(
            mediaId: mediaId,
            detectedTitle: detectedTitle,
            detectedYear: detectedYear,
            category: MetadataFailureCategory.matchingAmbiguity,
            providerId: primaryProvider.id,
            message: decision.reason,
            candidatesCount: primaryCandidates.length,
            topConfidence: decision.confidence,
          ),
          candidates: decision.candidates,
        );
      }
    }

    // 1b. If primary returned 0 candidates, check if stripped candidate on primary finds anything
    final strippedCandidate =
        MetadataMatcher.extractOrderingPrefixStrippedCandidate(detectedTitle);
    if (primaryProvider.isConfigured &&
        strippedCandidate != null &&
        strippedCandidate != detectedTitle) {
      try {
        final altPrimaryCandidates = await primaryProvider.searchTvShows(
          strippedCandidate,
        );
        if (altPrimaryCandidates.isNotEmpty) {
          final altDecision = matcher.evaluateProviderCandidates(
            detectedTitle: strippedCandidate,
            detectedYear: detectedYear,
            candidates: altPrimaryCandidates,
          );
          if (altDecision.isAutomatic && altDecision.bestMatch != null) {
            final details = await primaryProvider.getTvShowDetails(
              altDecision.bestMatch!.providerItemId,
            );
            if (details != null) {
              return OrchestratedTvResult(
                isSuccess: true,
                details: details,
                providerId: primaryProvider.id,
                providerItemId: altDecision.bestMatch!.providerItemId,
                confidence: altDecision.confidence,
                isFallbackUsed: false,
                diagnostic: MetadataDiagnostic(
                  mediaId: mediaId,
                  detectedTitle: detectedTitle,
                  detectedYear: detectedYear,
                  category: MetadataFailureCategory.providerUnknownTitle,
                  providerId: primaryProvider.id,
                  message:
                      'Successfully identified via ${primaryProvider.id} using normalized candidate',
                  candidatesCount: altPrimaryCandidates.length,
                  topConfidence: altDecision.confidence,
                ),
                candidates: altDecision.candidates,
              );
            }
          }
        }
      } catch (_) {}
    }

    // 2. Primary failed or returned 0 candidates -> Query TV Fallback (TVmaze)
    if (tvFallbackProvider != null && tvFallbackProvider!.isConfigured) {
      List<ProviderCandidate> fallbackCandidates = [];
      try {
        fallbackCandidates = await tvFallbackProvider!.searchTvShows(
          detectedTitle,
        );
      } catch (_) {}

      // Try normalized candidate on fallback provider if primary search yielded nothing
      if (fallbackCandidates.isEmpty &&
          strippedCandidate != null &&
          strippedCandidate != detectedTitle) {
        try {
          fallbackCandidates = await tvFallbackProvider!.searchTvShows(
            strippedCandidate,
          );
        } catch (_) {}
      }

      if (fallbackCandidates.isNotEmpty) {
        final fallbackDecision = matcher.evaluateProviderCandidates(
          detectedTitle: strippedCandidate ?? detectedTitle,
          detectedYear: detectedYear,
          candidates: fallbackCandidates,
        );

        if (fallbackDecision.isAutomatic &&
            fallbackDecision.bestMatch != null) {
          final fallbackDetails = await tvFallbackProvider!.getTvShowDetails(
            fallbackDecision.bestMatch!.providerItemId,
          );
          if (fallbackDetails != null) {
            return OrchestratedTvResult(
              isSuccess: true,
              details: fallbackDetails,
              providerId: tvFallbackProvider!.id,
              providerItemId: fallbackDecision.bestMatch!.providerItemId,
              confidence: fallbackDecision.confidence,
              isFallbackUsed: true,
              diagnostic: MetadataDiagnostic(
                mediaId: mediaId,
                detectedTitle: detectedTitle,
                detectedYear: detectedYear,
                category: MetadataFailureCategory.providerUnknownTitle,
                providerId: tvFallbackProvider!.id,
                message:
                    'Identified via fallback provider ${tvFallbackProvider!.id}',
                candidatesCount: fallbackCandidates.length,
                topConfidence: fallbackDecision.confidence,
              ),
              candidates: fallbackDecision.candidates,
            );
          }
        }

        if (fallbackDecision.needsVerification) {
          return OrchestratedTvResult(
            isSuccess: false,
            confidence: fallbackDecision.confidence,
            isFallbackUsed: true,
            diagnostic: MetadataDiagnostic(
              mediaId: mediaId,
              detectedTitle: detectedTitle,
              detectedYear: detectedYear,
              category: MetadataFailureCategory.matchingAmbiguity,
              providerId: tvFallbackProvider!.id,
              message: fallbackDecision.reason,
              candidatesCount: fallbackCandidates.length,
              topConfidence: fallbackDecision.confidence,
            ),
            candidates: fallbackDecision.candidates,
          );
        }
      }
    }

    // 3. Both failed or unknown
    final failureCategory = primaryFailed
        ? (!primaryProvider.isConfigured
              ? MetadataFailureCategory.missingApiKey
              : MetadataFailureCategory.networkError)
        : MetadataFailureCategory.providerUnknownTitle;

    return OrchestratedTvResult(
      isSuccess: false,
      diagnostic: MetadataDiagnostic(
        mediaId: mediaId,
        detectedTitle: detectedTitle,
        detectedYear: detectedYear,
        category: failureCategory,
        providerId: primaryProvider.id,
        message: 'No confident matches found on primary or fallback TV metadata providers.',
      ),
    );
  }
}
