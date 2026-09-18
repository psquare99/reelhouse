import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/presentation/collections/all_franchises_screen.dart';
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
    'AllFranchisesScreen displays responsive poster grid of all local franchises',
    (tester) async {
      final now = DateTime.now();

      // Seed franchise movies
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-lotr-1',
              detectedTitle: 'The Fellowship of the Ring',
              title: const drift.Value('The Fellowship of the Ring'),
              tmdbCollectionId: const drift.Value(119),
              tmdbCollectionName: const drift.Value(
                'The Lord of the Rings Collection',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-lotr-2',
              detectedTitle: 'The Two Towers',
              title: const drift.Value('The Two Towers'),
              tmdbCollectionId: const drift.Value(119),
              tmdbCollectionName: const drift.Value(
                'The Lord of the Rings Collection',
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-matrix-1',
              detectedTitle: 'The Matrix',
              title: const drift.Value('The Matrix'),
              tmdbCollectionId: const drift.Value(635),
              tmdbCollectionName: const drift.Value('The Matrix Collection'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: AllFranchisesScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Franchises'), findsOneWidget);
      expect(find.text('The Lord of the Rings Collection'), findsOneWidget);
      expect(find.text('2 Films'), findsOneWidget);
      expect(find.text('The Matrix Collection'), findsOneWidget);
      expect(find.text('1 Film'), findsOneWidget);

      // Tapping a franchise opens SystemCurationGridScreen
      await tester.tap(find.text('The Lord of the Rings Collection'));
      await tester.pumpAndSettle();

      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('The Lord of the Rings Collection'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'AllFranchisesScreen shows empty message when no franchises exist',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: AllFranchisesScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No franchises found in library.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
