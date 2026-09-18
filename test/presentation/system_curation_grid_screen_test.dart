import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/presentation/collections/system_curation_grid_screen.dart';
import 'package:reelhouse/presentation/movies/movie_detail_screen.dart';

void main() {
  late AppDatabase db;
  late DriftLibraryRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftLibraryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedCurationMedia() async {
    final now = DateTime.now();

    // 1. Movie in Sci-Fi genre & Star Wars franchise
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-sw-ep4',
            detectedTitle: 'Star Wars A New Hope',
            title: const drift.Value('Star Wars: A New Hope'),
            year: const drift.Value(1977),
            genres: const drift.Value('Action, Adventure, Science Fiction'),
            tmdbCollectionId: const drift.Value(10),
            tmdbCollectionName: const drift.Value('Star Wars Collection'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // 2. TV Show in Sci-Fi genre
    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'tv-andor',
            detectedTitle: 'Andor',
            title: const drift.Value('Andor'),
            genres: const drift.Value('Drama, Science Fiction'),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  testWidgets(
    'SystemCurationGridScreen displays genre media for both movies and tv shows',
    (tester) async {
      await seedCurationMedia();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: SystemCurationGridScreen(
            title: 'Science Fiction',
            genre: 'Science Fiction',
            repository: repository,
            database: db,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Science Fiction'), findsOneWidget);
      expect(find.text('Star Wars: A New Hope'), findsOneWidget);
      expect(find.text('Andor'), findsOneWidget);

      // Verify NO internal/architectural language
      expect(find.text('System Curation • Genre Catalogue'), findsNothing);
      expect(find.text('Canonical Franchise Grouping'), findsNothing);

      // Tap movie card navigates to MovieDetailScreen
      await tester.tap(find.text('Star Wars: A New Hope'));
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'SystemCurationGridScreen displays franchise media filtered by tmdbCollectionId',
    (tester) async {
      await seedCurationMedia();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: SystemCurationGridScreen(
            title: 'Star Wars Collection',
            tmdbCollectionId: 10,
            repository: repository,
            database: db,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Star Wars Collection'), findsOneWidget);
      expect(find.text('Star Wars: A New Hope'), findsOneWidget);
      // TV show should not be present in movie franchise collection
      expect(find.text('Andor'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
