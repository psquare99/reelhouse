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

  group('MetadataMatcher — Part 11 Candidate Normalization Test Matrix', () {
    test(
      'ORDERING PREFIXES: candidate B produces better canonical match and wins',
      () {
        // 1. "1 The Fast And The Furious" (2001) -> TMDB "The Fast and the Furious"
        final candA1 = "1 The Fast And The Furious";
        final candB1 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA1,
        )!;
        expect(candB1, "The Fast And The Furious");

        final decA1 = matcher.evaluateMovieCandidates(
          detectedTitle: candA1,
          detectedYear: 2001,
          candidates: [
            const TmdbMovieSearchResult(
              id: 9799,
              title: 'The Fast and the Furious',
              releaseYear: 2001,
            ),
          ],
        );
        final decB1 = matcher.evaluateMovieCandidates(
          detectedTitle: candB1,
          detectedYear: 2001,
          candidates: [
            const TmdbMovieSearchResult(
              id: 9799,
              title: 'The Fast and the Furious',
              releaseYear: 2001,
            ),
          ],
        );
        final win1 = MetadataMatcher.selectStrongestMovieMatch(
          candidateA: candA1,
          decisionA: decA1,
          candidateB: candB1,
          decisionB: decB1,
        );
        expect(win1.isAutomatic, isTrue);
        expect(win1.bestMatch?.title, 'The Fast and the Furious');
        expect(decB1.confidence, greaterThan(decA1.confidence));

        // 2. "2 2 Fast 2 Furious" (2003) -> TMDB "2 Fast 2 Furious"
        final candA2 = "2 2 Fast 2 Furious";
        final candB2 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA2,
        )!;
        expect(candB2, "2 Fast 2 Furious");

        final decA2 = matcher.evaluateMovieCandidates(
          detectedTitle: candA2,
          detectedYear: 2003,
          candidates: [
            const TmdbMovieSearchResult(
              id: 584,
              title: '2 Fast 2 Furious',
              releaseYear: 2003,
            ),
          ],
        );
        final decB2 = matcher.evaluateMovieCandidates(
          detectedTitle: candB2,
          detectedYear: 2003,
          candidates: [
            const TmdbMovieSearchResult(
              id: 584,
              title: '2 Fast 2 Furious',
              releaseYear: 2003,
            ),
          ],
        );
        final win2 = MetadataMatcher.selectStrongestMovieMatch(
          candidateA: candA2,
          decisionA: decA2,
          candidateB: candB2,
          decisionB: decB2,
        );
        expect(win2.isAutomatic, isTrue);
        expect(win2.bestMatch?.title, '2 Fast 2 Furious');

        // 3. "3 Tokyo Drift" (2006) -> TMDB "The Fast and the Furious: Tokyo Drift"
        final candA3 = "3 Tokyo Drift";
        final candB3 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA3,
        )!;
        expect(candB3, "Tokyo Drift");

        // 4. "4 Fast & Furious" (2009) -> TMDB "Fast & Furious"
        final candA4 = "4 Fast & Furious";
        final candB4 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA4,
        )!;
        expect(candB4, "Fast & Furious");

        // 5. "5 Fast Five" (2011) -> TMDB "Fast Five"
        final candA5 = "5 Fast Five";
        final candB5 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA5,
        )!;
        expect(candB5, "Fast Five");
      },
    );

    test(
      'LEGITIMATE NUMERIC TITLES: candidate A produces exact match and wins',
      () {
        // 1. "10 Things I Hate About You"
        final candA1 = "10 Things I Hate About You";
        final candB1 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA1,
        )!;
        final tmdb1 = [
          const TmdbMovieSearchResult(
            id: 4951,
            title: '10 Things I Hate About You',
            releaseYear: 1999,
          ),
        ];
        final decA1 = matcher.evaluateMovieCandidates(
          detectedTitle: candA1,
          detectedYear: 1999,
          candidates: tmdb1,
        );
        final decB1 = matcher.evaluateMovieCandidates(
          detectedTitle: candB1,
          detectedYear: 1999,
          candidates: tmdb1,
        );
        final win1 = MetadataMatcher.selectStrongestMovieMatch(
          candidateA: candA1,
          decisionA: decA1,
          candidateB: candB1,
          decisionB: decB1,
        );
        expect(win1.isAutomatic, isTrue);
        expect(win1.bestMatch?.title, '10 Things I Hate About You');
        expect(decA1.confidence, greaterThan(decB1.confidence));

        // 2. "12 Angry Men"
        final candA2 = "12 Angry Men";
        final candB2 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA2,
        )!;
        final tmdb2 = [
          const TmdbMovieSearchResult(
            id: 389,
            title: '12 Angry Men',
            releaseYear: 1957,
          ),
        ];
        final decA2 = matcher.evaluateMovieCandidates(
          detectedTitle: candA2,
          detectedYear: 1957,
          candidates: tmdb2,
        );
        final decB2 = matcher.evaluateMovieCandidates(
          detectedTitle: candB2,
          detectedYear: 1957,
          candidates: tmdb2,
        );
        final win2 = MetadataMatcher.selectStrongestMovieMatch(
          candidateA: candA2,
          decisionA: decA2,
          candidateB: candB2,
          decisionB: decB2,
        );
        expect(win2.isAutomatic, isTrue);
        expect(win2.bestMatch?.title, '12 Angry Men');

        // 3. "17 Again"
        final candA3 = "17 Again";
        final candB3 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA3,
        )!;
        final tmdb3 = [
          const TmdbMovieSearchResult(
            id: 16996,
            title: '17 Again',
            releaseYear: 2009,
          ),
        ];
        final decA3 = matcher.evaluateMovieCandidates(
          detectedTitle: candA3,
          detectedYear: 2009,
          candidates: tmdb3,
        );
        final decB3 = matcher.evaluateMovieCandidates(
          detectedTitle: candB3,
          detectedYear: 2009,
          candidates: tmdb3,
        );
        final win3 = MetadataMatcher.selectStrongestMovieMatch(
          candidateA: candA3,
          decisionA: decA3,
          candidateB: candB3,
          decisionB: decB3,
        );
        expect(win3.isAutomatic, isTrue);
        expect(win3.bestMatch?.title, '17 Again');

        // 4. "21 Jump Street"
        final candA4 = "21 Jump Street";
        final candB4 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA4,
        )!;
        final tmdb4 = [
          const TmdbMovieSearchResult(
            id: 64688,
            title: '21 Jump Street',
            releaseYear: 2012,
          ),
        ];
        final decA4 = matcher.evaluateMovieCandidates(
          detectedTitle: candA4,
          detectedYear: 2012,
          candidates: tmdb4,
        );
        final decB4 = matcher.evaluateMovieCandidates(
          detectedTitle: candB4,
          detectedYear: 2012,
          candidates: tmdb4,
        );
        final win4 = MetadataMatcher.selectStrongestMovieMatch(
          candidateA: candA4,
          decisionA: decA4,
          candidateB: candB4,
          decisionB: decB4,
        );
        expect(win4.isAutomatic, isTrue);
        expect(win4.bestMatch?.title, '21 Jump Street');

        // 5. "22 Jump Street"
        final candA5 = "22 Jump Street";
        final candB5 = MetadataMatcher.extractOrderingPrefixStrippedCandidate(
          candA5,
        )!;
        final tmdb5 = [
          const TmdbMovieSearchResult(
            id: 187017,
            title: '22 Jump Street',
            releaseYear: 2014,
          ),
        ];
        final decA5 = matcher.evaluateMovieCandidates(
          detectedTitle: candA5,
          detectedYear: 2014,
          candidates: tmdb5,
        );
        final decB5 = matcher.evaluateMovieCandidates(
          detectedTitle: candB5,
          detectedYear: 2014,
          candidates: tmdb5,
        );
        final win5 = MetadataMatcher.selectStrongestMovieMatch(
          candidateA: candA5,
          decisionA: decA5,
          candidateB: candB5,
          decisionB: decB5,
        );
        expect(win5.isAutomatic, isTrue);
        expect(win5.bestMatch?.title, '22 Jump Street');

        // 6. "1917"
        final candA6 = "1917";
        final tmdb6 = [
          const TmdbMovieSearchResult(
            id: 530915,
            title: '1917',
            releaseYear: 2019,
          ),
        ];
        final decA6 = matcher.evaluateMovieCandidates(
          detectedTitle: candA6,
          detectedYear: 2019,
          candidates: tmdb6,
        );
        expect(decA6.isAutomatic, isTrue);
        expect(decA6.bestMatch?.title, '1917');

        // 7. "2001 A Space Odyssey"
        final candA7 = "2001 A Space Odyssey";
        expect(
          MetadataMatcher.extractOrderingPrefixStrippedCandidate(candA7),
          isNull,
        );
        final tmdb7 = [
          const TmdbMovieSearchResult(
            id: 62,
            title: '2001: A Space Odyssey',
            releaseYear: 1968,
          ),
        ];
        final decA7 = matcher.evaluateMovieCandidates(
          detectedTitle: candA7,
          detectedYear: 1968,
          candidates: tmdb7,
        );
        expect(decA7.isAutomatic, isTrue);
        expect(decA7.bestMatch?.title, '2001: A Space Odyssey');

        // 8. "300"
        final candA8 = "300";
        final tmdb8 = [
          const TmdbMovieSearchResult(
            id: 1271,
            title: '300',
            releaseYear: 2006,
          ),
        ];
        final decA8 = matcher.evaluateMovieCandidates(
          detectedTitle: candA8,
          detectedYear: 2006,
          candidates: tmdb8,
        );
        expect(decA8.isAutomatic, isTrue);
        expect(decA8.bestMatch?.title, '300');
      },
    );

    test('ambiguous cases: select candidate with strongest valid canonical identity', () {
      final candA = "1 Movie Title";
      final candB = "Movie Title";

      final decA = const MatchDecision<TmdbMovieSearchResult>(
        type: MatchDecisionType.needsVerification,
        confidence: 0.60,
        reason: 'Low confidence',
      );
      final decB = const MatchDecision<TmdbMovieSearchResult>(
        type: MatchDecisionType.automaticMatch,
        bestMatch: TmdbMovieSearchResult(
          id: 12345,
          title: 'Movie Title',
          releaseYear: 2020,
        ),
        confidence: 0.98,
        reason: 'High confidence',
      );

      final result = MetadataMatcher.selectStrongestMovieMatch(
        candidateA: candA,
        decisionA: decA,
        candidateB: candB,
        decisionB: decB,
      );

      expect(result.isAutomatic, isTrue);
      expect(result.bestMatch?.title, 'Movie Title');
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
