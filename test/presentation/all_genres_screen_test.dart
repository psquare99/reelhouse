import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/presentation/collections/all_genres_screen.dart';
import 'package:reelhouse/presentation/collections/system_curation_grid_screen.dart';

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
    'AllGenresScreen displays responsive grid of all discovered genres',
    (tester) async {
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

      expect(find.text('Genres'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Science Fiction'), findsOneWidget);
      expect(find.text('Thriller'), findsOneWidget);
      expect(find.text('Comedy'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);

      // Tapping a genre opens SystemCurationGridScreen
      await tester.tap(find.text('Action'));
      await tester.pumpAndSettle();

      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('Action'), findsWidgets);

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
