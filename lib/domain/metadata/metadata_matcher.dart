import 'dart:math';

import '../../data/network/tmdb_models.dart';
import 'metadata_provider.dart';

/// Scored candidate result from confidence evaluation.
class ScoredMovieMatch {
  final TmdbMovieSearchResult candidate;
  final double confidence;
  final String rationale;

  const ScoredMovieMatch({
    required this.candidate,
    required this.confidence,
    required this.rationale,
  });
}

class ScoredTvMatch {
  final TmdbTvSearchResult candidate;
  final double confidence;
  final String rationale;

  const ScoredTvMatch({
    required this.candidate,
    required this.confidence,
    required this.rationale,
  });
}

class ScoredProviderMatch {
  final ProviderCandidate candidate;
  final double confidence;
  final String rationale;

  const ScoredProviderMatch({
    required this.candidate,
    required this.confidence,
    required this.rationale,
  });
}

enum MatchDecisionType { automaticMatch, needsVerification, noCandidates }

class MatchDecision<T> {
  final MatchDecisionType type;
  final T? bestMatch;
  final double confidence;
  final List<T> candidates;
  final String reason;

  const MatchDecision({
    required this.type,
    this.bestMatch,
    this.confidence = 0.0,
    this.candidates = const [],
    required this.reason,
  });

  bool get isAutomatic => type == MatchDecisionType.automaticMatch;
  bool get needsVerification => type == MatchDecisionType.needsVerification;
}

/// Confidence scoring and disambiguation engine for matching parsed media identity with TMDB results.
class MetadataMatcher {
  final double highConfidenceThreshold;
  final double ambiguityGap;

  const MetadataMatcher({
    this.highConfidenceThreshold = 0.85,
    this.ambiguityGap = 0.08,
  });

  /// Evaluates movie candidates and returns a match decision.
  MatchDecision<TmdbMovieSearchResult> evaluateMovieCandidates({
    required String detectedTitle,
    int? detectedYear,
    required List<TmdbMovieSearchResult> candidates,
  }) {
    if (candidates.isEmpty) {
      return const MatchDecision(
        type: MatchDecisionType.noCandidates,
        reason: 'No TMDB candidates returned for query.',
      );
    }

    final scored = <ScoredMovieMatch>[];
    for (final cand in candidates) {
      final score = calculateMovieScore(
        detectedTitle: detectedTitle,
        detectedYear: detectedYear,
        candidate: cand,
      );
      scored.add(score);
    }

    scored.sort((a, b) => b.confidence.compareTo(a.confidence));
    final best = scored.first;

    if (best.confidence >= highConfidenceThreshold) {
      // Check for ambiguity with the second best result
      if (scored.length > 1) {
        final second = scored[1];
        if ((best.confidence - second.confidence) < ambiguityGap &&
            best.candidate.id != second.candidate.id) {
          return MatchDecision(
            type: MatchDecisionType.needsVerification,
            bestMatch: best.candidate,
            confidence: best.confidence,
            candidates: scored.map((s) => s.candidate).toList(),
            reason:
                'Ambiguous matches with close scores: "${best.candidate.title} (${best.candidate.releaseYear})" vs "${second.candidate.title} (${second.candidate.releaseYear})"',
          );
        }
      }

      return MatchDecision(
        type: MatchDecisionType.automaticMatch,
        bestMatch: best.candidate,
        confidence: best.confidence,
        candidates: scored.map((s) => s.candidate).toList(),
        reason: best.rationale,
      );
    }

    return MatchDecision(
      type: MatchDecisionType.needsVerification,
      bestMatch: best.candidate,
      confidence: best.confidence,
      candidates: scored.map((s) => s.candidate).toList(),
      reason:
          'Confidence ${(best.confidence * 100).toStringAsFixed(0)}% is below threshold (${(highConfidenceThreshold * 100).toInt()}%).',
    );
  }

