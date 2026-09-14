import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/metadata/fallback_metadata_orchestrator.dart';
import 'package:reelhouse/domain/metadata/metadata_diagnostics.dart';
import 'package:reelhouse/domain/metadata/metadata_provider.dart';

// ---------------------------------------------------------------------------
// Fake Providers
// ---------------------------------------------------------------------------

/// A [MetadataProvider] that always returns the supplied candidates and details.
class _FakeProvider implements MetadataProvider {
  @override
  final String id;
  @override
  final String displayName;
  @override
  final bool isConfigured;

  final List<ProviderCandidate> candidates;
  final ProviderMovieDetails? movieDetails;
  final ProviderTvDetails? tvDetails;

  const _FakeProvider({
    required this.id,
    required this.displayName,
    this.isConfigured = true,
    this.candidates = const [],
    this.movieDetails,
    this.tvDetails,
  });

  @override
  Future<List<ProviderCandidate>> searchMovies(
    String title, {
    int? year,
  }) async => candidates;

  @override
  Future<List<ProviderCandidate>> searchTvShows(String title) async =>
      candidates;

  @override
  Future<ProviderMovieDetails?> getMovieDetails(String providerItemId) async =>
      movieDetails;

  @override
  Future<ProviderTvDetails?> getTvShowDetails(String providerItemId) async =>
      tvDetails;
}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

ProviderCandidate _movieCandidate({
  String id = '42',
  String title = 'Interstellar',
  int year = 2014,
}) {
  return ProviderCandidate(
    providerId: 'TMDB',
    providerItemId: id,
    title: title,
    year: year,
  );
}

ProviderMovieDetails _movieDetails({
  String id = '42',
  String title = 'Interstellar',
}) {
  return ProviderMovieDetails(
    providerId: 'TMDB',
    providerItemId: id,
    title: title,
    releaseYear: 2014,
  );
}

ProviderCandidate _tvCandidate({
  String id = '1399',
  String title = 'Game of Thrones',
  int year = 2011,
}) {
  return ProviderCandidate(
    providerId: 'TMDB',
    providerItemId: id,
    title: title,
    year: year,
  );
}

