import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/network/tmdb_models.dart';
import 'package:reelhouse/domain/metadata/metadata_matcher.dart';

void main() {
  const matcher = MetadataMatcher();

  group('MetadataMatcher — Movies', () {
    test('produces automaticMatch for exact title and year', () {
      final candidates = [
        const TmdbMovieSearchResult(
          id: 157336,
          title: 'Interstellar',
          releaseYear: 2014,
        ),
        const TmdbMovieSearchResult(
          id: 999999,
          title: 'Interstellar Wars',
          releaseYear: 2016,
        ),
      ];

      final decision = matcher.evaluateMovieCandidates(
        detectedTitle: 'Interstellar',
        detectedYear: 2014,
        candidates: candidates,
      );

      expect(decision.isAutomatic, isTrue);
      expect(decision.bestMatch?.id, 157336);
      expect(decision.confidence, greaterThanOrEqualTo(0.95));
    });

    test('tolerates leading articles and punctuation in title matching', () {
      final candidates = [
        const TmdbMovieSearchResult(
          id: 603,
          title: 'The Matrix',
          releaseYear: 1999,
        ),
      ];

      final decision = matcher.evaluateMovieCandidates(
        detectedTitle: 'Matrix',
        detectedYear: 1999,
        candidates: candidates,
      );

      expect(decision.isAutomatic, isTrue);
      expect(decision.bestMatch?.id, 603);
    });

    test(
      'tolerates 1-year discrepancy between festival and theatrical releases',
      () {
        final candidates = [
          const TmdbMovieSearchResult(
            id: 100,
            title: 'Parasite',
            releaseYear: 2019,
          ),
        ];

        final decision = matcher.evaluateMovieCandidates(
          detectedTitle: 'Parasite',
          detectedYear: 2020,
          candidates: candidates,
        );

        expect(decision.isAutomatic, isTrue);
        expect(decision.bestMatch?.id, 100);
        expect(decision.confidence, greaterThanOrEqualTo(0.85));
      },
    );

    test(
      'routes ambiguous remakes to needsVerification when year is omitted',
      () {
        final candidates = [
          const TmdbMovieSearchResult(
            id: 1091,
            title: 'The Thing',
            releaseYear: 1982,
          ),
          const TmdbMovieSearchResult(
            id: 60935,
            title: 'The Thing',
            releaseYear: 2011,
          ),
        ];

        // File without year: "The Thing.mkv"
        final decision = matcher.evaluateMovieCandidates(
          detectedTitle: 'The Thing',
          detectedYear: null,
          candidates: candidates,
        );

        expect(decision.needsVerification, isTrue);
        expect(decision.candidates.length, 2);
        expect(decision.reason, contains('Ambiguous'));
      },
    );

    test('routes low confidence score to needsVerification', () {
      final candidates = [
        const TmdbMovieSearchResult(
          id: 50,
          title: 'Something Completely Unrelated',
          releaseYear: 1975,
        ),
      ];

      final decision = matcher.evaluateMovieCandidates(
        detectedTitle: 'Fight Club',
        detectedYear: 1999,
        candidates: candidates,
      );

      expect(decision.needsVerification, isTrue);
      expect(decision.confidence, lessThan(0.50));
    });

    test('handles empty candidates list cleanly', () {
      final decision = matcher.evaluateMovieCandidates(
        detectedTitle: 'Obscure Unknown Movie',
        candidates: [],
      );

      expect(decision.type, MatchDecisionType.noCandidates);
    });
  });

  group('MetadataMatcher — TV Shows', () {
    test('produces automaticMatch for TV series with matching title', () {
      final candidates = [
        const TmdbTvSearchResult(
          id: 1396,
          name: 'Breaking Bad',
          firstAirYear: 2008,
        ),
        const TmdbTvSearchResult(
          id: 999,
          name: 'Breaking Bad: Special',
          firstAirYear: 2013,
        ),
      ];

      final decision = matcher.evaluateTvCandidates(
        detectedTitle: 'Breaking Bad',
        detectedYear: 2008,
        candidates: candidates,
      );

      expect(decision.isAutomatic, isTrue);
      expect(decision.bestMatch?.id, 1396);
    });
  });
}
