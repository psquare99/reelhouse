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

    final candidateA = detectedTitle;
    final candidateB = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
      detectedTitle,
    );

    if (primaryCandidates.isNotEmpty ||
        (primaryProvider.isConfigured &&
            candidateB != null &&
            candidateB != candidateA)) {
      final decisionA = primaryCandidates.isNotEmpty
          ? matcher.evaluateProviderCandidates(
              detectedTitle: candidateA,
              detectedYear: detectedYear,
              candidates: primaryCandidates,
            )
          : const MatchDecision<ProviderCandidate>(
              type: MatchDecisionType.noCandidates,
              reason: 'No primary candidates',
            );

      var primaryDecision = decisionA;

      if (candidateB != null && candidateB != candidateA) {
        try {
          final altCandidates = await primaryProvider.searchMovies(
            candidateB,
            year: detectedYear,
          );
          if (altCandidates.isNotEmpty) {
            final decisionB = matcher.evaluateProviderCandidates(
              detectedTitle: candidateB,
              detectedYear: detectedYear,
              candidates: altCandidates,
            );
            primaryDecision = MetadataMatcher.selectStrongestProviderMatch(
              candidateA: candidateA,
              decisionA: decisionA,
              candidateB: candidateB,
              decisionB: decisionB,
            );
          }
        } catch (_) {}
      }

      if (primaryDecision.isAutomatic && primaryDecision.bestMatch != null) {
        final details = await primaryProvider.getMovieDetails(
          primaryDecision.bestMatch!.providerItemId,
        );
        if (details != null) {
          return OrchestratedMovieResult(
            isSuccess: true,
            details: details,
            providerId: primaryProvider.id,
            providerItemId: primaryDecision.bestMatch!.providerItemId,
            confidence: primaryDecision.confidence,
            isFallbackUsed: false,
            diagnostic: MetadataDiagnostic(
              mediaId: mediaId,
              detectedTitle: detectedTitle,
              detectedYear: detectedYear,
              category: MetadataFailureCategory.providerUnknownTitle,
              providerId: primaryProvider.id,
              message: 'Successfully identified via ${primaryProvider.id}',
              candidatesCount: primaryCandidates.length,
              topConfidence: primaryDecision.confidence,
            ),
            candidates: primaryDecision.candidates,
          );
        }
      }

      // If still ambiguous or below threshold on primary, report diagnostic without querying fallback
      if (primaryDecision.needsVerification) {
        return OrchestratedMovieResult(
          isSuccess: false,
          confidence: primaryDecision.confidence,
          isFallbackUsed: false,
          diagnostic: MetadataDiagnostic(
            mediaId: mediaId,
            detectedTitle: detectedTitle,
            detectedYear: detectedYear,
            category: MetadataFailureCategory.matchingAmbiguity,
            providerId: primaryProvider.id,
            message: primaryDecision.reason,
            candidatesCount: primaryCandidates.length,
            topConfidence: primaryDecision.confidence,
          ),
          candidates: primaryDecision.candidates,
        );
      }
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
          candidateB != null &&
          candidateB != detectedTitle) {
        try {
          fallbackCandidates = await movieFallbackProvider!.searchMovies(
            candidateB,
            year: detectedYear,
          );
        } catch (_) {}
      }

      if (fallbackCandidates.isNotEmpty) {
        final fallbackDecision = matcher.evaluateProviderCandidates(
          detectedTitle: candidateB ?? detectedTitle,
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

    final candidateA = detectedTitle;
    final candidateB = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
      detectedTitle,
    );

    if (primaryCandidates.isNotEmpty ||
        (primaryProvider.isConfigured &&
            candidateB != null &&
            candidateB != candidateA)) {
      final decisionA = primaryCandidates.isNotEmpty
          ? matcher.evaluateProviderCandidates(
              detectedTitle: candidateA,
              detectedYear: detectedYear,
              candidates: primaryCandidates,
            )
          : const MatchDecision<ProviderCandidate>(
              type: MatchDecisionType.noCandidates,
              reason: 'No primary candidates',
            );

      var primaryDecision = decisionA;

      if (candidateB != null && candidateB != candidateA) {
        try {
          final altCandidates = await primaryProvider.searchTvShows(candidateB);
          if (altCandidates.isNotEmpty) {
            final decisionB = matcher.evaluateProviderCandidates(
              detectedTitle: candidateB,
              detectedYear: detectedYear,
              candidates: altCandidates,
            );
            primaryDecision = MetadataMatcher.selectStrongestProviderMatch(
              candidateA: candidateA,
              decisionA: decisionA,
              candidateB: candidateB,
              decisionB: decisionB,
            );
          }
        } catch (_) {}
      }

      if (primaryDecision.isAutomatic && primaryDecision.bestMatch != null) {
        final details = await primaryProvider.getTvShowDetails(
          primaryDecision.bestMatch!.providerItemId,
        );
        if (details != null) {
          return OrchestratedTvResult(
            isSuccess: true,
            details: details,
            providerId: primaryProvider.id,
            providerItemId: primaryDecision.bestMatch!.providerItemId,
            confidence: primaryDecision.confidence,
            isFallbackUsed: false,
            diagnostic: MetadataDiagnostic(
              mediaId: mediaId,
              detectedTitle: detectedTitle,
              detectedYear: detectedYear,
              category: MetadataFailureCategory.providerUnknownTitle,
              providerId: primaryProvider.id,
              message: 'Successfully identified via ${primaryProvider.id}',
              candidatesCount: primaryCandidates.length,
              topConfidence: primaryDecision.confidence,
            ),
            candidates: primaryDecision.candidates,
          );
        }
      }

      if (primaryDecision.needsVerification) {
        return OrchestratedTvResult(
          isSuccess: false,
          confidence: primaryDecision.confidence,
          isFallbackUsed: false,
          diagnostic: MetadataDiagnostic(
            mediaId: mediaId,
            detectedTitle: detectedTitle,
            detectedYear: detectedYear,
            category: MetadataFailureCategory.matchingAmbiguity,
            providerId: primaryProvider.id,
            message: primaryDecision.reason,
            candidatesCount: primaryCandidates.length,
            topConfidence: primaryDecision.confidence,
          ),
          candidates: primaryDecision.candidates,
        );
      }
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
          candidateB != null &&
          candidateB != detectedTitle) {
        try {
          fallbackCandidates = await tvFallbackProvider!.searchTvShows(
            candidateB,
          );
        } catch (_) {}
      }

      if (fallbackCandidates.isNotEmpty) {
        final fallbackDecision = matcher.evaluateProviderCandidates(
          detectedTitle: candidateB ?? detectedTitle,
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
