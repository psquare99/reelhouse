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
      expect(movie.title, 'Interstellar');
      expect(movie.year, 2014);

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
      expect(show.title, 'Breaking Bad');

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
      expect(movies.first.title, 'Interstellar');

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
    final memento = allMovies.firstWhere((m) => m.title == 'Memento');
    final mementoSources = await db.getSourcesForMovie(memento.id);
    expect(mementoSources.first.available, isFalse);

    // Inception remains available = true
    final inception = allMovies.firstWhere((m) => m.title == 'Inception');
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
}
