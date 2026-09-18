import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/presentation/search/search_screen.dart';
import 'package:reelhouse/presentation/tv_shows/tv_show_detail_screen.dart';

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

  Future<void> seedSearchLibrary() async {
    final now = DateTime.now();

    // 1. Movie with specific overview
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-blade-runner',
            detectedTitle: 'Blade Runner 2049',
            title: const drift.Value('Blade Runner 2049'),
            year: const drift.Value(2017),
            overview: const drift.Value(
              'A young blade runner unearths a secret.',
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // 2. Movie with overview matching keyword 'replicant' and title 'Original Cut'
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-original-br',
            detectedTitle: 'Blade Runner Original Cut',
            title: const drift.Value('Blade Runner Original Cut'),
            year: const drift.Value(1982),
            overview: const drift.Value(
              'A blade runner must pursue replicants.',
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // 3. TV Show
    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'tv-westworld',
            detectedTitle: 'Westworld',
            title: const drift.Value('Westworld'),
            overview: const drift.Value(
              'A theme park populated by android hosts.',
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(
            id: 's-westworld-1',
            showId: 'tv-westworld',
            seasonNumber: 1,
          ),
        );
    await db
        .into(db.episodes)
        .insert(
          EpisodesCompanion.insert(
            id: 'ep-ww-1',
            seasonId: 's-westworld-1',
            episodeNumber: 1,
            name: const drift.Value('The Original'),
            overview: const drift.Value('Dolores begins to remember.'),
          ),
        );
  }

  testWidgets('SearchScreen searches with debounce (~300ms)', (tester) async {
    await seedSearchLibrary();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: SearchScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fast Local Cinema Search'), findsOneWidget);

    // Enter search query
    final searchInput = find.byType(TextField);
    await tester.enterText(searchInput, 'Blade');
    await tester.pump(const Duration(milliseconds: 100));

    // After 100ms, debounce should not have fired yet
    expect(find.text('MOVIES (2)'), findsNothing);

    // After 300ms total, search runs
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('MOVIES (2)'), findsOneWidget);
    expect(find.text('Blade Runner 2049'), findsOneWidget);
    expect(find.text('Blade Runner Original Cut'), findsOneWidget);

    // Clear search
    final clearButton = find.byIcon(Icons.clear);
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('Fast Local Cinema Search'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('SearchMode selector filters between Title and All Fields', (
    tester,
  ) async {
    await seedSearchLibrary();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: SearchScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    final searchInput = find.byType(TextField);

    // Search keyword that only appears in overview: 'replicants'
    await tester.enterText(searchInput, 'replicants');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // In Title mode (default), 'replicants' is not in title -> no results
    expect(find.text('Blade Runner Original Cut'), findsNothing);
    expect(find.text('No matches for "replicants"'), findsOneWidget);

    // Switch SearchMode to All Fields
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('All Fields'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);

    await tester.tap(find.text('All Fields'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // In All Fields mode, finds Blade Runner Original Cut because 'replicants' is in overview
    expect(find.text('Blade Runner Original Cut'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('SearchResultTypeFilter tabs filter results properly', (
    tester,
  ) async {
    await seedSearchLibrary();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: SearchScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    final searchInput = find.byType(TextField);
    // Search 'Original' which matches 1 movie (detected/title) and 1 episode name ('The Original')
    await tester.enterText(searchInput, 'Original');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('MOVIES (1)'), findsOneWidget);
    expect(find.text('EPISODES (1)'), findsOneWidget);

    // Switch to Movies tab
    await tester.tap(find.widgetWithText(ChoiceChip, 'Movies (1)'));
    await tester.pumpAndSettle();

    expect(find.text('MOVIES (1)'), findsOneWidget);
    expect(find.text('EPISODES (1)'), findsNothing);

    // Switch to Episodes tab
    await tester.tap(find.widgetWithText(ChoiceChip, 'Episodes (1)'));
    await tester.pumpAndSettle();

    expect(find.text('MOVIES (1)'), findsNothing);
    expect(find.text('EPISODES (1)'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'The Original'), findsOneWidget);

    // Switch to TV Shows tab (empty for 'Original')
    await tester.tap(find.widgetWithText(ChoiceChip, 'TV Shows (0)'));
    await tester.pumpAndSettle();

    expect(find.text('No matches for "Original" in TV Shows'), findsOneWidget);
    expect(find.text('Show All Results'), findsOneWidget);

    // Tap Show All Results
    await tester.tap(find.text('Show All Results'));
    await tester.pumpAndSettle();

    expect(find.text('MOVIES (1)'), findsOneWidget);
    expect(find.text('EPISODES (1)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Episode search result tap navigates to TvShowDetailScreen', (
    tester,
  ) async {
    await seedSearchLibrary();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: SearchScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    final searchInput = find.byType(TextField);
    await tester.enterText(searchInput, 'The Original');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    final episodeTile = find.widgetWithText(ListTile, 'The Original');
    expect(episodeTile, findsOneWidget);

    // Tap episode ListTile
    await tester.tap(episodeTile);
    await tester.pumpAndSettle();

    // Verify TvShowDetailScreen is pushed for 'tv-westworld'
    expect(find.byType(TvShowDetailScreen), findsOneWidget);
    expect(find.text('Westworld'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('SearchScreen adapts properly on narrow mobile screen (360px)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await seedSearchLibrary();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: SearchScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    final searchInput = find.byType(TextField);
    await tester.enterText(searchInput, 'Blade');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Blade Runner 2049'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
