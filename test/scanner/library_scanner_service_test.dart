import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/domain/scanner/library_scanner_service.dart';
import 'package:reelhouse/domain/scanner/media_scanner.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';

class MockStorageIdentityService implements StorageIdentityService {
  final Map<String, bool> connectedMap = {};

  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'mock-fs-id';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      p.basename(rootUriOrPath);

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async =>
      connectedMap[rootUriOrPath] ?? true;

  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;

  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {}
}

void main() {
  late AppDatabase db;
  late MockStorageIdentityService identityService;
  late LibraryScannerService libraryScanner;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    identityService = MockStorageIdentityService();
    libraryScanner = LibraryScannerService(
      database: db,
      storageIdentityService: identityService,
      mediaScanner: const MediaScanner(),
    );
    tempDir = Directory.systemTemp.createTempSync('reelhouse_lib_scan_test_');
    identityService.connectedMap[tempDir.path] = true;
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void createTestFile(String relativePath, [int sizeBytes = 1024]) {
    final fullPath = p.join(tempDir.path, relativePath);
    final file = File(fullPath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(List.filled(sizeBytes, 0));
  }

  void deleteTestFile(String relativePath) {
    final fullPath = p.join(tempDir.path, relativePath);
    final file = File(fullPath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  test(
    'Initial scan discovers movies & TV shows, registers sources & entities',
    () async {
      // 1. Insert external storage record
      final storageCompanion = StoragesCompanion.insert(
        id: 'hdd-1',
        name: 'External HDD 1',
        storageType: 'REMOVABLE_VOLUME',
        filesystemIdentifier: '0x12345678',
        rootUri: tempDir.path,
        lastSeenAt: DateTime.now(),
        available: const drift.Value(true),
      );
      await db.upsertStorage(storageCompanion);
      final storage = (await db.getAllStorages()).firstWhere(
        (s) => s.id == 'hdd-1',
      );

      // 2. Create test files on disk
      createTestFile('Interstellar.2014.1080p.mkv', 2048);
      createTestFile(
        r'TV\Breaking Bad\Season 2\Breaking.Bad.S02E03.1080p.mkv',
        2048,
      );

      // 3. Perform scan
      final progressEvents = <ScanProgress>[];
      final summary = await libraryScanner.scanStorage(
        storage,
        onProgress: progressEvents.add,
      );

      expect(summary.filesDiscovered, 2);
      expect(summary.newSourcesAdded, 2);
      expect(summary.moviesIdentified, 1);
      expect(summary.tvEpisodesIdentified, 1);
      expect(progressEvents.isNotEmpty, isTrue);
      expect(progressEvents.last.isComplete, isTrue);

      // Verify Movie entity created
      final allMovies = await db.getAllMovies();
      expect(allMovies.length, 1);
      final movie = allMovies.first;
      expect(movie.detectedTitle, 'Interstellar');
      expect(movie.detectedYear, 2014);
      expect(movie.title, isNull);
      expect(movie.year, isNull);
      expect(movie.identificationStatus, 'PENDING');

      // Verify Movie MediaSource created
      final movieSources = await db.getSourcesForMovie(movie.id);
      expect(movieSources.length, 1);
      expect(movieSources.first.storageId, 'hdd-1');
      expect(movieSources.first.resolution, '1080p');
      expect(movieSources.first.available, isTrue);

      // Verify TV Show hierarchy created
      final allShows = await db.getAllTvShows();
      expect(allShows.length, 1);
      final show = allShows.first;
      expect(show.detectedTitle, 'Breaking Bad');
      expect(show.title, isNull);
      expect(show.identificationStatus, 'PENDING');

      final season = await db.findSeason(show.id, 2);
      expect(season, isNotNull);

      final episode = await db.findEpisode(season!.id, 3);
      expect(episode, isNotNull);

      final epSources = await db.getSourcesForEpisode(episode!.id);
      expect(epSources.length, 1);
      expect(epSources.first.resolution, '1080p');
    },
  );

  test('Multi-source architecture: links identical movie across 2 drives to the same Movie entity', () async {
    // Drive 1
    final storage1 = StoragesCompanion.insert(
      id: 'hdd-1',
      name: 'HDD 1',
      storageType: 'REMOVABLE_VOLUME',
      filesystemIdentifier: '0x1111',
      rootUri: tempDir.path,
      lastSeenAt: DateTime.now(),
      available: const drift.Value(true),
    );
    await db.upsertStorage(storage1);
    final s1 = (await db.getAllStorages()).firstWhere((s) => s.id == 'hdd-1');

    createTestFile('Interstellar.2014.1080p.mkv', 2048);
    await libraryScanner.scanStorage(s1);

    // Drive 2 (Simulated second folder)
    final drive2Dir = Directory.systemTemp.createTempSync('reelhouse_drive2_');
    identityService.connectedMap[drive2Dir.path] = true;

    try {
      final storage2 = StoragesCompanion.insert(
        id: 'hdd-2',
        name: 'HDD 2 (4K Remux)',
        storageType: 'REMOVABLE_VOLUME',
        filesystemIdentifier: '0x2222',
        rootUri: drive2Dir.path,
        lastSeenAt: DateTime.now(),
        available: const drift.Value(true),
      );
      await db.upsertStorage(storage2);
      final s2 = (await db.getAllStorages()).firstWhere((s) => s.id == 'hdd-2');

      // Add Interstellar 4K to drive 2
      final fullPath = p.join(
        drive2Dir.path,
        'Interstellar.2014.2160p.UHD.mkv',
      );
      File(fullPath).writeAsBytesSync(List.filled(1024, 0));

      await libraryScanner.scanStorage(s2);

      // Verify ONLY ONE logical movie exists!
      final movies = await db.getAllMovies();
      expect(movies.length, 1);
      expect(movies.first.detectedTitle, 'Interstellar');

      // Verify TWO physical media sources are linked to that movie!
      final sources = await db.getSourcesForMovie(movies.first.id);
      expect(sources.length, 2);

      final storages = sources.map((s) => s.storageId).toSet();
      expect(storages, containsAll(['hdd-1', 'hdd-2']));
    } finally {
      if (drive2Dir.existsSync()) {
        drive2Dir.deleteSync(recursive: true);
      }
    }
  });

  test('Incremental scan: marks disappeared files unavailable without deleting library entity', () async {
    final storageCompanion = StoragesCompanion.insert(
      id: 'hdd-1',
      name: 'External HDD 1',
      storageType: 'REMOVABLE_VOLUME',
      filesystemIdentifier: '0x12345678',
      rootUri: tempDir.path,
      lastSeenAt: DateTime.now(),
      available: const drift.Value(true),
    );
    await db.upsertStorage(storageCompanion);
    final storage = (await db.getAllStorages()).firstWhere(
      (s) => s.id == 'hdd-1',
    );

    createTestFile('Inception.2010.mkv', 1024);
    createTestFile('Memento.2000.mkv', 1024);

    // First scan: adds both
    final s1 = await libraryScanner.scanStorage(storage);
    expect(s1.newSourcesAdded, 2);
    expect((await db.getAllMovies()).length, 2);

    // User deletes Memento from disk
    deleteTestFile('Memento.2000.mkv');

    // Second scan
    final s2 = await libraryScanner.scanStorage(storage);
    expect(s2.sourcesMarkedMissing, 1);
    expect(s2.newSourcesAdded, 0);

    // The Movie entity STILL EXISTS in the cinema catalogue! (Section 46)
    final allMovies = await db.getAllMovies();
    expect(allMovies.length, 2);

    // But Memento's source is marked available = false
    final memento = allMovies.firstWhere((m) => m.detectedTitle == 'Memento');
    final mementoSources = await db.getSourcesForMovie(memento.id);
    expect(mementoSources.first.available, isFalse);

    // Inception remains available = true
    final inception = allMovies.firstWhere(
      (m) => m.detectedTitle == 'Inception',
    );
    final inceptionSources = await db.getSourcesForMovie(inception.id);
    expect(inceptionSources.first.available, isTrue);

    // User restores Memento to disk
    createTestFile('Memento.2000.mkv', 1024);

    // Third scan
    final s3 = await libraryScanner.scanStorage(storage);
    expect(s3.sourcesRestored, 1);

    final mementoSourcesRestored = await db.getSourcesForMovie(memento.id);
    expect(mementoSourcesRestored.first.available, isTrue);
  });

  // --- Tests A through H for Phase 1B Canonical Media Identity Scanner ---

  test('A & C: New movie discovery and rescan unchanged movie preserves logical Movie ID and MediaSources', () async {
    final storageCompanion = StoragesCompanion.insert(
      id: 'hdd-movies',
      name: 'Movies HDD',
      storageType: 'REMOVABLE_VOLUME',
      filesystemIdentifier: '0xAAAA',
      rootUri: tempDir.path,
      lastSeenAt: DateTime.now(),
      available: const drift.Value(true),
    );
    await db.upsertStorage(storageCompanion);
    final storage = (await db.getAllStorages()).firstWhere(
      (s) => s.id == 'hdd-movies',
    );

    createTestFile('The.Dark.Knight.2008.1080p.mkv', 2048);

    // Initial scan (A)
    final s1 = await libraryScanner.scanStorage(storage);
    expect(s1.newSourcesAdded, 1);
    expect(s1.moviesIdentified, 1);

    final moviesAfterFirstScan = await db.getAllMovies();
    expect(moviesAfterFirstScan.length, 1);
    final movie = moviesAfterFirstScan.first;
    expect(movie.detectedTitle, 'The Dark Knight');
    expect(movie.detectedYear, 2008);
    expect(movie.title, isNull);
    expect(movie.year, isNull);
    expect(movie.identificationStatus, 'PENDING');

    final originalMovieId = movie.id;
    final originalSources = await db.getSourcesForMovie(originalMovieId);
    expect(originalSources.length, 1);
    final originalSourceId = originalSources.first.id;

    // Rescan unchanged movie (C)
    final s2 = await libraryScanner.scanStorage(storage);
    expect(s2.newSourcesAdded, 0);
    expect(s2.sourcesRestored, 0);
    expect(s2.sourcesMarkedMissing, 0);

    final moviesAfterSecondScan = await db.getAllMovies();
    expect(moviesAfterSecondScan.length, 1);
    expect(moviesAfterSecondScan.first.id, originalMovieId);

    final sourcesAfterSecondScan = await db.getSourcesForMovie(originalMovieId);
    expect(sourcesAfterSecondScan.length, 1);
    expect(sourcesAfterSecondScan.first.id, originalSourceId);
  });

  test('B & D: New TV discovery and rescan unchanged TV show preserves logical TvShow ID, Season, and Episode', () async {
    final storageCompanion = StoragesCompanion.insert(
      id: 'hdd-tv',
      name: 'TV HDD',
      storageType: 'REMOVABLE_VOLUME',
      filesystemIdentifier: '0xBBBB',
      rootUri: tempDir.path,
      lastSeenAt: DateTime.now(),
      available: const drift.Value(true),
    );
    await db.upsertStorage(storageCompanion);
    final storage = (await db.getAllStorages()).firstWhere(
      (s) => s.id == 'hdd-tv',
    );

    createTestFile(r'TV\Succession\Season 1\Succession.S01E01.mkv', 2048);

    // Initial scan (B)
    final s1 = await libraryScanner.scanStorage(storage);
    expect(s1.newSourcesAdded, 1);
    expect(s1.tvEpisodesIdentified, 1);

    final shows = await db.getAllTvShows();
    expect(shows.length, 1);
    final show = shows.first;
    expect(show.detectedTitle, 'Succession');
    expect(show.title, isNull);
    expect(show.identificationStatus, 'PENDING');

    final originalShowId = show.id;
    final season = await db.findSeason(originalShowId, 1);
    expect(season, isNotNull);
    final episode = await db.findEpisode(season!.id, 1);
    expect(episode, isNotNull);

    // Rescan unchanged TV show (D)
    final s2 = await libraryScanner.scanStorage(storage);
    expect(s2.newSourcesAdded, 0);
    expect(s2.sourcesRestored, 0);
    expect(s2.sourcesMarkedMissing, 0);

    final showsAfterSecondScan = await db.getAllTvShows();
    expect(showsAfterSecondScan.length, 1);
    expect(showsAfterSecondScan.first.id, originalShowId);
  });

  test('E: Canonical movie title change does not cause scanner to duplicate logical Movie on rescan or new source', () async {
    final storage1 = StoragesCompanion.insert(
      id: 'hdd-movie-e',
      name: 'Movie HDD E',
      storageType: 'REMOVABLE_VOLUME',
      filesystemIdentifier: '0xEEEE',
      rootUri: tempDir.path,
      lastSeenAt: DateTime.now(),
      available: const drift.Value(true),
    );
    await db.upsertStorage(storage1);
    final s1 = (await db.getAllStorages()).firstWhere(
      (s) => s.id == 'hdd-movie-e',
    );

    createTestFile('Some.Movie.2020.1080p.mkv', 1024);
    await libraryScanner.scanStorage(s1);

    final originalMovie = (await db.getAllMovies()).first;
    expect(originalMovie.detectedTitle, 'Some Movie');
    expect(originalMovie.detectedYear, 2020);

    // Simulate metadata identification updating canonical title and status
    await (db.update(
      db.movies,
    )..where((m) => m.id.equals(originalMovie.id))).write(
      const MoviesCompanion(
        title: drift.Value('Canonical Movie Title'),
        year: drift.Value(2020),
        tmdbId: drift.Value(99901),
        identificationStatus: drift.Value('IDENTIFIED'),
      ),
    );

    // 1. Rescan same source: verify it still maps to originalMovie and doesn't duplicate
    await libraryScanner.scanStorage(s1);
    var movies = await db.getAllMovies();
    expect(movies.length, 1);
    expect(movies.first.id, originalMovie.id);
    expect(movies.first.title, 'Canonical Movie Title');
    expect(movies.first.detectedTitle, 'Some Movie');

    // 2. Discover another source on a second drive with same discovery hints
    final drive2Dir = Directory.systemTemp.createTempSync(
      'reelhouse_movie_e2_',
    );
    identityService.connectedMap[drive2Dir.path] = true;
    try {
      final storage2 = StoragesCompanion.insert(
        id: 'hdd-movie-e2',
        name: 'Movie HDD E2',
        storageType: 'REMOVABLE_VOLUME',
        filesystemIdentifier: '0xEEEE2',
        rootUri: drive2Dir.path,
        lastSeenAt: DateTime.now(),
        available: const drift.Value(true),
      );
      await db.upsertStorage(storage2);
      final s2 = (await db.getAllStorages()).firstWhere(
        (s) => s.id == 'hdd-movie-e2',
      );

      final fullPath = p.join(drive2Dir.path, 'Some.Movie.2020.2160p.mkv');
      File(fullPath).writeAsBytesSync(List.filled(1024, 0));

      await libraryScanner.scanStorage(s2);

      // Verify still exactly ONE logical movie, with two sources attached!
      movies = await db.getAllMovies();
      expect(movies.length, 1);
      expect(movies.first.id, originalMovie.id);
      expect(movies.first.title, 'Canonical Movie Title');

      final sources = await db.getSourcesForMovie(originalMovie.id);
      expect(sources.length, 2);
    } finally {
      if (drive2Dir.existsSync()) {
        drive2Dir.deleteSync(recursive: true);
      }
    }
  });

  test('F & G: Canonical TV title change does not duplicate TvShow and preserves Season/Episode hierarchy', () async {
    final storage1 = StoragesCompanion.insert(
      id: 'hdd-tv-fg',
      name: 'TV HDD FG',
      storageType: 'REMOVABLE_VOLUME',
      filesystemIdentifier: '0xFFGG',
      rootUri: tempDir.path,
      lastSeenAt: DateTime.now(),
      available: const drift.Value(true),
    );
    await db.upsertStorage(storage1);
    final s1 = (await db.getAllStorages()).firstWhere(
      (s) => s.id == 'hdd-tv-fg',
    );

    createTestFile(r'TV\HIMYM\Season 1\HIMYM.S01E01.mkv', 1024);
    await libraryScanner.scanStorage(s1);

    final originalShow = (await db.getAllTvShows()).first;
    expect(originalShow.detectedTitle, 'HIMYM');
    expect(originalShow.title, isNull);

    final season1 = await db.findSeason(originalShow.id, 1);
    expect(season1, isNotNull);
    final ep1 = await db.findEpisode(season1!.id, 1);
    expect(ep1, isNotNull);

    // Simulate metadata identification updating canonical title and status
    await (db.update(
      db.tvShows,
    )..where((t) => t.id.equals(originalShow.id))).write(
      const TvShowsCompanion(
        title: drift.Value('How I Met Your Mother'),
        tmdbId: drift.Value(1100),
        identificationStatus: drift.Value('IDENTIFIED'),
      ),
    );

    // Add Episode 2 to the same source on disk
    createTestFile(r'TV\HIMYM\Season 1\HIMYM.S01E02.mkv', 1024);

    // Rescan
    await libraryScanner.scanStorage(s1);

    // (F) Verify exactly one TvShow row, existing ID preserved, canonical title intact
    final shows = await db.getAllTvShows();
    expect(shows.length, 1);
    expect(shows.first.id, originalShow.id);
    expect(shows.first.detectedTitle, 'HIMYM');
    expect(shows.first.title, 'How I Met Your Mother');
    expect(shows.first.identificationStatus, 'IDENTIFIED');

    // (G) Verify season and episodes remain attached to the same TvShow
    final seasonAfterRescan = await db.findSeason(originalShow.id, 1);
    expect(seasonAfterRescan, isNotNull);
    expect(seasonAfterRescan!.id, season1.id);

    final ep1AfterRescan = await db.findEpisode(season1.id, 1);
    expect(ep1AfterRescan, isNotNull);
    expect(ep1AfterRescan!.id, ep1!.id);

    final ep2AfterRescan = await db.findEpisode(season1.id, 2);
    expect(ep2AfterRescan, isNotNull);
    expect(ep2AfterRescan!.seasonId, season1.id);

    final ep1Sources = await db.getSourcesForEpisode(ep1.id);
    expect(ep1Sources.length, 1);
    final ep2Sources = await db.getSourcesForEpisode(ep2AfterRescan.id);
    expect(ep2Sources.length, 1);
  });

  test('H: Different discoveries remain distinct and do not collapse into one entity', () async {
    final storageCompanion = StoragesCompanion.insert(
      id: 'hdd-distinct',
      name: 'Distinct HDD',
      storageType: 'REMOVABLE_VOLUME',
      filesystemIdentifier: '0xHHHH',
      rootUri: tempDir.path,
      lastSeenAt: DateTime.now(),
      available: const drift.Value(true),
    );
    await db.upsertStorage(storageCompanion);
    final storage = (await db.getAllStorages()).firstWhere(
      (s) => s.id == 'hdd-distinct',
    );

    // 1. Two movies with different years
    createTestFile('Avatar.2009.1080p.mkv', 1024);
    createTestFile('Avatar.The.Way.of.Water.2022.1080p.mkv', 1024);

    // 2. Two distinct TV shows
    createTestFile(r'TV\The Office\Season 1\The.Office.S01E01.mkv', 1024);
    createTestFile(r'TV\The Office UK\Season 1\The.Office.UK.S01E01.mkv', 1024);

    await libraryScanner.scanStorage(storage);

    final movies = await db.getAllMovies();
    expect(movies.length, 2);
    final movieTitles = movies.map((m) => m.detectedTitle).toSet();
    expect(movieTitles, containsAll(['Avatar', 'Avatar The Way of Water']));

    final shows = await db.getAllTvShows();
    expect(shows.length, 2);
    final showTitles = shows.map((s) => s.detectedTitle).toSet();
    expect(showTitles, containsAll(['The Office', 'The Office UK']));
  });

  test('I: Scanning files with manual numeric prefixes preserves single logical entity across scans after canonical identification', () async {
    final storageCompanion = StoragesCompanion.insert(
      id: 'hdd-prefixes',
      name: 'Prefix HDD',
      storageType: 'REMOVABLE_VOLUME',
      filesystemIdentifier: '0xPREFIX',
      rootUri: tempDir.path,
      lastSeenAt: DateTime.now(),
      available: const drift.Value(true),
    );
    await db.upsertStorage(storageCompanion);
    final storage = (await db.getAllStorages()).firstWhere(
      (s) => s.id == 'hdd-prefixes',
    );

    // Initial scan of "1 Iron Man.2008.mkv"
    createTestFile('1 Iron Man.2008.mkv', 2048);
    final s1 = await libraryScanner.scanStorage(storage);
    expect(s1.newSourcesAdded, 1);
    expect(s1.moviesIdentified, 1);

    final movies1 = await db.getAllMovies();
    expect(movies1.length, 1);
    final movie = movies1.first;
    expect(movie.detectedTitle, '1 Iron Man');
    expect(movie.detectedYear, 2008);

    // Simulate canonical identification updating title to "Iron Man"
    await (db.update(db.movies)..where((m) => m.id.equals(movie.id))).write(
      const MoviesCompanion(
        title: drift.Value('Iron Man'),
        year: drift.Value(2008),
        tmdbId: drift.Value(1726),
        identificationStatus: drift.Value('IDENTIFIED'),
      ),
    );

    // Rescan unchanged storage
    final s2 = await libraryScanner.scanStorage(storage);
    expect(s2.newSourcesAdded, 0);

    // Verify still exactly one movie, with canonical title "Iron Man" and detectedTitle "1 Iron Man"
    final movies2 = await db.getAllMovies();
    expect(movies2.length, 1);
    expect(movies2.first.id, movie.id);
    expect(movies2.first.title, 'Iron Man');
    expect(movies2.first.detectedTitle, '1 Iron Man');
  });
}
