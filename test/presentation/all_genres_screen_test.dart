import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/presentation/collections/all_genres_screen.dart';
import 'package:reelhouse/presentation/collections/system_curation_grid_screen.dart';
import 'package:reelhouse/presentation/widgets/cinema_genre_tile.dart';

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

  testWidgets(
    'AllGenresScreen displays responsive 4-column grid of all discovered genres on desktop',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();

      // Seed media with various genres
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-1',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              genres: const drift.Value('Action, Science Fiction, Thriller'),
              backdropPath: const drift.Value('/non_existent/backdrop.jpg'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-2',
              detectedTitle: 'The Grand Budapest Hotel',
              title: const drift.Value('The Grand Budapest Hotel'),
              genres: const drift.Value('Comedy, Drama'),
              posterPath: const drift.Value('/non_existent/poster.jpg'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: AllGenresScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Genres'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Science Fiction'), findsOneWidget);
      expect(find.text('Thriller'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);

      // Verify CinemaGenreTile widgets and chevrons
      expect(find.byType(CinemaGenreTile), findsNWidgets(5));
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(5));

      // Tapping a genre opens SystemCurationGridScreen
      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();

      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('Action'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'AllGenresScreen adapts cleanly to medium tablet viewport without layout overflow',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-1',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              genres: const drift.Value('Action, Science Fiction, Thriller'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: AllGenresScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Genres'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Science Fiction'), findsOneWidget);
      expect(find.text('Thriller'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'AllGenresScreen adapts cleanly to narrow mobile viewport without layout overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-1',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              genres: const drift.Value('Action, Science Fiction, Thriller'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: AllGenresScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Genres'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Science Fiction'), findsOneWidget);
      expect(find.text('Thriller'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'AllGenresScreen adapts cleanly to very narrow viewport (300px) without layout overflow',
    (tester) async {
      tester.view.physicalSize = const Size(300, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-1',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              genres: const drift.Value('Action, Science Fiction, Thriller'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: AllGenresScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Genres'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'AllGenresScreen renders in Gallery Linen (light) theme without error',
    (tester) async {
      final now = DateTime.now();

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-1',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              genres: const drift.Value('Action'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.lightTheme,
          home: AllGenresScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Genres'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.byType(CinemaGenreTile), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('AllGenresScreen shows empty message when no genres exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: AllGenresScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No genres found in library.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
