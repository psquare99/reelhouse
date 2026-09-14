import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/presentation/tv_shows/tv_show_detail_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'TvShowDetailScreen renders seasons, episodes, and availability',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();

      // 1. Add storage
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'hdd-series',
              name: 'Series HDD',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'VOL-SERIES',
              rootUri: r'D:\Series',
              lastSeenAt: now,
              available: const drift.Value(true),
            ),
          );

      // 2. Add TV Show
      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'show-severance',
              title: 'Severance',
              overview: const drift.Value(
                'Mark leads a team of office workers whose memories have been surgically divided.',
              ),
              firstAirDate: drift.Value(DateTime(2022, 2, 18)),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 3. Add Season
      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 'season-sev-1',
              showId: 'show-severance',
              seasonNumber: 1,
              name: const drift.Value('Season 1'),
            ),
          );

      // 4. Add Episode
      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-sev-s1e1',
              seasonId: 'season-sev-1',
              episodeNumber: 1,
              name: const drift.Value('Good News About Hell'),
              overview: const drift.Value(
                'Mark Scout leads a team at Lumon Industries.',
              ),
              runtime: const drift.Value(57),
            ),
          );

      // 5. Add Media Source for Episode
      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'src-sev-s1e1',
              episodeId: const drift.Value('ep-sev-s1e1'),
              storageId: 'hdd-series',
              sourceType: 'removableStorage',
              relativePath: 'Severance/Season 1/S01E01.mkv',
              filename: 'S01E01.mkv',
              extension: 'mkv',
              fileSize: BigInt.from(2500000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: TvShowDetailScreen(showId: 'show-severance', database: db),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Show Title & Season
      expect(find.text('Severance'), findsOneWidget);
      expect(find.text('1 Season'), findsOneWidget); // Badge
      expect(find.text('Season 1'), findsOneWidget); // Choice chip
      expect(find.text('Good News About Hell'), findsOneWidget);
      expect(find.text('Episode 1'), findsOneWidget);

      // Verify Play button for episode
      expect(find.text('PLAY'), findsOneWidget);
      expect(find.text('DOWNLOAD'), findsOneWidget);

      // Test Episode watched toggle
      final watchToggle = find.byIcon(Icons.check_circle_outline);
      expect(watchToggle, findsOneWidget);
      await tester.tap(watchToggle);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      final ep = await (db.select(
        db.episodes,
      )..where((e) => e.id.equals('ep-sev-s1e1'))).getSingle();
      expect(ep.watchState, 'WATCHED');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
