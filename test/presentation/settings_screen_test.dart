import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/network/tmdb_api_client.dart';
import 'package:reelhouse/domain/metadata/image_cache_service.dart';
import 'package:reelhouse/domain/metadata/metadata_matcher.dart';
import 'package:reelhouse/domain/metadata/metadata_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/domain/services/settings_service.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/presentation/settings/settings_screen.dart';

class FakeStorageIdentityService implements StorageIdentityService {
  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'fake-fs';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      'Mock Disk';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async => true;

  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;

  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {}
}

class FakeLocalStorageManager implements LocalStorageManager {
  @override
  Future<String> getLocalMediaDirectoryPath() async => '/fake/media';

  @override
  Future<int> getAvailableDeviceStorageBytes() async =>
      128 * 1024 * 1024 * 1024;

  @override
  Future<int> getUsedOfflineStorageBytes() async => 2 * 1024 * 1024 * 1024;

  @override
  Future<String> resolveLocalPath(String relativePath) async =>
      '/fake/media/$relativePath';

  @override
  Future<bool> verifyLocalCopyIntegrity(
    String relativePath,
    int expectedBytes,
  ) async => true;

  @override
  Future<bool> deleteLocalCopy(String relativePath) async => true;
}

void main() {
  late AppDatabase db;
  late MetadataService metadataService;
  late SettingsService settingsService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    metadataService = MetadataService(
      database: db,
      tmdbClient: TmdbApiClient(apiKey: 'test_key'),
      matcher: const MetadataMatcher(),
      imageCacheService: ImageCacheService(
        localStorageManager: FakeLocalStorageManager(),
      ),
    );
    settingsService = SettingsService(settingsFilePath: '/fake/settings.json');
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'SettingsScreen renders TMDB configuration card and required attribution',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            storageIdentityService: FakeStorageIdentityService(),
            localStorageManager: FakeLocalStorageManager(),
            metadataService: metadataService,
            settingsService: settingsService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify sections
      expect(find.text('STORAGE LOCATIONS'), findsOneWidget);
      expect(find.text('TMDB METADATA CONFIGURATION'), findsOneWidget);
      expect(find.text('The Movie Database (TMDB) API'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Identify Unmatched Media'), findsOneWidget);

      // Drag ListView down to reveal Section 40 TMDB attribution
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This product uses the TMDB API but is not endorsed or certified by TMDB.',
        ),
        findsOneWidget,
      );

      // Unmount and flush Drift stream cancel timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'SettingsScreen displays Needs Verification alert when unmatched media exists',
    (WidgetTester tester) async {
      // Insert an unmatched movie
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-unverified',
              detectedTitle: 'Inception',
              title: const drift.Value('Inception'),
              year: const drift.Value(2010),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            storageIdentityService: FakeStorageIdentityService(),
            localStorageManager: FakeLocalStorageManager(),
            metadataService: metadataService,
            settingsService: settingsService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 items need your attention'), findsOneWidget);
      expect(find.text('Review Queue'), findsOneWidget);

      // Unmount and flush Drift stream cancel timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'SettingsScreen renders Appearance & Theme and allows switching theme mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            storageIdentityService: FakeStorageIdentityService(),
            localStorageManager: FakeLocalStorageManager(),
            metadataService: metadataService,
            settingsService: settingsService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag ListView down to reveal Appearance & Theme section
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE & THEME'), findsOneWidget);
      expect(find.text('Visual Theme'), findsOneWidget);
      expect(find.text('Dark (Screening Room)'), findsOneWidget);
      expect(find.text('Light (Gallery Linen)'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);

      // Tap Light Mode chip
      await tester.tap(find.text('Light (Gallery Linen)'));
      await tester.pumpAndSettle();

      expect(settingsService.themeMode, equals(ThemeMode.light));

      // Unmount and flush
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
