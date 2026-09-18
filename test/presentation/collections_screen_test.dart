import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/presentation/collections/all_franchises_screen.dart';
import 'package:reelhouse/presentation/collections/collection_detail_screen.dart';
import 'package:reelhouse/presentation/collections/collections_screen.dart';
import 'package:reelhouse/presentation/collections/system_curation_grid_screen.dart';
import 'package:reelhouse/presentation/widgets/responsive_card_row.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'CollectionsScreen displays genre chip strip, responsive shelves, and navigates to genre detail grid',
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

      // Seed a movie with a long-tail genre (Documentary)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-doc',
              detectedTitle: 'Planet Earth',
              title: const drift.Value('Planet Earth'),
              year: const drift.Value(2006),
              genres: const drift.Value('Documentary'),
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

      // Verify clean section headers
      expect(find.text('GENRES'), findsOneWidget);
      expect(find.text('FRANCHISES'), findsOneWidget);
      expect(find.text('YOUR COLLECTIONS'), findsOneWidget);

      // Verify NO internal/architectural terminology exists
      expect(find.text('SYSTEM CURATION — GENRES'), findsNothing);
      expect(
        find.text('Dynamic metadata-derived catalogue views'),
        findsNothing,
      );
      expect(find.text('Custom lists curated by you'), findsNothing);
      expect(find.text('FRANCHISES & SAGAS'), findsNothing);

      // Verify horizontal genre chips exist for all discovered genres
      expect(find.text('Action'), findsWidgets);
      expect(find.text('Science Fiction'), findsWidgets);
      expect(find.text('Documentary'), findsOneWidget);

      // Non-represented genres are NOT shown
      expect(find.text('Western'), findsNothing);
      expect(find.text('Romance'), findsNothing);

      // Verify prominent genre shelves exist for Action and Science Fiction
      expect(find.text('ACTION'), findsOneWidget);
      expect(find.text('SCIENCE FICTION'), findsOneWidget);

      // Multi-genre media appears in both genre rows
      expect(find.text('Star Wars: A New Hope'), findsWidgets);
      expect(find.text('The Matrix'), findsWidgets);

      // Verify franchise card
      expect(find.text('Star Wars Collection'), findsOneWidget);
      expect(find.text('1 Film'), findsOneWidget);

      // Verify shelf rows use ResponsiveCardRow (no horizontal scrolling ListViews)
      expect(find.byType(ResponsiveCardRow), findsWidgets);

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

      // Tap prominent genre chip (Action) - navigates to SystemCurationGridScreen
      final actionChip = find.text('Action').first;
      await tester.tap(actionChip);
      await tester.pumpAndSettle();
      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('Action'), findsWidgets);

      // Pop SystemCurationGridScreen
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Tap long-tail genre chip (Documentary) - navigates directly to SystemCurationGridScreen
      final docChip = find.text('Documentary');
      await tester.tap(docChip);
      await tester.pumpAndSettle();

      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('Documentary'), findsWidgets);

      // Pop SystemCurationGridScreen
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Tap 'View All' on ACTION shelf opens SystemCurationGridScreen for Action
      final actionViewAll = find
          .widgetWithText(TextButton, 'View All')
          .first; // ACTION shelf View All
      await tester.ensureVisible(actionViewAll);
      await tester.pumpAndSettle();
      await tester.tap(actionViewAll);
      await tester.pumpAndSettle();

      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('Action'), findsWidgets);

      // Pop SystemCurationGridScreen
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Tap main 'FRANCHISES' View All opens AllFranchisesScreen
      final viewAllFranchisesButton = find
          .widgetWithText(TextButton, 'View All')
          .at(2); // after ACTION, SCIENCE FICTION View Alls
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
    'CollectionsScreen adapts to narrow mobile viewport without layout overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();

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

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: CollectionsScreen(database: db),
        ),
      );

      await tester.pumpAndSettle();

      // Check no flutter exceptions/overflow occurred
      expect(tester.takeException(), isNull);
      expect(find.text('GENRES'), findsOneWidget);
      expect(find.text('Action'), findsWidgets);
      expect(find.text('ACTION'), findsOneWidget);

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

  testWidgets(
    'Genre chip strip navigation buttons: absent when all fit, interactive when overflowing, supports tapping and manual scroll in dark & light themes',
    (tester) async {
      final now = DateTime.now();

      // Seed 2 genres that easily fit on a wide desktop screen
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-act',
              detectedTitle: 'Action Movie',
              title: const drift.Value('Action Movie'),
              genres: const drift.Value('Action'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-com',
              detectedTitle: 'Comedy Movie',
              title: const drift.Value('Comedy Movie'),
              genres: const drift.Value('Comedy'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Wide desktop: both genres fit without scrolling
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: CollectionsScreen(database: db),
        ),
      );
      await tester.pumpAndSettle();

      // When all genres fit, left and right nav buttons are absent
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);

      // Now seed additional distinct genres so the strip overflows
      final additionalGenres = [
        'Adventure',
        'Crime',
        'Documentary',
        'Drama',
        'Fantasy',
        'Horror',
        'Mystery',
        'Romance',
        'Science Fiction',
        'Thriller',
        'Western',
      ];

      for (var i = 0; i < additionalGenres.length; i++) {
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-extra-$i',
                detectedTitle: 'Film $i',
                title: drift.Value('Film $i'),
                genres: drift.Value(additionalGenres[i]),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // Re-render in mobile viewport to guarantee overflow
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: CollectionsScreen(database: db),
        ),
      );
      await tester.pumpAndSettle();

      // Right button is present, Left button is absent initially
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      final genreListFinder = find.byKey(const ValueKey('genre_chip_list'));
      expect(genreListFinder, findsOneWidget);

      final genreScrollable = find.descendant(
        of: genreListFinder,
        matching: find.byType(Scrollable),
      );
      expect(genreScrollable, findsOneWidget);

      // Verify initial position
      final initialScrollable = tester.state<ScrollableState>(genreScrollable);
      expect(initialScrollable.position.pixels, 0.0);

      // Tap the right navigation button
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      // Scroll position moved to the right and left button is now visible
      final movedScrollable = tester.state<ScrollableState>(genreScrollable);
      expect(movedScrollable.position.pixels, greaterThan(0.0));
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      // Tap the left navigation button to return to the start
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      // Scroll position returns to start; left button disappears
      final returnedScrollable = tester.state<ScrollableState>(genreScrollable);
      expect(returnedScrollable.position.pixels, 0.0);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Drag to the absolute end of the strip
      await tester.drag(genreListFinder, const Offset(-1000, 0));
      await tester.pumpAndSettle();
      await tester.drag(genreListFinder, const Offset(-1000, 0));
      await tester.pumpAndSettle();

      // Right button disappears at max extent, left button remains, Western is visible
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.text('Western'), findsOneWidget);

      // Scroll back via left button tap
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      // Both buttons visible mid-scroll
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Test Gallery Linen (light theme)
      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.lightTheme,
          home: CollectionsScreen(database: db),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Every genre chip navigates directly to SystemCurationGridScreen regardless of rendered shelf presence',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();

      // 1. Rendered shelf genre 1 (Action movie)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-die-hard',
              detectedTitle: 'Die Hard',
              title: const drift.Value('Die Hard'),
              year: const drift.Value(1988),
              genres: const drift.Value('Action'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 2. Rendered shelf genre 2 (Science Fiction movie)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-interstellar',
              detectedTitle: 'Interstellar',
              title: const drift.Value('Interstellar'),
              year: const drift.Value(2014),
              genres: const drift.Value('Science Fiction'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 3. Prominent genre with ONLY TV Shows (0 movies in library) - reproduces regression case
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-breaking-bad',
              detectedTitle: 'Breaking Bad',
              title: const drift.Value('Breaking Bad'),
              genres: const drift.Value('Drama'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 4. Long-tail genre without dedicated shelf (Animation movie)
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-spirited-away',
              detectedTitle: 'Spirited Away',
              title: const drift.Value('Spirited Away'),
              year: const drift.Value(2001),
              genres: const drift.Value('Animation'),
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

      // Verify discovered genre chips are rendered
      expect(find.text('Action'), findsWidgets);
      expect(find.text('Science Fiction'), findsWidgets);
      expect(find.text('Drama'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);

      // Verify ONLY Action and Science Fiction have dedicated rendered shelves
      expect(find.text('ACTION'), findsOneWidget);
      expect(find.text('SCIENCE FICTION'), findsOneWidget);
      expect(find.text('DRAMA'), findsNothing);
      expect(find.text('ANIMATION'), findsNothing);

      // 1. Tapping Action chip (has dedicated shelf) -> navigates directly to SystemCurationGridScreen
      final actionChip = find.text('Action').first;
      await tester.tap(actionChip);
      await tester.pumpAndSettle();
      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('Action'), findsWidgets);
      expect(find.text('Die Hard'), findsOneWidget);

      // Return to CollectionsScreen
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SystemCurationGridScreen), findsNothing);

      // 2. Tapping Science Fiction chip (has dedicated shelf) -> navigates directly to SystemCurationGridScreen
      final sciFiChip = find.text('Science Fiction').first;
      await tester.tap(sciFiChip);
      await tester.pumpAndSettle();
      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('Science Fiction'), findsWidgets);
      expect(find.text('Interstellar'), findsOneWidget);

      // Return to CollectionsScreen
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SystemCurationGridScreen), findsNothing);

      // 3. Tapping Drama chip (prominent genre, TV-only with NO rendered shelf) -> navigates to SystemCurationGridScreen
      final dramaChip = find.text('Drama');
      await tester.tap(dramaChip);
      await tester.pumpAndSettle();
      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('Drama'), findsWidgets);
      expect(find.text('Breaking Bad'), findsOneWidget);

      // Return to CollectionsScreen
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SystemCurationGridScreen), findsNothing);

      // 4. Tapping Animation chip (long-tail genre with NO rendered shelf) -> navigates to SystemCurationGridScreen
      final animChip = find.text('Animation');
      await tester.tap(animChip);
      await tester.pumpAndSettle();
      expect(find.byType(SystemCurationGridScreen), findsOneWidget);
      expect(find.text('Animation'), findsWidgets);
      expect(find.text('Spirited Away'), findsOneWidget);

      // Return to CollectionsScreen
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SystemCurationGridScreen), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
