import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/services/library_backup_service_impl.dart';
import 'package:reelhouse/domain/models/library_backup_models.dart';
import 'package:reelhouse/domain/services/settings_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late String settingsPath;
  late SettingsService settingsService;
  late LibraryBackupServiceImpl backupService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('reelhouse_backup_test_');
    settingsPath = '${tempDir.path}/settings.json';
    settingsService = SettingsService(settingsFilePath: settingsPath);
    await settingsService.setTmdbApiKey('tmdb_super_secret_key_12345');
    await settingsService.setPreferredPlayer('vlc');

    backupService = LibraryBackupServiceImpl(
      database: db,
      settingsService: settingsService,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RC.1 Export Library & Format Validation', () {
    test('1. Export creates a valid versioned payload envelope', () async {
      final payload = await backupService.createBackupPayload();

      expect(payload.formatVersion, equals(kCurrentBackupFormatVersion));
      expect(payload.appVersion, equals(kCurrentBackupAppVersion));
      expect(payload.schemaVersion, equals(db.schemaVersion));
      expect(payload.application, equals('REELHOUSE'));
      expect(payload.exportedAt, isNotNull);

      final json = payload.toJson();
      expect(json['formatVersion'], equals(1));
      expect(json['library'], isA<Map<String, dynamic>>());
      expect(json['summary'], isA<Map<String, dynamic>>());
    });

    test(
      '2. Export contains expected logical movie and TV show library data',
      () async {
        final now = DateTime.now();

        // Seed Movie
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-inception',
                detectedTitle: 'Inception',
                title: const drift.Value('Inception'),
                originalTitle: const drift.Value('Inception'),
                year: const drift.Value(2010),
                detectedYear: const drift.Value(2010),
                identificationStatus: const drift.Value('IDENTIFIED'),
                overview: const drift.Value(
                  'A thief who steals corporate secrets...',
                ),
                runtime: const drift.Value(148),
                rating: const drift.Value(8.8),
                tmdbId: const drift.Value(27205),
                genres: const drift.Value('Action, Sci-Fi'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Seed TV Show, Season, and Episode
        await db
            .into(db.tvShows)
            .insert(
              TvShowsCompanion.insert(
                id: 'tv-breaking-bad',
                detectedTitle: 'Breaking Bad',
                title: const drift.Value('Breaking Bad'),
                identificationStatus: const drift.Value('IDENTIFIED'),
                tmdbId: const drift.Value(1396),
                genres: const drift.Value('Drama, Crime'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        await db
            .into(db.seasons)
            .insert(
              SeasonsCompanion.insert(
                id: 's-bb-1',
                showId: 'tv-breaking-bad',
                seasonNumber: 1,
                name: const drift.Value('Season 1'),
                tmdbId: const drift.Value(3572),
              ),
            );

        await db
            .into(db.episodes)
            .insert(
              EpisodesCompanion.insert(
                id: 'ep-bb-1-1',
                seasonId: 's-bb-1',
                episodeNumber: 1,
                name: const drift.Value('Pilot'),
                overview: const drift.Value(
                  'A high school chemistry teacher...',
                ),
                tmdbId: const drift.Value(62085),
                runtime: const drift.Value(58),
              ),
            );

        final payload = await backupService.createBackupPayload();

        expect(payload.movies.length, equals(1));
        expect(payload.movies.first.id, equals('m-inception'));
        expect(payload.movies.first.title, equals('Inception'));
        expect(payload.movies.first.tmdbId, equals(27205));

        expect(payload.tvShows.length, equals(1));
        expect(payload.tvShows.first.id, equals('tv-breaking-bad'));
        expect(payload.tvShows.first.seasons.length, equals(1));
        expect(payload.tvShows.first.seasons.first.episodes.length, equals(1));
        expect(
          payload.tvShows.first.seasons.first.episodes.first.name,
          equals('Pilot'),
        );
      },
    );

    test(
      '3. Export contains custom curated collections and collection items',
      () async {
        final now = DateTime.now();
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-dune-1',
                detectedTitle: 'Dune',
                title: const drift.Value('Dune: Part One'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        await db
            .into(db.collections)
            .insert(
              CollectionsCompanion.insert(
                id: 'col-sci-fi-masterpieces',
                name: 'Sci-Fi Masterpieces',
                overview: const drift.Value('Greatest science fiction cinema'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        await db
            .into(db.collectionItems)
            .insert(
              CollectionItemsCompanion.insert(
                id: 'ci-1',
                collectionId: 'col-sci-fi-masterpieces',
                movieId: const drift.Value('m-dune-1'),
                displayOrder: const drift.Value(1),
                addedAt: now,
              ),
            );

        final payload = await backupService.createBackupPayload();

        expect(payload.collections.length, equals(1));
        expect(payload.collections.first.id, equals('col-sci-fi-masterpieces'));
        expect(payload.collections.first.name, equals('Sci-Fi Masterpieces'));
        expect(payload.collections.first.items.length, equals(1));
        expect(
          payload.collections.first.items.first.movieId,
          equals('m-dune-1'),
        );
      },
    );

    test('4 & 5. Export preserves watch state and playback history', () async {
      final now = DateTime.now();
      final lastPlayed = DateTime.fromMillisecondsSinceEpoch(
        (now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch ~/
                1000) *
            1000,
      );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-matrix',
              detectedTitle: 'The Matrix',
              title: const drift.Value('The Matrix'),
              watchState: const drift.Value('IN_PROGRESS'),
              playbackPositionSeconds: const drift.Value(3450),
              lastPlayedAt: drift.Value(lastPlayed),
              isFavorite: const drift.Value(true),
              isWatchlist: const drift.Value(false),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-show-1',
              detectedTitle: 'Show 1',
              isFavorite: const drift.Value(true),
              isWatchlist: const drift.Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 's-1',
              showId: 'tv-show-1',
              seasonNumber: 1,
            ),
          );

      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-1',
              seasonId: 's-1',
              episodeNumber: 1,
              watchState: const drift.Value('WATCHED'),
              playbackPositionSeconds: const drift.Value(0),
              lastPlayedAt: drift.Value(lastPlayed),
            ),
          );

      final payload = await backupService.createBackupPayload();

      final movie = payload.movies.first;
      expect(movie.watchState, equals('IN_PROGRESS'));
      expect(movie.playbackPositionSeconds, equals(3450));
      expect(
        movie.lastPlayedAt?.millisecondsSinceEpoch,
        equals(lastPlayed.millisecondsSinceEpoch),
      );
      expect(movie.isFavorite, isTrue);

      final ep = payload.tvShows.first.seasons.first.episodes.first;
      expect(ep.watchState, equals('WATCHED'));
      expect(
        ep.lastPlayedAt?.millisecondsSinceEpoch,
        equals(lastPlayed.millisecondsSinceEpoch),
      );
    });

    test(
      '6. CRITICAL SECURITY: Export DOES NOT contain TMDB API credentials',
      () async {
        expect(
          settingsService.tmdbApiKey,
          equals('tmdb_super_secret_key_12345'),
        );

        final payload = await backupService.createBackupPayload();
        final rawJson = payload.toPrettyJson();

        // Regression assertions
        expect(rawJson.contains('tmdb_super_secret_key_12345'), isFalse);
        expect(rawJson.contains('tmdbApiKey'), isFalse);
        expect(rawJson.contains('apiKey'), isFalse);

        if (payload.settings != null) {
          final settingsJson = payload.settings!.toJson();
          expect(settingsJson.containsKey('tmdbApiKey'), isFalse);
          expect(settingsJson.containsKey('apiKey'), isFalse);
        }
      },
    );

    test('7. Export DOES NOT include physical media files, MediaSources, or storages', () async {
      final now = DateTime.now();

      // Insert real Storage and MediaSource records
      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'storage-external-hdd',
              name: 'Seagate 4TB',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'VOL_SERIAL_98765',
              rootUri: 'D:/Movies',
              lastSeenAt: now,
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-interstellar',
              detectedTitle: 'Interstellar',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'ms-interstellar-hdd',
              movieId: const drift.Value('m-interstellar'),
              storageId: 'storage-external-hdd',
              sourceType: 'removableStorage',
              relativePath: 'SciFi/Interstellar.2014.1080p.mkv',
              filename: 'Interstellar.2014.1080p.mkv',
              extension: '.mkv',
              fileSize: BigInt.from(14 * 1024 * 1024 * 1024),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      final payload = await backupService.createBackupPayload();
      final rawJson = payload.toPrettyJson();

      // Verify no storage paths or physical MediaSource records are packaged
      expect(rawJson.contains('VOL_SERIAL_98765'), isFalse);
      expect(rawJson.contains('D:/Movies'), isFalse);
      expect(rawJson.contains('ms-interstellar-hdd'), isFalse);
      expect(rawJson.contains('mediaSources'), isFalse);
      expect(rawJson.contains('storages'), isFalse);
    });

    test('Summary inspection accurately previews metrics without loading full schema', () async {
      final now = DateTime.now();
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-1',
              detectedTitle: 'Movie 1',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-2',
              detectedTitle: 'Movie 2',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final exportPath = '${tempDir.path}/test_export.json';
      await backupService.exportBackupToFile(exportPath);

      final summary = await backupService.inspectBackupFile(exportPath);
      expect(summary.movieCount, equals(2));
      expect(summary.tvShowCount, equals(0));
      expect(summary.formatVersion, equals(1));
    });
  });
}
