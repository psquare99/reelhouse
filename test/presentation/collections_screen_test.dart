import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/presentation/collections/all_franchises_screen.dart';
import 'package:reelhouse/presentation/collections/all_genres_screen.dart';
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
    'CollectionsScreen displays prominent genre rows, franchises, View All links, and personal collections',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();

      // Seed a movie with Action & Sci-Fi genres & Star Wars franchise
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-sw',
              detectedTitle: 'Star Wars: A New Hope',
              title: const drift.Value('Star Wars: A New Hope'),
              year: const drift.Value(1977),
              genres: const drift.Value('Action, Science Fiction'),
              tmdbCollectionId: const drift.Value(10),
              tmdbCollectionName: const drift.Value('Star Wars Collection'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Seed another Action movie
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-matrix',
              detectedTitle: 'The Matrix',
              title: const drift.Value('The Matrix'),
              year: const drift.Value(1999),
              genres: const drift.Value('Action, Science Fiction'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: CollectionsScreen(database: db),
        ),
      );

      await tester.pumpAndSettle();

      // Verify clean section headers without implementation terminology
      expect(find.text('GENRES'), findsOneWidget);
      expect(find.text('FRANCHISES'), findsOneWidget);
      expect(find.text('YOUR COLLECTIONS'), findsOneWidget);

      // Verify NO architectural/internal language exists
      expect(find.text('SYSTEM CURATION — GENRES'), findsNothing);
      expect(
        find.text('Dynamic metadata-derived catalogue views'),
        findsNothing,
      );
      expect(find.text('Custom lists curated by you'), findsNothing);
      expect(find.text('FRANCHISES & SAGAS'), findsNothing);

      // Verify prominent genre row headers
      expect(find.text('ACTION'), findsOneWidget);
      expect(find.text('SCIENCE FICTION'), findsOneWidget);

      // Multi-genre media appears in both genre rows
      expect(find.text('Star Wars: A New Hope'), findsWidgets);
      expect(find.text('The Matrix'), findsWidgets);

      // Non-represented genres are NOT shown
      expect(find.text('DOCUMENTARY'), findsNothing);
      expect(find.text('WESTERN'), findsNothing);

      // Verify franchise card
      expect(find.text('Star Wars Collection'), findsOneWidget);
      expect(find.text('1 Film'), findsOneWidget);

      // Verify personal collections empty state
      expect(find.text('No personal collections yet.'), findsOneWidget);
      expect(
        find.text(
          'Create a collection for a marathon, a theme, or anything you want to keep together.',
        ),
        findsOneWidget,
      );

      // Tap create button opens dialog
      final createButton = find.widgetWithText(ElevatedButton, 'Create');
      expect(createButton, findsOneWidget);
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('New Curated Collection'), findsOneWidget);
      expect(find.text('Collection Name'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Tap main 'GENRES' View All opens AllGenresScreen
      final viewAllGenresButton = find
          .widgetWithText(TextButton, 'View All')
          .first;
      await tester.ensureVisible(viewAllGenresButton);
      await tester.pumpAndSettle();
      await tester.tap(viewAllGenresButton);
      await tester.pumpAndSettle();

      expect(find.byType(AllGenresScreen), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Science Fiction'), findsOneWidget);

      // Pop AllGenresScreen
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Tap main 'FRANCHISES' View All opens AllFranchisesScreen
      final viewAllFranchisesButton = find
          .widgetWithText(TextButton, 'View All')
          .last;
      await tester.ensureVisible(viewAllFranchisesButton);
      await tester.pumpAndSettle();
      await tester.tap(viewAllFranchisesButton);
      await tester.pumpAndSettle();

      expect(find.byType(AllFranchisesScreen), findsOneWidget);
      expect(find.text('Star Wars Collection'), findsOneWidget);

      // Pop AllFranchisesScreen
      await tester.pageBack();
      await tester.pumpAndSettle();

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
