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
  Future<int> getTotalDeviceStorageBytes() async => 256 * 1024 * 1024 * 1024;

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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settingsService = SettingsService(settingsFilePath: '/fake/settings.json');
    await settingsService.setTmdbApiKey('test_key');
    metadataService = MetadataService(
      database: db,
      tmdbClient: TmdbApiClient(apiKey: 'test_key'),
      matcher: const MetadataMatcher(),
      imageCacheService: ImageCacheService(
        localStorageManager: FakeLocalStorageManager(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'SettingsScreen renders TMDB configuration card and required attribution',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
        findsAtLeastNWidgets(1),
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
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

  testWidgets(
    'SettingsScreen TMDB interaction: masked key, change key, cancel, and guide dialog',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setTmdbApiKey('active-verified-key');

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

      // Scroll to TMDB card
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('TMDB METADATA CONFIGURATION'), findsOneWidget);
      expect(find.text('The Movie Database (TMDB) API'), findsOneWidget);
      expect(find.text('CONNECTED'), findsOneWidget);
      expect(find.text('Change API Key'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Disconnect'), findsOneWidget);

      // Tap Change API Key
      await tester.tap(find.text('Change API Key'));
      await tester.pumpAndSettle();

      expect(find.text('Test & Save'), findsOneWidget);
      expect(find.text('Get a TMDB API Key'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Open Guide Dialog
      await tester.tap(find.text('Get a TMDB API Key'));
      await tester.pumpAndSettle();

      expect(find.text('How to Get a TMDB API Key'), findsOneWidget);
      expect(find.text('Got It'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();

      // Tap Cancel -> reverts to masked view without modifying existing key
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Change API Key'), findsOneWidget);
      expect(settingsService.tmdbApiKey, equals('active-verified-key'));

      // Unmount and flush
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'SettingsScreen renders Feedback & Suggestions section and opens FeedbackDialog',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // Scroll to bottom to reveal Feedback section
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      expect(find.text('FEEDBACK & SUGGESTIONS'), findsOneWidget);
      expect(
        find.text(
          'Help improve REELHOUSE by reporting bugs, suggesting improvements, or sharing feedback.',
        ),
        findsOneWidget,
      );
      expect(find.text('Send Feedback'), findsOneWidget);

      // Tap Send Feedback -> opens FeedbackDialog
      await tester.tap(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      expect(find.text('Report a Bug'), findsOneWidget);
      expect(find.text('Suggest an Improvement'), findsOneWidget);
      expect(find.text('General Feedback'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Unmount and flush
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'SettingsScreen renders About & Credits section with required information',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // Scroll to the very bottom to reveal About section
      await tester.drag(find.byType(ListView), const Offset(0, -1600));
      await tester.pumpAndSettle();

      // Verify About eyebrow
      expect(find.text('ABOUT'), findsOneWidget);

      // Verify application identity
      expect(find.text('REELHOUSE'), findsOneWidget);
      expect(find.text('Personal Digital Cinema'), findsOneWidget);

      // Verify version information
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.0+1'), findsOneWidget);
      expect(find.text('Platform'), findsOneWidget);

      // Verify credits
      expect(find.text('CREDITS'), findsOneWidget);
      expect(find.text('Built with'), findsOneWidget);
      expect(find.text('Flutter & Dart'), findsOneWidget);
      expect(find.text('Metadata'), findsOneWidget);
      expect(find.text('The Movie Database (TMDB)'), findsOneWidget);

      // Verify open-source acknowledgements
      expect(find.text('ACKNOWLEDGEMENTS'), findsOneWidget);
      expect(find.text('drift'), findsOneWidget);
      expect(find.text('path_provider'), findsOneWidget);
      expect(find.text('uuid'), findsOneWidget);

      // Verify TMDB attribution is still present
      expect(
        find.text(
          'This product uses the TMDB API but is not endorsed or certified by TMDB.',
        ),
        findsAtLeastNWidgets(1),
      );

      // RC.5B — Verify legal links
      expect(find.text('LEGAL'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(
        find.text('Media, Copyright & User Responsibility'),
        findsOneWidget,
      );

      // Unmount and flush
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
