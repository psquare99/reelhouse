import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/presentation/collections/collection_detail_screen.dart';
import 'package:reelhouse/presentation/collections/collections_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'CollectionsScreen displays empty state and opens creation dialog',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: CollectionsScreen(database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No curated collections yet.'), findsOneWidget);
      expect(find.text('Create Collection'), findsOneWidget);

      // Tap create button
      await tester.tap(find.text('Create Collection'));
      await tester.pumpAndSettle();

      expect(find.text('New Curated Collection'), findsOneWidget);
      expect(find.text('Collection Name'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'CollectionDetailScreen lists media items and supports adding items',
    (tester) async {
      final now = DateTime.now();

      // 1. Add movie
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-batman',
              title: 'The Dark Knight',
              year: const drift.Value(2008),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 2. Add collection
      await db.createCollection(
        CollectionsCompanion.insert(
          id: 'col-nolan',
          name: 'Christopher Nolan',
          overview: const drift.Value('Filmography of Christopher Nolan'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 3. Add movie to collection
      await db.addItemToCollection(
        CollectionItemsCompanion.insert(
          id: 'ci-1',
          collectionId: 'col-nolan',
          movieId: const drift.Value('m-batman'),
          addedAt: now,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: CollectionDetailScreen(collectionId: 'col-nolan', database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Christopher Nolan'), findsOneWidget);
      expect(find.text('The Dark Knight'), findsOneWidget);
      expect(find.text('2008'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
