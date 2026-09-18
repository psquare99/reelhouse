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

  Future<void> seedComprehensiveMedia() async {
    final now = DateTime.now();

    // Movies
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-act',
            detectedTitle: 'Die Hard',
            title: const drift.Value('Die Hard'),
            genres: const drift.Value('Action'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-adv',
            detectedTitle: 'Indiana Jones',
            title: const drift.Value('Indiana Jones'),
            genres: const drift.Value('Adventure'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-act-adv',
            detectedTitle: 'Uncharted',
            title: const drift.Value('Uncharted'),
            genres: const drift.Value('Action & Adventure'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-scifi',
            detectedTitle: 'Interstellar',
            title: const drift.Value('Interstellar'),
            genres: const drift.Value('Science Fiction'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-fantasy',
            detectedTitle: 'The Lord of the Rings',
            title: const drift.Value('The Lord of the Rings'),
            genres: const drift.Value('Fantasy'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-scifi-fantasy',
            detectedTitle: 'Star Wars A New Hope',
            title: const drift.Value('Star Wars: A New Hope'),
            genres: const drift.Value('Science Fiction, Fantasy'),
            tmdbCollectionId: const drift.Value(10),
            tmdbCollectionName: const drift.Value('Star Wars Collection'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-drama',
            detectedTitle: 'The Godfather',
            title: const drift.Value('The Godfather'),
            genres: const drift.Value('Drama'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // TV Shows
    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'tv-act-adv',
            detectedTitle: 'The Mandalorian',
            title: const drift.Value('The Mandalorian'),
            genres: const drift.Value('Action & Adventure, Sci-Fi & Fantasy'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'tv-drama',
            detectedTitle: 'Succession',
            title: const drift.Value('Succession'),
            genres: const drift.Value('Drama'),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  testWidgets(
    'Action & Adventure cross-media curation returns Action, Adventure, and combined TV/movie titles without unassociated genres',
    (tester) async {
      await seedComprehensiveMedia();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: SystemCurationGridScreen(
            title: 'Action & Adventure',
            genre: 'Action & Adventure',
            repository: repository,
            database: db,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Included
      expect(find.text('Die Hard'), findsOneWidget); // Action movie
      expect(find.text('Indiana Jones'), findsOneWidget); // Adventure movie
      expect(
        find.text('Uncharted'),
        findsOneWidget,
      ); // Action & Adventure movie
      expect(
        find.text('The Mandalorian'),
        findsOneWidget,
      ); // Action & Adventure TV Show

      // Excluded
      expect(find.text('The Godfather'), findsNothing); // Drama movie
      expect(find.text('Succession'), findsNothing); // Drama TV Show
      expect(find.text('Interstellar'), findsNothing); // Science Fiction only

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Sci-Fi & Fantasy cross-media curation returns Science Fiction, Fantasy, and combined titles without unassociated genres',
    (tester) async {
      await seedComprehensiveMedia();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: SystemCurationGridScreen(
            title: 'Sci-Fi & Fantasy',
            genre: 'Sci-Fi & Fantasy',
            repository: repository,
            database: db,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Included
      expect(
        find.text('Interstellar'),
        findsOneWidget,
      ); // Science Fiction movie
      expect(
        find.text('The Lord of the Rings'),
        findsOneWidget,
      ); // Fantasy movie
      expect(
        find.text('Star Wars: A New Hope'),
        findsOneWidget,
      ); // Sci-Fi & Fantasy movie
      expect(
        find.text('The Mandalorian'),
        findsOneWidget,
      ); // Sci-Fi & Fantasy TV Show

      // Excluded
      expect(find.text('The Godfather'), findsNothing);
      expect(find.text('Die Hard'), findsNothing);
      expect(find.text('Succession'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Ordinary Action genre returns Action titles without absorbing Adventure-only or Drama-only titles',
    (tester) async {
      await seedComprehensiveMedia();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: SystemCurationGridScreen(
            title: 'Action',
            genre: 'Action',
            repository: repository,
            database: db,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Action movie included
      expect(find.text('Die Hard'), findsOneWidget);

      // Adventure-only, Sci-Fi-only, Drama excluded
      expect(find.text('Indiana Jones'), findsNothing);
      expect(find.text('Interstellar'), findsNothing);
      expect(find.text('The Godfather'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Ordinary Fantasy genre returns Fantasy titles without absorbing Science-Fiction-only titles',
    (tester) async {
      await seedComprehensiveMedia();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: SystemCurationGridScreen(
            title: 'Fantasy',
            genre: 'Fantasy',
            repository: repository,
            database: db,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fantasy movie included
      expect(find.text('The Lord of the Rings'), findsOneWidget);
      expect(
        find.text('Star Wars: A New Hope'),
        findsOneWidget,
      ); // Multi-genre including Fantasy

      // Sci-Fi only and Drama excluded
      expect(find.text('Interstellar'), findsNothing);
      expect(find.text('The Godfather'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'SystemCurationGridScreen displays franchise media filtered by tmdbCollectionId',
    (tester) async {
      await seedComprehensiveMedia();

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
      expect(find.text('The Mandalorian'), findsNothing);

      // Tap movie card navigates to MovieDetailScreen
      await tester.tap(find.text('Star Wars: A New Hope'));
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