  /// Evaluates TV show candidates and returns a match decision.
  MatchDecision<TmdbTvSearchResult> evaluateTvCandidates({
    required String detectedTitle,
    int? detectedYear,
    required List<TmdbTvSearchResult> candidates,
  }) {
    if (candidates.isEmpty) {
      return const MatchDecision(
        type: MatchDecisionType.noCandidates,
        reason: 'No TMDB TV candidates returned for query.',
      );
    }

    final scored = <ScoredTvMatch>[];
    for (final cand in candidates) {
      final score = calculateTvScore(
        detectedTitle: detectedTitle,
        detectedYear: detectedYear,
        candidate: cand,
      );
      scored.add(score);
    }

    scored.sort((a, b) => b.confidence.compareTo(a.confidence));
    final best = scored.first;

    if (best.confidence >= highConfidenceThreshold) {
      if (scored.length > 1) {
        final second = scored[1];
        if ((best.confidence - second.confidence) < ambiguityGap &&
            best.candidate.id != second.candidate.id) {
          return MatchDecision(
            type: MatchDecisionType.needsVerification,
            bestMatch: best.candidate,
            confidence: best.confidence,
            candidates: scored.map((s) => s.candidate).toList(),
            reason:
                'Ambiguous TV matches: "${best.candidate.name} (${best.candidate.firstAirYear})" vs "${second.candidate.name} (${second.candidate.firstAirYear})"',
          );
        }
      }

      return MatchDecision(
        type: MatchDecisionType.automaticMatch,
        bestMatch: best.candidate,
        confidence: best.confidence,
        candidates: scored.map((s) => s.candidate).toList(),
        reason: best.rationale,
      );
    }

    return MatchDecision(
      type: MatchDecisionType.needsVerification,
      bestMatch: best.candidate,
      confidence: best.confidence,
      candidates: scored.map((s) => s.candidate).toList(),
      reason:
          'TV confidence ${(best.confidence * 100).toStringAsFixed(0)}% is below threshold.',
    );
  }

  ScoredMovieMatch calculateMovieScore({
    required String detectedTitle,
    int? detectedYear,
    required TmdbMovieSearchResult candidate,
  }) {
    final titleSim = max(
      _stringSimilarity(detectedTitle, candidate.title),
      candidate.originalTitle != null
          ? _stringSimilarity(detectedTitle, candidate.originalTitle!)
          : 0.0,
    );

    double yearScore = 0.15; // neutral when year is unverified
    String yearRationale = 'Year unverified';

    if (detectedYear != null && candidate.releaseYear != null) {
      final diff = (candidate.releaseYear! - detectedYear).abs();
      if (diff == 0) {
        yearScore = 0.30;
        yearRationale = 'Exact year match ($detectedYear)';
      } else if (diff == 1) {
        yearScore = 0.20;
        yearRationale =
            'Close year match (${candidate.releaseYear} vs $detectedYear)';
      } else {
        yearScore = 0.00;
        yearRationale =
            'Year mismatch (${candidate.releaseYear} vs $detectedYear)';
      }
    }

    final totalScore = (titleSim * 0.70) + yearScore;
    final clamped = totalScore.clamp(0.0, 1.0);

    return ScoredMovieMatch(
      candidate: candidate,
      confidence: clamped,
      rationale:
          'Title similarity: ${(titleSim * 100).toStringAsFixed(0)}%, $yearRationale.',
    );
  }

  ScoredTvMatch calculateTvScore({
    required String detectedTitle,
    int? detectedYear,
    required TmdbTvSearchResult candidate,
  }) {
    final titleSim = max(
      _stringSimilarity(detectedTitle, candidate.name),
      candidate.originalName != null
          ? _stringSimilarity(detectedTitle, candidate.originalName!)
          : 0.0,
    );

    double yearScore = 0.15;
    String yearRationale = 'First air year unverified';

    if (detectedYear != null && candidate.firstAirYear != null) {
      final diff = (candidate.firstAirYear! - detectedYear).abs();
      if (diff == 0) {
        yearScore = 0.30;
        yearRationale = 'Exact first air year ($detectedYear)';
      } else if (diff == 1) {
        yearScore = 0.20;
        yearRationale = 'Close first air year (${candidate.firstAirYear})';
      } else {
        yearScore = 0.00;
        yearRationale = 'Year mismatch';
      }
    }

    final totalScore = (titleSim * 0.70) + yearScore;
    final clamped = totalScore.clamp(0.0, 1.0);

    return ScoredTvMatch(
      candidate: candidate,
      confidence: clamped,
      rationale:
          'TV title similarity: ${(titleSim * 100).toStringAsFixed(0)}%, $yearRationale.',
    );
  }

