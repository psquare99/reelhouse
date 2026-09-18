import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/network/tmdb_models.dart';
import 'package:reelhouse/domain/metadata/metadata_matcher.dart';

void main() {
  const matcher = MetadataMatcher();

  group(
    'MetadataMatcher — Candidate Normalization & Ordering Prefix Extraction',
    () {
      test('extracts ordering prefixes correctly for common conventions', () {
        // Space-separated prefixes
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "1 Harry Potter and the Sorcerer's Stone",
          ),
          "Harry Potter and the Sorcerer's Stone",
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate("1 Iron Man"),
          "Iron Man",
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "2 The Dark Knight",
          ),
          "The Dark Knight",
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "10 Captain America The Winter Soldier",
          ),
          "Captain America The Winter Soldier",
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "29 Doctor Strange in the Multiverse of Madness",
          ),
          "Doctor Strange in the Multiverse of Madness",
        );

        // Separator-based prefixes (dot, dash, underscore)
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate("1. Iron Man"),
          "Iron Man",
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "01. Iron Man",
          ),
          "Iron Man",
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "01 - The Dark Knight",
          ),
          "The Dark Knight",
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate("1 - Movie"),
          "Movie",
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "02_The Matrix",
          ),
          "The Matrix",
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate("1_Movie"),
          "Movie",
        );
      });

      test('protects legitimate numeric titles and 4-digit years from prefix stripping', () {
        // 4-digit years/titles MUST NOT be stripped
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate("1917"),
          isNull,
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "2001: A Space Odyssey",
          ),
          isNull,
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "2001 A Space Odyssey",
          ),
          isNull,
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate("1984"),
          isNull,
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate("2012"),
          isNull,
        );

        // 3-digit titles without separator MUST NOT be stripped
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate("300"),
          isNull,
        );
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(
            "500 Days of Summer",
          ),
          isNull,
        );
      });

      test('getTitleCandidates returns original title first, then stripped candidate if present', () {
        final hpCandidates = MetadataMatcher.getTitleCandidates(
          "1 Harry Potter and the Sorcerer's Stone",
        );
        expect(hpCandidates, [
          "1 Harry Potter and the Sorcerer's Stone",
          "Harry Potter and the Sorcerer's Stone",
        ]);

        final yearCandidates = MetadataMatcher.getTitleCandidates("1917");
        expect(yearCandidates, ["1917"]);

        final spaceOdysseyCandidates = MetadataMatcher.getTitleCandidates(
          "2001 A Space Odyssey",
        );
        expect(spaceOdysseyCandidates, ["2001 A Space Odyssey"]);
      });
    },
  );

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
