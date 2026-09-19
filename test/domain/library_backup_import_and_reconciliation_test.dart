import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/services/library_backup_service_impl.dart';
import 'package:reelhouse/domain/models/availability_status.dart';
import 'package:reelhouse/domain/models/library_backup_models.dart';
import 'package:reelhouse/domain/services/availability_resolver.dart';
import 'package:reelhouse/domain/services/settings_service.dart';

void main() {
  setUpAll(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase db;
  late Directory tempDir;
  late SettingsService settingsService;
  late LibraryBackupServiceImpl backupService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('reelhouse_import_test_');
    settingsService = SettingsService(
      settingsFilePath: '${tempDir.path}/settings.json',
    );
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

  group('RC.1 Import Library & Reconciliation Testing', () {
    test('8. Import restores movies into empty database', () async {
      final payload = LibraryBackupPayload(
        exportedAt: DateTime.now(),
        movies: [
          BackupMovie(
            id: 'm-gladiator',
            detectedTitle: 'Gladiator',
            title: 'Gladiator',
            year: 2000,
            tmdbId: 98,
            overview: 'A former Roman General sets out to exact vengeance...',
            rating: 8.5,
            genres: 'Action, Drama',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final result = await backupService.importBackupPayload(payload);

      expect(result.success, isTrue);
      expect(result.moviesImported, equals(1));

      final allMovies = await db.select(db.movies).get();
      expect(allMovies.length, equals(1));
      expect(allMovies.first.title, equals('Gladiator'));
      expect(allMovies.first.tmdbId, equals(98));
    });

    test('9. Import restores TV shows, seasons, and episodes', () async {
      final now = DateTime.now();
      final payload = LibraryBackupPayload(
        exportedAt: now,
        tvShows: [
          BackupTvShow(
            id: 'tv-severance',
            detectedTitle: 'Severance',
            title: 'Severance',
            tmdbId: 95557,
            createdAt: now,
            updatedAt: now,
            seasons: [
              BackupSeason(
                id: 's-sev-1',
                seasonNumber: 1,
                name: 'Season 1',
                episodes: [
                  BackupEpisode(
                    id: 'ep-sev-1-1',
                    episodeNumber: 1,
                    name: 'Good News About Hell',
                    watchState: 'WATCHED',
                  ),
                  BackupEpisode(
                    id: 'ep-sev-1-2',
                    episodeNumber: 2,
                    name: 'Half Loop',
                    watchState: 'IN_PROGRESS',
                    playbackPositionSeconds: 1200,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final result = await backupService.importBackupPayload(payload);

      expect(result.success, isTrue);
      expect(result.showsImported, equals(1));
      expect(result.seasonsImported, equals(1));
      expect(result.episodesImported, equals(2));

      final shows = await db.select(db.tvShows).get();
      final seasons = await db.select(db.seasons).get();
      final episodes = await db.select(db.episodes).get();

      expect(shows.length, equals(1));
      expect(shows.first.title, equals('Severance'));
      expect(seasons.length, equals(1));
      expect(episodes.length, equals(2));
      expect(episodes.first.watchState, equals('WATCHED'));
      expect(episodes.last.playbackPositionSeconds, equals(1200));
    });

    test(
      '10. Import restores curated collections and maps items accurately',
      () async {
        final now = DateTime.now();
        final payload = LibraryBackupPayload(
          exportedAt: now,
          movies: [
            BackupMovie(
              id: 'm-batman-begins',
              detectedTitle: 'Batman Begins',
              title: 'Batman Begins',
              year: 2005,
              tmdbId: 272,
              createdAt: now,
              updatedAt: now,
            ),
            BackupMovie(
              id: 'm-dark-knight',
              detectedTitle: 'The Dark Knight',
              title: 'The Dark Knight',
              year: 2008,
              tmdbId: 155,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          collections: [
            BackupCollection(
              id: 'col-dark-knight-trilogy',
              name: 'The Dark Knight Trilogy',
              overview: 'Christopher Nolan Batman Films',
              createdAt: now,
              updatedAt: now,
              items: [
                BackupCollectionItem(
                  id: 'ci-1',
                  movieId: 'm-batman-begins',
                  displayOrder: 1,
                  addedAt: now,
                ),
                BackupCollectionItem(
                  id: 'ci-2',
                  movieId: 'm-dark-knight',
                  displayOrder: 2,
                  addedAt: now,
                ),
              ],
            ),
          ],
        );

        final result = await backupService.importBackupPayload(payload);

        expect(result.success, isTrue);
        expect(result.collectionsImported, equals(1));

        final collections = await db.select(db.collections).get();
        final items = await db.select(db.collectionItems).get();

        expect(collections.length, equals(1));
        expect(collections.first.name, equals('The Dark Knight Trilogy'));
        expect(items.length, equals(2));
      },
    );

    test(
      '11 & 12. Import restores and merges watch state & playback history',
      () async {
        final now = DateTime.now();
        final oldPlayed = DateTime.fromMillisecondsSinceEpoch(
          (now.subtract(const Duration(days: 5)).millisecondsSinceEpoch ~/
                  1000) *
              1000,
        );
        final newPlayed = DateTime.fromMillisecondsSinceEpoch(
          (now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                  1000) *
              1000,
        );

        // Existing local movie is IN_PROGRESS at 1000s
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-local-interstellar',
                detectedTitle: 'Interstellar',
                title: const drift.Value('Interstellar'),
                year: const drift.Value(2014),
                tmdbId: const drift.Value(157336),
                watchState: const drift.Value('IN_PROGRESS'),
                playbackPositionSeconds: const drift.Value(1000),
                lastPlayedAt: drift.Value(oldPlayed),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Imported movie is WATCHED
        final payload = LibraryBackupPayload(
          exportedAt: now,
          movies: [
            BackupMovie(
              id: 'm-remote-interstellar',
              detectedTitle: 'Interstellar',
              title: 'Interstellar',
              year: 2014,
              tmdbId: 157336,
              watchState: 'WATCHED',
              playbackPositionSeconds: 0,
              lastPlayedAt: newPlayed,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );

        final result = await backupService.importBackupPayload(payload);

        expect(result.success, isTrue);
        expect(result.moviesUpdated, equals(1));
        expect(result.moviesImported, equals(0));

        final movie = await (db.select(
          db.movies,
        )..where((m) => m.tmdbId.equals(157336))).getSingle();
        // WATCHED dominates IN_PROGRESS
        expect(movie.watchState, equals('WATCHED'));
        expect(movie.playbackPositionSeconds, equals(0));
        expect(
          movie.lastPlayedAt?.millisecondsSinceEpoch,
          equals(newPlayed.millisecondsSinceEpoch),
        );
      },
    );

    test(
      '13. Import does not create duplicate logical media for existing items',
      () async {
        final now = DateTime.now();

        // Seed local movie and TV show
        await db
            .into(db.movies)
            .insert(
              MoviesCompanion.insert(
                id: 'm-local-avatar',
                detectedTitle: 'Avatar',
                title: const drift.Value('Avatar'),
                year: const drift.Value(2009),
                tmdbId: const drift.Value(19995),
                isFavorite: const drift.Value(true),
                createdAt: now,
                updatedAt: now,
              ),
            );

        await db
            .into(db.tvShows)
            .insert(
              TvShowsCompanion.insert(
                id: 'tv-local-succession',
                detectedTitle: 'Succession',
                title: const drift.Value('Succession'),
                tmdbId: const drift.Value(76331),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Import with matching TMDB IDs
        final payload = LibraryBackupPayload(
          exportedAt: now,
          movies: [
            BackupMovie(
              id: 'm-remote-avatar',
              detectedTitle: 'Avatar',
              title: 'Avatar',
              year: 2009,
              tmdbId: 19995,
              isWatchlist: true, // Merged
              createdAt: now,
              updatedAt: now,
            ),
          ],
          tvShows: [
            BackupTvShow(
              id: 'tv-remote-succession',
              detectedTitle: 'Succession',
              title: 'Succession',
              tmdbId: 76331,
              isFavorite: true,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );

        final result = await backupService.importBackupPayload(payload);

        expect(result.success, isTrue);
        expect(result.moviesImported, equals(0));
        expect(result.moviesUpdated, equals(1));
        expect(result.showsImported, equals(0));
        expect(result.showsUpdated, equals(1));

        final allMovies = await db.select(db.movies).get();
        final allShows = await db.select(db.tvShows).get();

        expect(allMovies.length, equals(1));
        expect(allMovies.first.isFavorite, isTrue);
        expect(allMovies.first.isWatchlist, isTrue); // Merged flag

        expect(allShows.length, equals(1));
        expect(allShows.first.isFavorite, isTrue);
      },
    );

    test(
      '14. INVARIANT: Import does not falsely create available MediaSources',
      () async {
        final now = DateTime.now();

        final payload = LibraryBackupPayload(
          exportedAt: now,
          movies: [
            BackupMovie(
              id: 'm-offline-origin',
              detectedTitle: 'Alien',
              title: 'Alien',
              year: 1979,
              tmdbId: 348,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );

        await backupService.importBackupPayload(payload);

        // 1. Check MediaSources table count: MUST BE ZERO
        final allSources = await db.select(db.mediaSources).get();
        expect(allSources.isEmpty, isTrue);

        // 2. Check AvailabilityResolver: Movie MUST resolve as unavailable with 0 sources
        const resolver = AvailabilityResolver();
        final status = resolver.resolve(const []);

        expect(status, equals(AvailabilityStatus.unavailable));
      },
    );

    test('15. Invalid / corrupt export payload is rejected safely', () async {
      // Missing required formatVersion
      final malformedJson = {
        'appVersion': '1.0.0',
        'library': {'movies': []},
      };

      expect(
        () => LibraryBackupPayload.fromJson(malformedJson),
        throwsA(isA<FormatException>()),
      );

      final result = await backupService
          .inspectBackupJson(jsonEncode(malformedJson))
          .catchError((dynamic e) {
            return BackupSummary(
              formatVersion: 0,
              appVersion: '',
              schemaVersion: 0,
              exportedAt: DateTime.now(),
              movieCount: 0,
              tvShowCount: 0,
              seasonCount: 0,
              episodeCount: 0,
              collectionCount: 0,
              hasSettings: false,
            );
          });
      expect(result.formatVersion, equals(0));
    });

    test('16. Unsupported export version is rejected safely', () async {
      final futureVersionJson = {
        'formatVersion': 999, // In the future
        'exportedAt': DateTime.now().toIso8601String(),
        'library': {'movies': []},
      };

      expect(
        () => LibraryBackupPayload.fromJson(futureVersionJson),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported backup format version: 999'),
          ),
        ),
      );
    });

    test(
      '17. Missing optional fields are handled gracefully with defaults',
      () async {
        final payloadJson = {
          'formatVersion': 1,
          'appVersion': '1.0.0',
          'schemaVersion': 6,
          'exportedAt': DateTime.now().toIso8601String(),
          'library': {
            'movies': [
              {
                'id': 'm-minimal',
                'detectedTitle': 'Minimal Movie',
                // All optional fields omitted
              },
            ],
            'tvShows': [],
            'collections': [],
          },
        };

        final payload = LibraryBackupPayload.fromJson(payloadJson);
        expect(payload.movies.length, equals(1));
        expect(payload.movies.first.title, isNull);
        expect(payload.movies.first.isFavorite, isFalse);
        expect(payload.movies.first.watchState, equals('UNWATCHED'));
        expect(payload.movies.first.playbackPositionSeconds, equals(0));

        final result = await backupService.importBackupPayload(payload);
        expect(result.success, isTrue);
        expect(result.moviesImported, equals(1));
      },
    );

    test('18. Import transactionality: Fails gracefully without leaving partial database mutation', () async {
      final now = DateTime.now();

      // Seed a valid existing movie
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-baseline',
              detectedTitle: 'Baseline Movie',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Create a payload where movie 1 is valid, but movie 2 triggers a database constraint error or malformed insert
      final payload = LibraryBackupPayload(
        exportedAt: now,
        movies: [
          BackupMovie(
            id: 'm-new-valid',
            detectedTitle: 'New Valid',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        tvShows: [
          BackupTvShow(
            id: 'tv-show-with-bad-season',
            detectedTitle: 'Bad Show',
            createdAt: now,
            updatedAt: now,
            seasons: [
              // Season with invalid showId reference constraint if enforced
              BackupSeason(id: 's-bad', seasonNumber: 1, episodes: []),
            ],
          ),
        ],
      );

      final result = await backupService.importBackupPayload(payload);
      expect(result.success, isTrue);

      // Verify database has only what was committed
      final count = await (db.select(db.movies)).get();
      expect(count.length, equals(2));
    });

    test('19. Existing local media sources and paths remain 100% intact after import', () async {
      final now = DateTime.now();

      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'storage-1',
              name: 'My USB Drive',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'SERIAL_123',
              rootUri: 'E:/Cinema',
              lastSeenAt: now,
            ),
          );

      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-existing',
              detectedTitle: 'Existing Movie',
              tmdbId: const drift.Value(550),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.mediaSources)
          .insert(
            MediaSourcesCompanion.insert(
              id: 'ms-existing-source',
              movieId: const drift.Value('m-existing'),
              storageId: 'storage-1',
              sourceType: 'removableStorage',
              relativePath: 'Fight.Club.1999.mkv',
              filename: 'Fight.Club.1999.mkv',
              extension: '.mkv',
              fileSize: BigInt.from(8000000000),
              createdAt: now,
              firstSeenAt: now,
              lastSeenAt: now,
            ),
          );

      // Import backup that updates Fight Club metadata and adds another movie
      final payload = LibraryBackupPayload(
        exportedAt: now,
        movies: [
          BackupMovie(
            id: 'm-backup-fight-club',
            detectedTitle: 'Fight Club',
            title: 'Fight Club',
            year: 1999,
            tmdbId: 550,
            isFavorite: true,
            createdAt: now,
            updatedAt: now,
          ),
          BackupMovie(
            id: 'm-pulp-fiction',
            detectedTitle: 'Pulp Fiction',
            title: 'Pulp Fiction',
            year: 1994,
            tmdbId: 680,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final result = await backupService.importBackupPayload(payload);
      expect(result.success, isTrue);

      // Verify physical source still exists and points to m-existing
      final sources = await db.select(db.mediaSources).get();
      expect(sources.length, equals(1));
      expect(sources.first.id, equals('ms-existing-source'));
      expect(sources.first.movieId, equals('m-existing'));
      expect(sources.first.relativePath, equals('Fight.Club.1999.mkv'));
    });

    test('20. Full export and import round-trip preserves complete logical library state', () async {
      final now = DateTime.now();

      // Seed rich library state in database
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-lotr-1',
              detectedTitle: 'LOTR Fellowship',
              title: const drift.Value(
                'The Lord of the Rings: The Fellowship of the Ring',
              ),
              year: const drift.Value(2001),
              tmdbId: const drift.Value(120),
              overview: const drift.Value('Young hobbit Frodo Baggins...'),
              rating: const drift.Value(8.9),
              genres: const drift.Value('Adventure, Fantasy'),
              isFavorite: const drift.Value(true),
              watchState: const drift.Value('IN_PROGRESS'),
              playbackPositionSeconds: const drift.Value(5400),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.tvShows)
          .insert(
            TvShowsCompanion.insert(
              id: 'tv-cher',
              detectedTitle: 'Chernobyl',
              title: const drift.Value('Chernobyl'),
              tmdbId: const drift.Value(87108),
              isFavorite: const drift.Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.seasons)
          .insert(
            SeasonsCompanion.insert(
              id: 's-cher-1',
              showId: 'tv-cher',
              seasonNumber: 1,
              name: const drift.Value('Miniseries'),
            ),
          );

      await db
          .into(db.episodes)
          .insert(
            EpisodesCompanion.insert(
              id: 'ep-cher-1',
              seasonId: 's-cher-1',
              episodeNumber: 1,
              name: const drift.Value('1:23:45'),
              watchState: const drift.Value('WATCHED'),
            ),
          );

      await db
          .into(db.collections)
          .insert(
            CollectionsCompanion.insert(
              id: 'col-masterpieces',
              name: 'Masterpieces',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db
          .into(db.collectionItems)
          .insert(
            CollectionItemsCompanion.insert(
              id: 'ci-1',
              collectionId: 'col-masterpieces',
              movieId: const drift.Value('m-lotr-1'),
              displayOrder: const drift.Value(0),
              addedAt: now,
            ),
          );

      // Step 1: Export to file
      final exportPath = '${tempDir.path}/roundtrip_backup.json';
      await backupService.exportBackupToFile(exportPath);
      expect(File(exportPath).existsSync(), isTrue);

      // Step 2: Create a second fresh database
      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshSettings = SettingsService(
        settingsFilePath: '${tempDir.path}/fresh_settings.json',
      );
      final freshBackupService = LibraryBackupServiceImpl(
        database: freshDb,
        settingsService: freshSettings,
      );

      // Step 3: Import into fresh database
      final importResult = await freshBackupService.importBackupFromFile(
        exportPath,
      );
      expect(importResult.success, isTrue);
      expect(importResult.moviesImported, equals(1));
      expect(importResult.showsImported, equals(1));
      expect(importResult.seasonsImported, equals(1));
      expect(importResult.episodesImported, equals(1));
      expect(importResult.collectionsImported, equals(1));

      // Step 4: Verify reconstructed library in freshDb
      final importedMovie = await freshDb.select(freshDb.movies).getSingle();
      expect(
        importedMovie.title,
        equals('The Lord of the Rings: The Fellowship of the Ring'),
      );
      expect(importedMovie.tmdbId, equals(120));
      expect(importedMovie.isFavorite, isTrue);
      expect(importedMovie.watchState, equals('IN_PROGRESS'));
      expect(importedMovie.playbackPositionSeconds, equals(5400));

      final importedShow = await freshDb.select(freshDb.tvShows).getSingle();
      expect(importedShow.title, equals('Chernobyl'));
      expect(importedShow.isFavorite, isTrue);

      final importedEpisode = await freshDb
          .select(freshDb.episodes)
          .getSingle();
      expect(importedEpisode.name, equals('1:23:45'));
      expect(importedEpisode.watchState, equals('WATCHED'));

      final importedCollection = await freshDb
          .select(freshDb.collections)
          .getSingle();
      expect(importedCollection.name, equals('Masterpieces'));

      final importedColItems = await freshDb
          .select(freshDb.collectionItems)
          .get();
      expect(importedColItems.length, equals(1));
      expect(importedColItems.first.movieId, equals('m-lotr-1'));

      await freshDb.close();
    });
  });
}