  /// Evaluates standardized [ProviderCandidate]s across any metadata provider.
  MatchDecision<ProviderCandidate> evaluateProviderCandidates({
    required String detectedTitle,
    int? detectedYear,
    required List<ProviderCandidate> candidates,
  }) {
    if (candidates.isEmpty) {
      return const MatchDecision(
        type: MatchDecisionType.noCandidates,
        reason: 'No provider candidates returned for query.',
      );
    }

    final scored = <ScoredProviderMatch>[];
    for (final cand in candidates) {
      final score = calculateProviderScore(
        detectedTitle: detectedTitle,
        detectedYear: detectedYear,
        candidate: cand,
      );
      scored.add(score);
    }

    scored.sort((a, b) => b.confidence.compareTo(a.confidence));
    final best = scored.first;

    if (best.confidence >= highConfidenceThreshold) {
      if (scored.length > 1) {
        final second = scored[1];
        if ((best.confidence - second.confidence) < ambiguityGap &&
            best.candidate.providerItemId != second.candidate.providerItemId) {
          return MatchDecision(
            type: MatchDecisionType.needsVerification,
            bestMatch: best.candidate,
            confidence: best.confidence,
            candidates: scored.map((s) => s.candidate).toList(),
            reason:
                'Ambiguous matches on ${best.candidate.providerId}: "${best.candidate.title} (${best.candidate.year})" vs "${second.candidate.title} (${second.candidate.year})"',
          );
        }
      }

      return MatchDecision(
        type: MatchDecisionType.automaticMatch,
        bestMatch: best.candidate,
        confidence: best.confidence,
        candidates: scored.map((s) => s.candidate).toList(),
        reason: best.rationale,
      );
    }

    return MatchDecision(
      type: MatchDecisionType.needsVerification,
      bestMatch: best.candidate,
      confidence: best.confidence,
      candidates: scored.map((s) => s.candidate).toList(),
      reason:
          'Confidence ${(best.confidence * 100).toStringAsFixed(0)}% on ${best.candidate.providerId} is below safe threshold ($highConfidenceThreshold).',
    );
  }

  ScoredProviderMatch calculateProviderScore({
    required String detectedTitle,
    int? detectedYear,
    required ProviderCandidate candidate,
  }) {
    final titleSim = max(
      _stringSimilarity(detectedTitle, candidate.title),
      candidate.originalTitle != null
          ? _stringSimilarity(detectedTitle, candidate.originalTitle!)
          : 0.0,
    );

    double yearScore = 0.15;
    String yearRationale = 'Year unverified';

    if (detectedYear != null && candidate.year != null) {
      final diff = (candidate.year! - detectedYear).abs();
      if (diff == 0) {
        yearScore = 0.30;
        yearRationale = 'Exact year match ($detectedYear)';
      } else if (diff == 1) {
        yearScore = 0.20;
        yearRationale = 'Close year match (${candidate.year} vs $detectedYear)';
      } else {
        yearScore = 0.00;
        yearRationale = 'Year mismatch (${candidate.year} vs $detectedYear)';
      }
    }

    final totalScore = (titleSim * 0.70) + yearScore;
    final clamped = totalScore.clamp(0.0, 1.0);

    return ScoredProviderMatch(
      candidate: candidate,
      confidence: clamped,
      rationale:
          '${candidate.providerId} title similarity: ${(titleSim * 100).toStringAsFixed(0)}%, $yearRationale.',
    );
  }

