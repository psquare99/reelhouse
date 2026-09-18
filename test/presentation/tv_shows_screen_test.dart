import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/presentation/tv_shows/tv_shows_screen.dart';

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

  Future<void> seedTvShows() async {
    final t1 = DateTime(2026, 1, 1, 10, 0);
    final t2 = DateTime(2026, 1, 2, 10, 0);
    final t3 = DateTime(2026, 1, 3, 10, 0);

    // 1. Breaking Bad (Favorite, Watched)
    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'tv-1',
            detectedTitle: 'Breaking Bad',
            title: const drift.Value('Breaking Bad'),
            rating: const drift.Value(9.5),
            isFavorite: const drift.Value(true),
            isWatchlist: const drift.Value(false),
            createdAt: t1,
            updatedAt: t1,
          ),
        );
    await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(id: 's-1', showId: 'tv-1', seasonNumber: 1),
        );
    await db
        .into(db.episodes)
        .insert(
          EpisodesCompanion.insert(
            id: 'ep-1',
            seasonId: 's-1',
            episodeNumber: 1,
            watchState: const drift.Value('WATCHED'),
          ),
        );

    // 2. Better Call Saul (Watchlist, In Progress)
    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'tv-2',
            detectedTitle: 'Better Call Saul',
            title: const drift.Value('Better Call Saul'),
            rating: const drift.Value(9.0),
            isFavorite: const drift.Value(false),
            isWatchlist: const drift.Value(true),
            createdAt: t2,
            updatedAt: t2,
          ),
        );
    await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(id: 's-2', showId: 'tv-2', seasonNumber: 1),
        );
    await db
        .into(db.episodes)
        .insert(
          EpisodesCompanion.insert(
            id: 'ep-2a',
            seasonId: 's-2',
            episodeNumber: 1,
            watchState: const drift.Value('WATCHED'),
          ),
        );
    await db
        .into(db.episodes)
        .insert(
          EpisodesCompanion.insert(
            id: 'ep-2b',
            seasonId: 's-2',
            episodeNumber: 2,
            watchState: const drift.Value('UNWATCHED'),
          ),
        );

    // 3. Severance (Unwatched)
    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'tv-3',
            detectedTitle: 'Severance',
            title: const drift.Value('Severance'),
            rating: const drift.Value(8.7),
            isFavorite: const drift.Value(false),
            isWatchlist: const drift.Value(false),
            createdAt: t3,
            updatedAt: t3,
          ),
        );
    await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(id: 's-3', showId: 'tv-3', seasonNumber: 1),
        );
    await db
        .into(db.episodes)
        .insert(
          EpisodesCompanion.insert(
            id: 'ep-3',
            seasonId: 's-3',
            episodeNumber: 1,
            watchState: const drift.Value('UNWATCHED'),
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
            id: 'ms-ep-1',
            episodeId: const drift.Value('ep-1'),
            storageId: 'disk-main',
            relativePath: 'BreakingBad_S01E01.mkv',
            filename: 'BreakingBad_S01E01.mkv',
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

  testWidgets('TvShowsScreen renders empty state when library has no shows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: TvShowsScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No TV shows discovered yet.'), findsOneWidget);
    expect(find.byIcon(Icons.tv_outlined), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'TvShowsScreen renders catalogue and applies repository filters',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await seedTvShows();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: TvShowsScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      // Default: ALL (Title ASC) -> Better Call Saul, Breaking Bad, Severance
      expect(find.text('Better Call Saul'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);

      // Filter: FAVORITES -> only Breaking Bad
      final favChip = find.widgetWithText(ChoiceChip, 'Favorites');
      await tester.ensureVisible(favChip);
      await tester.pumpAndSettle();
      await tester.tap(favChip);
      await tester.pumpAndSettle();

      expect(find.text('Breaking Bad'), findsOneWidget);
      expect(find.text('Better Call Saul'), findsNothing);
      expect(find.text('Severance'), findsNothing);

      // Filter: WATCHLIST -> only Better Call Saul
      final watchChip = find.widgetWithText(ChoiceChip, 'Watchlist');
      await tester.ensureVisible(watchChip);
      await tester.pumpAndSettle();
      await tester.tap(watchChip);
      await tester.pumpAndSettle();

      expect(find.text('Breaking Bad'), findsNothing);
      expect(find.text('Better Call Saul'), findsOneWidget);
      expect(find.text('Severance'), findsNothing);

      // Filter: IN PROGRESS -> only Better Call Saul
      final inProgressChip = find.widgetWithText(ChoiceChip, 'In Progress');
      await tester.ensureVisible(inProgressChip);
      await tester.pumpAndSettle();
      await tester.tap(inProgressChip);
      await tester.pumpAndSettle();

      expect(find.text('Better Call Saul'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsNothing);
      expect(find.text('Severance'), findsNothing);

      // Filter: UNWATCHED -> only Severance
      final unwatchedChip = find.widgetWithText(ChoiceChip, 'Unwatched');
      await tester.ensureVisible(unwatchedChip);
      await tester.pumpAndSettle();
      await tester.tap(unwatchedChip);
      await tester.pumpAndSettle();

      expect(find.text('Severance'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsNothing);
      expect(find.text('Better Call Saul'), findsNothing);

      // Filter: AVAILABLE -> only Breaking Bad (ep-1 has source ms-ep-1)
      final availableChip = find.widgetWithText(ChoiceChip, 'Available');
      await tester.ensureVisible(availableChip);
      await tester.pumpAndSettle();
      await tester.tap(availableChip);
      await tester.pumpAndSettle();

      expect(find.text('Breaking Bad'), findsOneWidget);
      expect(find.text('Better Call Saul'), findsNothing);
      expect(find.text('Severance'), findsNothing);

      // Filter: UNAVAILABLE -> Better Call Saul, Severance
      final unavailableChip = find.widgetWithText(ChoiceChip, 'Unavailable');
      await tester.ensureVisible(unavailableChip);
      await tester.pumpAndSettle();
      await tester.tap(unavailableChip);
      await tester.pumpAndSettle();

      expect(find.text('Breaking Bad'), findsNothing);
      expect(find.text('Better Call Saul'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);

      // Reset back to ALL
      final allChip = find.widgetWithText(ChoiceChip, 'All');
      await tester.ensureVisible(allChip);
      await tester.pumpAndSettle();
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('Better Call Saul'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('TvShowsScreen sorting controls update query and sort order', (
    tester,
  ) async {
    await seedTvShows();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: TvShowsScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    // Verify sort button is present
    expect(find.byIcon(Icons.sort_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    // Toggle direction to DESC
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

    // Open Sort Menu
    await tester.tap(find.byIcon(Icons.sort_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('First Air Date'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('Date Added'), findsOneWidget);

    // Select Rating
    await tester.tap(find.text('Rating'));
    await tester.pumpAndSettle();

    // Verify items still render properly
    expect(find.text('Breaking Bad'), findsOneWidget);
    expect(find.text('Better Call Saul'), findsOneWidget);
    expect(find.text('Severance'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'TvShowsScreen does not overflow on narrow mobile screen (360px)',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await seedTvShows();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: TvShowsScreen(repository: repository, database: db),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Breaking Bad'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('TvShowsScreen empty filter state allows clearing filter', (
    tester,
  ) async {
    await seedTvShows();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: TvShowsScreen(repository: repository, database: db),
      ),
    );

    await tester.pumpAndSettle();

    // Toggle favorite off to make favorites empty
    await repository.toggleTvShowFavorite('tv-1', false);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('No TV shows matching this filter.'), findsOneWidget);
    expect(find.text('Show All TV Shows'), findsOneWidget);

    // Tap Show All TV Shows
    await tester.tap(find.text('Show All TV Shows'));
    await tester.pumpAndSettle();

    expect(find.text('Better Call Saul'), findsOneWidget);
    expect(find.text('Breaking Bad'), findsOneWidget);
    expect(find.text('Severance'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
