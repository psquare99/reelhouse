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
              detectedTitle: 'The Dark Knight',
              title: const drift.Value('The Dark Knight'),
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

  testWidgets(
    'CollectionDetailScreen Add Media dialog provides real-time search filtering',
    (tester) async {
      final now = DateTime.now();

      // Seed movies
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-oppenheimer',
              detectedTitle: 'Oppenheimer',
              title: const drift.Value('Oppenheimer'),
              year: const drift.Value(2023),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-dunkirk',
              detectedTitle: 'Dunkirk',
              title: const drift.Value('Dunkirk'),
              year: const drift.Value(2017),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Seed TV Show
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-chernobyl',
              detectedTitle: 'Chernobyl',
              title: const drift.Value('Chernobyl'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Create collection
      await db.createCollection(
        CollectionsCompanion.insert(
          id: 'col-history',
          name: 'Historical Drama',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: CollectionDetailScreen(
            collectionId: 'col-history',
            database: db,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Add Media sheet
      final addMediaButton = find.widgetWithText(ElevatedButton, 'Add Media');
      expect(addMediaButton, findsOneWidget);
      await tester.tap(addMediaButton);
      await tester.pumpAndSettle();

      expect(find.text('Add Media to Collection'), findsOneWidget);
      expect(find.text('Oppenheimer'), findsOneWidget);
      expect(find.text('Dunkirk'), findsOneWidget);
      expect(find.text('Chernobyl'), findsOneWidget);

      // Search 'oppen' (case-insensitive)
      final searchInput = find.widgetWithText(
        TextField,
        'Search library to add...',
      );
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'oppen');
      await tester.pumpAndSettle();

      expect(find.text('Oppenheimer'), findsOneWidget);
      expect(find.text('Dunkirk'), findsNothing);
      expect(find.text('Chernobyl'), findsNothing);

      // Search 'chernobyl'
      await tester.enterText(searchInput, 'chernobyl');
      await tester.pumpAndSettle();

      expect(find.text('Oppenheimer'), findsNothing);
      expect(find.text('Dunkirk'), findsNothing);
      expect(find.text('Chernobyl'), findsOneWidget);

      // Add Chernobyl to collection
      await tester.tap(find.text('Chernobyl'));
      await tester.pumpAndSettle();

      // Verify Chernobyl is now in the collection screen
      expect(find.text('Chernobyl'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