  static String _normalize(String s) {
    var clean = s.toLowerCase().trim();
    clean = clean.replaceAll(RegExp(r'^(?:the|a|an)\s+'), '');
    clean = clean.replaceAll(RegExp(r'[^\w\s]'), ' ');
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean;
  }

  static double _stringSimilarity(String a, String b) {
    final normA = _normalize(a);
    final normB = _normalize(b);

    if (normA == normB) return 1.0;
    if (normA.isEmpty || normB.isEmpty) return 0.0;

    // Token set overlap
    final tokensA = normA.split(' ').where((t) => t.isNotEmpty).toSet();
    final tokensB = normB.split(' ').where((t) => t.isNotEmpty).toSet();
    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;
    final jaccard = union > 0 ? intersection / union : 0.0;

    // Character bigram Dice coefficient
    final bigramsA = _getBigrams(normA);
    final bigramsB = _getBigrams(normB);
    var matches = 0;
    for (final bg in bigramsA) {
      if (bigramsB.contains(bg)) {
        matches++;
      }
    }
    final totalBigrams = bigramsA.length + bigramsB.length;
    final dice = totalBigrams > 0 ? (2.0 * matches) / totalBigrams : 0.0;

    return (jaccard * 0.5) + (dice * 0.5);
  }

  static List<String> _getBigrams(String s) {
    final list = <String>[];
    for (var i = 0; i < s.length - 1; i++) {
      list.add(s.substring(i, i + 2));
    }
    return list;
  }

  /// Extracts an alternate title candidate if [title] begins with a recognized numeric ordering prefix pattern.
  ///
  /// Supported prefix patterns:
  /// - "1 Movie", "01 Movie" (1-2 digits followed by whitespace)
  /// - "1. Movie", "01. Movie" (1-3 digits followed by '.' and separator)
  /// - "1 - Movie", "01 - Movie" (1-3 digits followed by '-' and separator)
  /// - "1_Movie", "01_Movie", "1_ Movie" (1-3 digits followed by '_' and separator)
  ///
  /// Protects legitimate 4-digit numeric titles/years (e.g. "1917", "2001: A Space Odyssey")
  /// and 3-digit titles without separator (e.g. "300", "500 Days of Summer").
  ///
  /// Returns `null` if no ordering prefix pattern is detected or if stripping would leave an invalid/short title.
  static String? extractOrderingPrefixStrippedCandidate(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;

    // 1. Separator-based prefixes: e.g. "01 - The Dark Knight", "1. Iron Man", "02_The Matrix", "1 - Movie"
    final sepMatch = RegExp(r'^\s*(\d{1,3})\s*[-._]\s*(.+)$')
        .firstMatch(trimmed);
    if (sepMatch != null) {
      final remainder = sepMatch.group(2)?.trim();
      if (remainder != null && remainder.length >= 2) {
        return remainder;
      }
    }

    // 2. Space-separated 1-2 digit prefix: e.g. "1 Harry Potter...", "1 Iron Man", "29 Doctor Strange..."
    // 4-digit years (1917, 2001) and 3-digit titles (300, 500 Days) are protected by \d{1,2}
    final spaceMatch = RegExp(r'^\s*(\d{1,2})\s+(.+)$').firstMatch(trimmed);
    if (spaceMatch != null) {
      final remainder = spaceMatch.group(2)?.trim();
      if (remainder != null && remainder.length >= 2) {
        return remainder;
      }
    }

    return null;
  }

  /// Generates an ordered list of title candidates for discovery and matching:
  /// 1. Original detected title (evaluated first with highest priority)
  /// 2. Normalized title with ordering prefix removed (evaluated if primary candidate yields no automatic match)
  static List<String> getTitleCandidates(String title) {
    final candidates = <String>[title.trim()];
    final stripped = extractOrderingPrefixStrippedCandidate(title);
    if (stripped != null && stripped.isNotEmpty && stripped != title.trim()) {
      candidates.add(stripped);
    }
    return candidates;
  }
}
