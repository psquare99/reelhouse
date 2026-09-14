import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/presentation/movies/movie_detail_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('MovieDetailScreen renders metadata, actions, and YOUR COPIES', (
    tester,
  ) async {
    final now = DateTime.now();

    // 1. Add storage
    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: 'hdd-1',
            name: 'Cinema HDD',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: 'VOL-001',
            rootUri: r'D:\Cinema',
            lastSeenAt: now,
            available: const drift.Value(true),
          ),
        );

    // 2. Add movie
    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'movie-oppenheimer',
            title: 'Oppenheimer',
            originalTitle: const drift.Value('Oppenheimer'),
            year: const drift.Value(2023),
            overview: const drift.Value(
              'The story of American scientist J. Robert Oppenheimer.',
            ),
            runtime: const drift.Value(180),
            rating: const drift.Value(8.9),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // 3. Add physical source
    await db
        .into(db.mediaSources)
        .insert(
          MediaSourcesCompanion.insert(
            id: 'src-opp-hdd',
            movieId: const drift.Value('movie-oppenheimer'),
            storageId: 'hdd-1',
            sourceType: 'removableStorage',
            relativePath: 'Oppenheimer (2023)/Oppenheimer.mkv',
            filename: 'Oppenheimer.mkv',
            extension: 'mkv',
            fileSize: BigInt.from(15000000000),
            resolution: const drift.Value('4K'),
            videoCodec: const drift.Value('HEVC'),
            audioChannels: const drift.Value('5.1'),
            createdAt: now,
            firstSeenAt: now,
            lastSeenAt: now,
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: MovieDetailScreen(movieId: 'movie-oppenheimer', database: db),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Metadata
    expect(find.text('Oppenheimer'), findsOneWidget);
    expect(find.text('2023'), findsOneWidget);
    expect(find.text('3h'), findsOneWidget);
    expect(find.text('8.9'), findsOneWidget);
    expect(
      find.text('The story of American scientist J. Robert Oppenheimer.'),
      findsOneWidget,
    );

    // Verify Primary Action (PLAY button since HDD is connected)
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('DOWNLOAD TO DEVICE'), findsOneWidget);

    // Verify YOUR COPIES section
    expect(find.text('YOUR COPIES'), findsOneWidget);
    expect(find.text('Cinema HDD (Original)'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('4K'), findsOneWidget);
    expect(find.text('HEVC'), findsOneWidget);

    // Test Favorite Toggle
    final favButton = find.byIcon(Icons.favorite_border);
    expect(favButton, findsOneWidget);
    await tester.tap(favButton);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    final updatedMovie = await db.findMovieById('movie-oppenheimer');
    expect(updatedMovie!.isFavorite, true);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'MovieDetailScreen reflects disconnected storage with CONNECT DISK action',
    (tester) async {
      final now = DateTime.now();

      // Disconnected storage
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'hdd-offline',
              name: 'Cold Storage Vault',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'VOL-OFFLINE',
              rootUri: r'E:\Cold',
              lastSeenAt: now,
              available: const drift.Value(false),
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'movie-dune',
              title: 'Dune: Part Two',
              year: const drift.Value(2024),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-dune-cold',
              movieId: const drift.Value('movie-dune'),
              storageId: 'hdd-offline',
              sourceType: 'removableStorage',
              relativePath: 'Dune Part Two.mkv',
              filename: 'Dune Part Two.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(12000000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
              available: const drift.Value(false),
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: MovieDetailScreen(movieId: 'movie-dune', database: db),
        ),
      );

      await tester.pumpAndSettle();

      // Should display CONNECT COLD STORAGE VAULT instead of misleading Play button
      expect(find.text('CONNECT COLD STORAGE VAULT'), findsOneWidget);
      expect(find.text('Disconnected'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