ProviderTvDetails _tvDetails({
  String id = '1399',
  String title = 'Game of Thrones',
}) {
  return ProviderTvDetails(
    providerId: 'TMDB',
    providerItemId: id,
    title: title,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FallbackMetadataOrchestrator — movies', () {
    test('primary success: returns details, isFallbackUsed = false', () async {
      final candidate = _movieCandidate();
      final details = _movieDetails();

      final orchestrator = FallbackMetadataOrchestrator(
        primaryProvider: _FakeProvider(
          id: 'TMDB',
          displayName: 'TMDB',
          candidates: [candidate],
          movieDetails: details,
        ),
      );

      final result = await orchestrator.identifyMovie(
        mediaId: 'movie-1',
        detectedTitle: 'Interstellar',
        detectedYear: 2014,
      );

      expect(result.isSuccess, true);
      expect(result.isFallbackUsed, false);
      expect(result.providerId, 'TMDB');
      expect(result.details?.title, 'Interstellar');
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    test(
      'primary returns 0 candidates → fallback queried and succeeds',
      () async {
        final fallbackCandidate = ProviderCandidate(
          providerId: 'OMDb',
          providerItemId: 'tt0816692',
          title: 'Interstellar',
          year: 2014,
        );
        final fallbackDetails = ProviderMovieDetails(
          providerId: 'OMDb',
          providerItemId: 'tt0816692',
          title: 'Interstellar',
        );

        final orchestrator = FallbackMetadataOrchestrator(
          primaryProvider: _FakeProvider(
            id: 'TMDB',
            displayName: 'TMDB',
            // returns no candidates
          ),
          movieFallbackProvider: _FakeProvider(
            id: 'OMDb',
            displayName: 'OMDb',
            candidates: [fallbackCandidate],
            movieDetails: fallbackDetails,
          ),
        );

        final result = await orchestrator.identifyMovie(
          mediaId: 'movie-1',
          detectedTitle: 'Interstellar',
          detectedYear: 2014,
        );

        expect(result.isSuccess, true);
        expect(result.isFallbackUsed, true);
        expect(result.providerId, 'OMDb');
        expect(result.details?.title, 'Interstellar');
      },
    );

    test('primary ambiguous (confidence < 0.85) → fallback NOT tried, needsVerification', () async {
      // "Total Recall" vs "Total Recall 2012" — low title similarity match
      // Simulate ambiguity: two very different candidates for the same query
      final candidate1 = ProviderCandidate(
        providerId: 'TMDB',
        providerItemId: '1234',
        title: 'Batman',
        year: 1989,
      );
      final candidate2 = ProviderCandidate(
        providerId: 'TMDB',
        providerItemId: '5678',
        title: 'Batman Returns',
        year: 1992,
      );

      // This orchestrator has a fallback configured, but it should NOT be used.
      final orchestrator = FallbackMetadataOrchestrator(
        primaryProvider: _FakeProvider(
          id: 'TMDB',
          displayName: 'TMDB',
          candidates: [candidate1, candidate2],
          movieDetails: _movieDetails(),
        ),
        movieFallbackProvider: _FakeProvider(
          id: 'OMDb',
          displayName: 'OMDb',
          candidates: [
            ProviderCandidate(
              providerId: 'OMDb',
              providerItemId: 'X',
              title: 'Bat',
              year: 1999,
            ),
          ],
          movieDetails: _movieDetails(id: 'X', title: 'Bat'),
        ),
      );

      // Search for something that won't closely match either candidate (low confidence)
      final result = await orchestrator.identifyMovie(
        mediaId: 'movie-x',
        detectedTitle: 'Xanadu Fantasia',
        detectedYear: 2000,
      );

      // The primary returned candidates but none will score ≥ 0.85
      // The orchestrator should NOT use the fallback in this case.
      expect(result.isSuccess, false);
      expect(result.isFallbackUsed, false);
      expect(
        result.diagnostic.category,
        MetadataFailureCategory.matchingAmbiguity,
      );
    });

    test('primary unconfigured → failure category = missingApiKey', () async {
      final orchestrator = FallbackMetadataOrchestrator(
        primaryProvider: _FakeProvider(
          id: 'TMDB',
          displayName: 'TMDB',
          isConfigured: false,
        ),
      );

      final result = await orchestrator.identifyMovie(
        mediaId: 'movie-1',
        detectedTitle: 'Interstellar',
      );

      expect(result.isSuccess, false);
      expect(result.diagnostic.category, MetadataFailureCategory.missingApiKey);
    });

    test('both providers fail → isSuccess = false, no crash', () async {
      final orchestrator = FallbackMetadataOrchestrator(
        primaryProvider: _FakeProvider(
          id: 'TMDB',
          displayName: 'TMDB',
          // no candidates
        ),
        movieFallbackProvider: _FakeProvider(
          id: 'OMDb',
          displayName: 'OMDb',
          // no candidates
        ),
      );

      final result = await orchestrator.identifyMovie(
        mediaId: 'movie-1',
        detectedTitle: 'SomeObscureFilm',
        detectedYear: 1923,
      );

      expect(result.isSuccess, false);
      expect(result.details, isNull);
    });
  });

  group('FallbackMetadataOrchestrator — TV shows', () {
    test(
      'primary success: returns TV details, isFallbackUsed = false',
      () async {
        final candidate = _tvCandidate();
        final details = _tvDetails();

        final orchestrator = FallbackMetadataOrchestrator(
          primaryProvider: _FakeProvider(
            id: 'TMDB',
            displayName: 'TMDB',
            candidates: [candidate],
            tvDetails: details,
          ),
        );

        final result = await orchestrator.identifyTvShow(
          mediaId: 'tv-1',
          detectedTitle: 'Game of Thrones',
        );

        expect(result.isSuccess, true);
        expect(result.isFallbackUsed, false);
        expect(result.details?.title, 'Game of Thrones');
      },
    );

    test('primary returns 0 candidates → TVmaze fallback used', () async {
      final tvmazeCandidates = [
        ProviderCandidate(
          providerId: 'TVmaze',
          providerItemId: '82',
          title: 'Game of Thrones',
          year: 2011,
        ),
      ];
      final tvmazeDetails = ProviderTvDetails(
        providerId: 'TVmaze',
        providerItemId: '82',
        title: 'Game of Thrones',
      );

      final orchestrator = FallbackMetadataOrchestrator(
        primaryProvider: _FakeProvider(
          id: 'TMDB',
          displayName: 'TMDB',
          // no candidates
        ),
        tvFallbackProvider: _FakeProvider(
          id: 'TVmaze',
          displayName: 'TVmaze',
          candidates: tvmazeCandidates,
          tvDetails: tvmazeDetails,
        ),
      );

      final result = await orchestrator.identifyTvShow(
        mediaId: 'tv-1',
        detectedTitle: 'Game of Thrones',
        detectedYear: 2011,
      );

      expect(result.isSuccess, true);
      expect(result.isFallbackUsed, true);
      expect(result.providerId, 'TVmaze');
    });

    test(
      'confidence gate: candidate scoring below 0.85 is never auto-accepted',
      () async {
        // Low-confidence candidate: title mismatch forces score below threshold
        final lowConfidenceCandidate = ProviderCandidate(
          providerId: 'TMDB',
          providerItemId: '999',
          title: 'Something Completely Different',
          year: 1999,
        );

        final orchestrator = FallbackMetadataOrchestrator(
          primaryProvider: _FakeProvider(
            id: 'TMDB',
            displayName: 'TMDB',
            candidates: [lowConfidenceCandidate],
            tvDetails: _tvDetails(),
          ),
        );

        // Searching for a very different title → confidence well below 0.85
        final result = await orchestrator.identifyTvShow(
          mediaId: 'tv-x',
          detectedTitle: 'Breaking Bad',
          detectedYear: 2008,
        );

        // Must not auto-accept a low-confidence match
        expect(result.isSuccess, false);
        // Either ambiguity or fallback failure, but no success
        expect(result.details, isNull);
      },
    );
  });
}
