import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/presentation/home/home_screen.dart';
import 'package:reelhouse/presentation/movies/movie_detail_screen.dart';
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

  Future<void> seedTestData() async {
    final now = DateTime.now();

    // 1. Seed Storage
    await db
        .into(db.storages)
        .insertOnConflictUpdate(
          StoragesCompanion.insert(
            id: 'disk-test',
            name: 'Primary Vault',
            storageType: 'EXTERNAL_DRIVE',
            filesystemIdentifier: 'fs-test',
            rootUri: '/media/vault',
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    // 2. Seed Movies (one in-progress, one watched, one recent)
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-1',
            detectedTitle: 'Oppenheimer',
            title: const drift.Value('Oppenheimer'),
            year: const drift.Value(2023),
            watchState: const drift.Value('IN_PROGRESS'),
            playbackPositionSeconds: const drift.Value(3600),
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now,
          ),
        );

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-2',
            detectedTitle: 'Dune Part Two',
            title: const drift.Value('Dune: Part Two'),
            year: const drift.Value(2024),
            isFavorite: const drift.Value(true),
            watchState: const drift.Value('WATCHED'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // 3. Seed TV Show
    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'show-1',
            detectedTitle: 'Severance',
            title: const drift.Value('Severance'),
            firstAirDate: drift.Value(DateTime(2022, 2, 18)),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // 4. Seed Season
    await db
        .into(db.seasons)
        .insert(
          SeasonsCompanion.insert(
            id: 'season-1',
            showId: 'show-1',
            seasonNumber: 1,
            name: const drift.Value('Season 1'),
          ),
        );

    // 5. Seed Episode (in-progress)
    await db
        .into(db.episodes)
        .insert(
          EpisodesCompanion.insert(
            id: 'ep-1',
            seasonId: 'season-1',
            episodeNumber: 1,
            name: const drift.Value('Good News About Hell'),
            watchState: const drift.Value('IN_PROGRESS'),
            playbackPositionSeconds: const drift.Value(1200),
          ),
        );
  }

  testWidgets('HomeScreen renders header, banners, and empty state cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: HomeScreen(
          repository: repository,
          database: db,
          onNavigateToMovies: () {},
          onNavigateToTv: () {},
          onNavigateToOffline: () {},
          onNavigateToSettings: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('REELHOUSE'), findsOneWidget);
    expect(find.text('Personal Digital Cinema'), findsOneWidget);
    expect(find.text('Cinema Status'), findsOneWidget);
    expect(find.text('EXPLORE CINEMA'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('TV Shows'), findsOneWidget);
    expect(find.text('Offline Library'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'HomeScreen renders Movie and TV Continue Watching and Recently Added sections',
    (tester) async {
      await seedTestData();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: HomeScreen(
            repository: repository,
            database: db,
            onNavigateToMovies: () {},
            onNavigateToTv: () {},
            onNavigateToOffline: () {},
            onNavigateToSettings: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Movie Continue Watching section
      expect(find.text('CONTINUE WATCHING'), findsOneWidget);
      expect(find.text('Oppenheimer'), findsWidgets);

      // 2. TV Continue Watching section
      expect(find.text('TV CONTINUE WATCHING'), findsOneWidget);
      expect(find.text('Good News About Hell'), findsOneWidget);
      expect(find.text('S01E01'), findsOneWidget);

      // 3. Movie Recently Added section
      expect(find.text('RECENTLY ADDED'), findsOneWidget);

      // 4. TV Recently Added section
      expect(find.text('TV RECENTLY ADDED'), findsOneWidget);
      expect(find.text('Severance'), findsWidgets);

      // 5. Favorites section
      expect(find.text('FAVORITES'), findsOneWidget);
      expect(find.text('Dune: Part Two'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('HomeScreen movie card tap navigates to MovieDetailScreen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await seedTestData();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: HomeScreen(
          repository: repository,
          database: db,
          onNavigateToMovies: () {},
          onNavigateToTv: () {},
          onNavigateToOffline: () {},
          onNavigateToSettings: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the Oppenheimer movie card
    final oppenheimerCard = find.text('Oppenheimer').first;
    await tester.ensureVisible(oppenheimerCard);
    await tester.pumpAndSettle();
    await tester.tap(oppenheimerCard);
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'HomeScreen TV episode card tap navigates to TvShowDetailScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await seedTestData();

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: HomeScreen(
            repository: repository,
            database: db,
            onNavigateToMovies: () {},
            onNavigateToTv: () {},
            onNavigateToOffline: () {},
            onNavigateToSettings: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the episode card in TV Continue Watching
      final episodeCard = find.text('Good News About Hell');
      await tester.ensureVisible(episodeCard);
      await tester.pumpAndSettle();
      await tester.tap(episodeCard);
      await tester.pumpAndSettle();

      expect(find.byType(TvShowDetailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('HomeScreen TV show card tap navigates to TvShowDetailScreen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await seedTestData();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: HomeScreen(
          repository: repository,
          database: db,
          onNavigateToMovies: () {},
          onNavigateToTv: () {},
          onNavigateToOffline: () {},
          onNavigateToSettings: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Severance card in TV Recently Added
    final severanceCard = find.text('Severance').first;
    await tester.ensureVisible(severanceCard);
    await tester.pumpAndSettle();
    await tester.tap(severanceCard);
    await tester.pumpAndSettle();

    expect(find.byType(TvShowDetailScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('HomeScreen renders on narrow 360px viewport without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await seedTestData();

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: HomeScreen(
          repository: repository,
          database: db,
          onNavigateToMovies: () {},
          onNavigateToTv: () {},
          onNavigateToOffline: () {},
          onNavigateToSettings: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('REELHOUSE'), findsOneWidget);
    expect(find.text('Severance'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
