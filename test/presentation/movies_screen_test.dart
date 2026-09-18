import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/presentation/movies/movies_screen.dart';
import 'package:reelhouse/presentation/widgets/cinema_poster_card.dart';

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

  Future<void> seedMovies() async {
    final t1 = DateTime(2026, 1, 1, 10, 0);
    final t2 = DateTime(2026, 1, 2, 10, 0);
    final t3 = DateTime(2026, 1, 3, 10, 0);

    // 1. Inception (2010, Rating 8.8, Favorite, Watched)
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-1',
            detectedTitle: 'Inception',
            title: const drift.Value('Inception'),
            year: const drift.Value(2010),
            rating: const drift.Value(8.8),
            isFavorite: const drift.Value(true),
            isWatchlist: const drift.Value(false),
            watchState: const drift.Value('WATCHED'),
            createdAt: t1,
            updatedAt: t1,
          ),
        );

    // 2. Interstellar (2014, Rating 8.6, Watchlist, In Progress)
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-2',
            detectedTitle: 'Interstellar',
            title: const drift.Value('Interstellar'),
            year: const drift.Value(2014),
            rating: const drift.Value(8.6),
            isFavorite: const drift.Value(false),
            isWatchlist: const drift.Value(true),
            watchState: const drift.Value('IN_PROGRESS'),
            createdAt: t2,
            updatedAt: t2,
          ),
        );

    // 3. Tenet (2020, Rating 7.4, Unwatched)
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-3',
            detectedTitle: 'Tenet',
            title: const drift.Value('Tenet'),
            year: const drift.Value(2020),
            rating: const drift.Value(7.4),
            isFavorite: const drift.Value(false),
            isWatchlist: const drift.Value(false),
            watchState: const drift.Value('UNWATCHED'),
            createdAt: t3,
            updatedAt: t3,
          ),
        );

    // Storage and media sources for availability test
    await db
        .into(db.storages)
        .insertOnConflictUpdate(
          StoragesCompanion.insert(
            id: 'disk-main',
            name: 'Main Storage',
            storageType: 'EXTERNAL_DRIVE',
            filesystemIdentifier: 'fs-main',
            rootUri: '/media/main',
            lastSeenAt: DateTime.now(),
            available: const drift.Value(true),
          ),
        );

    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'ms-1',
            movieId: const drift.Value('m-1'),
            storageId: 'disk-main',
            relativePath: 'Inception.mkv',
            filename: 'Inception.mkv',
            extension: 'mkv',
            fileSize: BigInt.from(1000),
            sourceType: 'EXTERNAL_STORAGE_COPY',
            firstSeenAt: DateTime.now(),
            lastSeenAt: DateTime.now(),
            createdAt: DateTime.now(),
            available: const drift.Value(true),
          ),
        );
  }

  testWidgets('MoviesScreen renders empty state when library has no movies', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: MoviesScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No movies discovered yet.'), findsOneWidget);
    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('MoviesScreen renders catalogue and applies repository filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await seedMovies();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: MoviesScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    // Default: ALL (Title ASC) -> Inception, Interstellar, Tenet
    expect(find.text('Inception'), findsOneWidget);
    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('Tenet'), findsOneWidget);

    // Filter: FAVORITES -> only Inception
    final favChip = find.widgetWithText(ChoiceChip, 'Favorites');
    await tester.ensureVisible(favChip);
    await tester.pumpAndSettle();
    await tester.tap(favChip);
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
    expect(find.text('Interstellar'), findsNothing);
    expect(find.text('Tenet'), findsNothing);

    // Filter: WATCHLIST -> only Interstellar
    final watchChip = find.widgetWithText(ChoiceChip, 'Watchlist');
    await tester.ensureVisible(watchChip);
    await tester.pumpAndSettle();
    await tester.tap(watchChip);
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsNothing);
    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('Tenet'), findsNothing);

    // Filter: IN PROGRESS -> only Interstellar
    final inProgressChip = find.widgetWithText(ChoiceChip, 'In Progress');
    await tester.ensureVisible(inProgressChip);
    await tester.pumpAndSettle();
    await tester.tap(inProgressChip);
    await tester.pumpAndSettle();

    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('Tenet'), findsNothing);

    // Filter: UNWATCHED -> only Tenet
    final unwatchedChip = find.widgetWithText(ChoiceChip, 'Unwatched');
    await tester.ensureVisible(unwatchedChip);
    await tester.pumpAndSettle();
    await tester.tap(unwatchedChip);
    await tester.pumpAndSettle();

    expect(find.text('Tenet'), findsOneWidget);
    expect(find.text('Inception'), findsNothing);
    expect(find.text('Interstellar'), findsNothing);

    // Filter: AVAILABLE -> only Inception (has source ms-1)
    final availableChip = find.widgetWithText(ChoiceChip, 'Available');
    await tester.ensureVisible(availableChip);
    await tester.pumpAndSettle();
    await tester.tap(availableChip);
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
    expect(find.text('Interstellar'), findsNothing);
    expect(find.text('Tenet'), findsNothing);

    // Filter: UNAVAILABLE -> Interstellar, Tenet
    final unavailableChip = find.widgetWithText(ChoiceChip, 'Unavailable');
    await tester.ensureVisible(unavailableChip);
    await tester.pumpAndSettle();
    await tester.tap(unavailableChip);
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsNothing);
    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('Tenet'), findsOneWidget);

    // Reset back to ALL
    final allChip = find.widgetWithText(ChoiceChip, 'All');
    await tester.ensureVisible(allChip);
    await tester.pumpAndSettle();
    await tester.tap(allChip);
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('Tenet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('MoviesScreen sorting controls update query and sort order', (
    tester,
  ) async {
    await seedMovies();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: MoviesScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    // Verify sort button is present
    expect(find.byIcon(Icons.sort_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    // Toggle direction to DESC -> Tenet, Interstellar, Inception
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

    // Open Sort Menu
    await tester.tap(find.byIcon(Icons.sort_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Release Year'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('Date Added'), findsOneWidget);

    // Select Release Year
    await tester.tap(find.text('Release Year'));
    await tester.pumpAndSettle();

    // Verify items still render properly
    expect(find.text('Tenet'), findsOneWidget);
    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('Inception'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('MoviesScreen empty filter state allows clearing filter', (
    tester,
  ) async {
    await seedMovies();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: MoviesScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    // Delete favorite movie to make favorites empty
    await repository.toggleMovieFavorite('m-1', false);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('No movies matching this filter.'), findsOneWidget);
    expect(find.text('Show All Movies'), findsOneWidget);

    // Tap Show All Movies
    await tester.tap(find.text('Show All Movies'));
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsOneWidget);
    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.text('Tenet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'MoviesScreen does not overflow on narrow mobile screen (360px)',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await seedMovies();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: MoviesScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Inception'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'MoviesScreen contextual search filters titles and shows single clear X',
    (tester) async {
      await seedMovies();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: MoviesScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Open search
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Enter query 'Inception'
      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify single clear X button exists (not duplicate)
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      expect(
        find.widgetWithText(CinemaPosterCard, 'Inception'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CinemaPosterCard, 'Interstellar'),
        findsNothing,
      );
      expect(find.widgetWithText(CinemaPosterCard, 'Tenet'), findsNothing);

      // Tap clear button -> clears query
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear_rounded), findsNothing);
      expect(
        find.widgetWithText(CinemaPosterCard, 'Inception'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CinemaPosterCard, 'Interstellar'),
        findsOneWidget,
      );
      expect(find.widgetWithText(CinemaPosterCard, 'Tenet'), findsOneWidget);

      // Tap back arrow -> closes search
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
