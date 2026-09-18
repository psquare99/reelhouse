import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/platform/platform_storage_adapter.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/domain/services/playback_launcher_service.dart';
import 'package:reelhouse/presentation/home/home_screen.dart';
import 'package:reelhouse/presentation/movies/movie_detail_screen.dart';
import 'package:reelhouse/presentation/tv_shows/tv_show_detail_screen.dart';
import 'package:reelhouse/presentation/widgets/cinema_poster_card.dart';

class _FakeStorageAdapter implements PlatformStorageAdapter {
  final bool connected;
  final bool filePresent;

  const _FakeStorageAdapter({this.connected = true, this.filePresent = true});

  @override
  Future<bool> isStorageConnected(String rootUri) async => connected;

  @override
  Future<String> resolvePlaybackUri(
    String rootUri,
    String relativePath,
  ) async => '$rootUri\\$relativePath';

  @override
  Future<bool> fileExists(String rootUri, String relativePath) async =>
      filePresent;

  @override
  Future<String?> getFilesystemIdentifier(String rootUri) async => null;

  @override
  Future<String> getStorageDisplayName(String rootUri) async => 'Fake Storage';

  @override
  Future<int> getAvailableBytes(String rootUri) async => 0;

  @override
  Future<int> getFileSizeBytes(String rootUri, String relativePath) async => 0;
}

class _FakeProcess implements Process {
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;

  @override
  int get pid => 12345;

  @override
  Future<int> get exitCode => Future.value(0);

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  Stream<List<int>> get stdout => const Stream.empty();

