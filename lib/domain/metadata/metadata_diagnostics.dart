/// Category classification for metadata pipeline failures.
///
/// Distinguishes between:
/// - "The provider doesn't know this title" (providerUnknownTitle)
/// - "MATINEE failed to identify or match the title" (matchingAmbiguity, parsingError)
/// - Infrastructure issues (network, rate limit, missing key)
enum MetadataFailureCategory {
  /// The upstream provider has no record of this title or year query.
  /// ("TMDB doesn't know this title")
  providerUnknownTitle,

  /// Candidates were returned by the provider, but confidence was below the
  /// 0.85 safety threshold, or multiple remakes produced ambiguous scores.
  /// ("MATINEE failed to disambiguate the title")
  matchingAmbiguity,

  /// The local filename heuristic parser could not extract a reliable title or year.
  parsingError,

  /// Network error, connection timeout, or host unreachable.
  networkError,

  /// Upstream provider HTTP 429 rate limit exceeded.
  rateLimited,

  /// The user has not configured a valid API key for the provider.
  missingApiKey,

  /// The provider returned a matching record, but poster/backdrop or required fields are missing.
  missingAssets,
}

/// Detailed diagnostics for a metadata identification pass on a media item.
class MetadataDiagnostic {
  final String mediaId;
  final String detectedTitle;
  final int? detectedYear;
  final MetadataFailureCategory category;
  final String providerId;
  final String message;
  final int candidatesCount;
  final double topConfidence;

  const MetadataDiagnostic({
    required this.mediaId,
    required this.detectedTitle,
    this.detectedYear,
    required this.category,
    required this.providerId,
    required this.message,
    this.candidatesCount = 0,
    this.topConfidence = 0.0,
  });

  /// True if the failure is because the upstream provider has no knowledge of this title.
  bool get isProviderUnknown =>
      category == MetadataFailureCategory.providerUnknownTitle;

  /// True if the upstream provider had candidates, but MATINEE confidence scoring
  /// safely rejected an automatic match to protect catalogue integrity.
  bool get isReelhouseMatchingFailure =>
      category == MetadataFailureCategory.matchingAmbiguity ||
      category == MetadataFailureCategory.parsingError;

  /// Human-readable diagnostic summary suitable for user verification dialogs.
  String get humanReadableExplanation {
    switch (category) {
      case MetadataFailureCategory.providerUnknownTitle:
        return 'No results found on $providerId for "$detectedTitle"${detectedYear != null ? ' ($detectedYear)' : ''}. '
            'The title may be unlisted, misspelled, or require an alternate title.';
      case MetadataFailureCategory.matchingAmbiguity:
        return '$candidatesCount candidates found on $providerId, but top match had ${(topConfidence * 100).toStringAsFixed(0)}% confidence '
            '(threshold: 85%). Manual verification required to avoid false matches.';
      case MetadataFailureCategory.parsingError:
        return 'Filename could not be parsed with high certainty.';
      case MetadataFailureCategory.networkError:
        return 'Network request to $providerId timed out or failed. Check your internet connection.';
      case MetadataFailureCategory.rateLimited:
        return '$providerId rate limit exceeded. Requests are being throttled.';
      case MetadataFailureCategory.missingApiKey:
        return 'No API key configured for $providerId in Settings.';
      case MetadataFailureCategory.missingAssets:
        return 'Matched on $providerId, but artwork or essential metadata fields were incomplete.';
    }
  }

  @override
  String toString() =>
      'MetadataDiagnostic(category: $category, provider: $providerId, title: "$detectedTitle", confidence: $topConfidence, count: $candidatesCount)';
}