  @override
  IOSink get stdin => throw UnimplementedError();
}

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

    // 6. Seed Media Sources
    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'source-m1',
            storageId: 'disk-test',
            movieId: const drift.Value('m-1'),
            relativePath: 'Oppenheimer.2023.mkv',
            filename: 'Oppenheimer.2023',
            extension: 'mkv',
            fileSize: BigInt.from(1000000),
            sourceType: 'removableStorage',
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
          ),
        );

    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'source-m2',
            storageId: 'disk-test',
            movieId: const drift.Value('m-2'),
            relativePath: 'Dune.Part.Two.2024.mkv',
            filename: 'Dune.Part.Two.2024',
            extension: 'mkv',
            fileSize: BigInt.from(1000000),
            sourceType: 'removableStorage',
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
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
    expect(find.text('EXPLORE CINEMA'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('TV Shows'), findsOneWidget);
    expect(find.text('Offline Library'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'HomeScreen renders Featured Screening Hero, Recently Added, and excludes separate Continue Watching or Resume sections',
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

      // 1. Separate Continue Watching & Resume Watching sections must NOT be present
      expect(find.text('CONTINUE WATCHING'), findsNothing);
      expect(find.text('TV CONTINUE WATCHING'), findsNothing);
      expect(find.text('RESUME WATCHING'), findsNothing);
      expect(find.text('Resume'), findsNothing);

      // 2. Hero provides Featured Screening with Play semantics
      expect(find.text('FEATURED SCREENING'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Dune: Part Two'), findsWidgets);

      // 3. Movie Recently Added section
      expect(find.text('RECENTLY ADDED'), findsOneWidget);

      // 4. TV Recently Added section
      expect(find.text('TV RECENTLY ADDED'), findsOneWidget);
      expect(find.text('Severance'), findsWidgets);

      // 5. Favorites section
      expect(find.text('FAVORITES'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeScreen movie card tap in Recently Added navigates to MovieDetailScreen',
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

      // Tap the Dune movie card
      final duneCard = find.text('Dune: Part Two').first;
      await tester.ensureVisible(duneCard);
      await tester.pumpAndSettle();
      await tester.tap(duneCard);
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeScreen Hero Play action directly launches playback with Play semantics',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await seedTestData();

      List<String>? launchedArgs;
      final launcher = PlaybackLauncherService(
        database: db,
        storageAdapter: const _FakeStorageAdapter(
          connected: true,
          filePresent: true,
        ),
        processStarter: (exec, args, {mode = ProcessStartMode.normal}) async {
          launchedArgs = args;
          return _FakeProcess();
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: HomeScreen(
            repository: repository,
            database: db,
            playbackLauncher: launcher,
            onNavigateToMovies: () {},
            onNavigateToTv: () {},
            onNavigateToOffline: () {},
            onNavigateToSettings: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Play button in Hero
      final playBtn = find.text('Play');
      expect(playBtn, findsOneWidget);
      await tester.tap(playBtn);
      await tester.pumpAndSettle();

      // Verify that playback was launched without start-time
      expect(launchedArgs, isNotNull);
      expect(
        launchedArgs!.any((arg) => arg.startsWith('--start-time=')),
        isFalse,
      );
      // Verify it did not navigate away
      expect(find.byType(MovieDetailScreen), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeScreen Hero View Details action tap navigates to MovieDetailScreen',
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

      // Tap View Details button in Hero
      final detailsBtn = find.text('View Details');
      expect(detailsBtn, findsOneWidget);
      await tester.tap(detailsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(MovieDetailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeScreen Hero does not select in-progress episode or movie as a Resume Hero',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await seedTestData();

      final now = DateTime.now();
      // Make episode in-progress and played recently
      await (db.update(db.episodes)..where((e) => e.id.equals('ep-1'))).write(
        EpisodesCompanion(
          watchState: const drift.Value('IN_PROGRESS'),
          lastPlayedAt: drift.Value(now),
        ),
      );

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

      // Hero remains FEATURED SCREENING (not Resume Watching)
      expect(find.text('FEATURED SCREENING'), findsOneWidget);
      expect(find.text('RESUME WATCHING'), findsNothing);
      expect(find.text('Resume'), findsNothing);
      expect(find.text('Play'), findsOneWidget);

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

    expect(find.text('REELHOUSE'), findsOneWidget);
    expect(find.text('Severance'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'HomeScreen global search searches Movies, TV Shows, and Episodes in Title mode with single clear X',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
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

      final searchInput = find.byType(TextField);
      expect(searchInput, findsOneWidget);

      // Initial state: Title mode default indicator
      expect(find.text('Title'), findsOneWidget);

      // Search 'Oppenheimer'
      await tester.enterText(searchInput, 'Oppenheimer');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify single clear X button
      final clearButtons = find.byTooltip('Clear search');
      expect(clearButtons, findsOneWidget);

      // Verify results show Movies section
      expect(find.text('MOVIES (1)'), findsOneWidget);
      expect(
        find.widgetWithText(CinemaPosterCard, 'Oppenheimer'),
        findsOneWidget,
      );

      // Search 'Severance' (matches TV show)
      await tester.enterText(searchInput, 'Severance');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('TV SHOWS (1)'), findsOneWidget);
      expect(
        find.widgetWithText(CinemaPosterCard, 'Severance'),
        findsOneWidget,
      );

      // Clear search with single clear X
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('RECENTLY ADDED'), findsOneWidget);
      expect(find.text('CONTINUE WATCHING'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeScreen displays quiet cinema footer and no technical storage copy',
    (tester) async {
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

      // Quiet cinema closing element
      expect(
        find.text('Your cinema. Your collection. Your stories.'),
        findsOneWidget,
      );

      // Old technical storage text removed
      expect(find.text('Your personal cinema is permanent.'), findsNothing);
      expect(
        find.text(
          'Disks are sources. Disconnecting a drive never erases your library.\nCopies on this device remain ready to watch offline.',
        ),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeScreen discovery rows use non-scrollable responsive rows without horizontal scrollables',
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

      // Ensure that there are NO horizontal ListViews or SingleChildScrollView discovery rows in the home screen
      final horizontalListScrollables = find.byWidgetPredicate((widget) {
        if (widget is ListView && widget.scrollDirection == Axis.horizontal) {
          return true;
        }
        if (widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal) {
          return true;
        }
        return false;
      });
      expect(horizontalListScrollables, findsNothing);

      // Verify no "View All" button exists on Recently Added
      expect(find.text('View All'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeScreen renders RECENTLY PLAYED section with "Your latest screenings" when items have lastPlayedAt',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await seedTestData();

      // Seed a movie and episode with lastPlayedAt
      final now = DateTime.now();
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-played',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              year: const drift.Value(2010),
              watchState: const drift.Value('WATCHED'),
              lastPlayedAt: drift.Value(now),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Update ep-1 with lastPlayedAt
      await (db.update(db.episodes)..where((e) => e.id.equals('ep-1'))).write(
        EpisodesCompanion(
          lastPlayedAt: drift.Value(now.subtract(const Duration(minutes: 5))),
        ),
      );

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

      expect(find.text('RECENTLY PLAYED'), findsOneWidget);
      expect(find.text('Your latest screenings'), findsOneWidget);
      expect(find.text('Inception'), findsWidgets);
      expect(find.text('Good News About Hell'), findsWidgets);

      // Tap episode card in Recently Played to verify navigation
      final epCard = find.widgetWithText(
        CinemaPosterCard,
        'Good News About Hell',
      );
      await tester.ensureVisible(epCard);
      await tester.pumpAndSettle();
      await tester.tap(epCard);
      await tester.pumpAndSettle();

      expect(find.byType(TvShowDetailScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'HomeScreen omits RECENTLY PLAYED section when no playback history exists',
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

      expect(find.text('RECENTLY PLAYED'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
