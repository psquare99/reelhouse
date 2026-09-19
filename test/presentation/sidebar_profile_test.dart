import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/network/tmdb_api_client.dart';
import 'package:reelhouse/domain/metadata/image_cache_service.dart';
import 'package:reelhouse/domain/metadata/metadata_matcher.dart';
import 'package:reelhouse/domain/metadata/metadata_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/domain/services/settings_service.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/domain/services/storage_monitor_service.dart';
import 'package:reelhouse/presentation/profile/profile_screen.dart';
import 'package:reelhouse/presentation/settings/settings_screen.dart';
import 'package:reelhouse/presentation/shell/cinema_shell.dart';

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

/// Overrides [startMonitoring] to be a no-op so tests don't start background
/// [Timer.periodic] timers that prevent the test runner from terminating.
class NoOpStorageMonitorService extends StorageMonitorService {
  NoOpStorageMonitorService({
    required super.database,
    required super.storageIdentityService,
  });

  @override
  void startMonitoring({Duration interval = const Duration(seconds: 10)}) {
    // intentionally empty — no background timer in tests
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MetadataService metadataService;
  late SettingsService settingsService;
  late StorageMonitorService storageMonitorService;
  late StorageIdentityService storageIdentityService;
  late LocalStorageManager localStorageManager;
  late Directory tempDir;

  setUp(() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    tempDir = await Directory.systemTemp.createTemp('sidebar_profile_test_');
    final settingsPath = p.join(tempDir.path, 'settings.json');

    db = AppDatabase(NativeDatabase.memory());
    storageIdentityService = FakeStorageIdentityService();
    localStorageManager = FakeLocalStorageManager();
    storageMonitorService = NoOpStorageMonitorService(
      database: db,
      storageIdentityService: storageIdentityService,
    );
    metadataService = MetadataService(
      database: db,
      tmdbClient: TmdbApiClient(apiKey: 'test_key'),
      matcher: const MetadataMatcher(),
      imageCacheService: ImageCacheService(
        localStorageManager: localStorageManager,
      ),
    );
    settingsService = await SettingsService.load(settingsPath);
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await db.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildShellWidget() {
    return MaterialApp(
      theme: CinemaTheme.darkTheme,
      home: CinemaShell(
        database: db,
        storageIdentityService: storageIdentityService,
        localStorageManager: localStorageManager,
        storageMonitorService: storageMonitorService,
        metadataService: metadataService,
        settingsService: settingsService,
      ),
    );
  }

  testWidgets(
    'Sidebar expanded: shows display name, initials, and navigates to ProfileScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setUserDisplayName('Prateek Pal');

      await tester.pumpWidget(buildShellWidget());
      await tester.pump();

      expect(find.text('Prateek Pal'), findsOneWidget);
      expect(find.text('Personal Profile'), findsOneWidget);
      expect(find.text('PP'), findsOneWidget);

      // Tap profile row → navigates to ProfileScreen
      await tester.tap(find.text('Prateek Pal'));
      await tester.pump();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'Sidebar expanded: profile is anchored to bottom with flexible space below Offline and Settings',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setUserDisplayName('Denis Villeneuve');

      await tester.pumpWidget(buildShellWidget());
      await tester.pump();

      final offlinePos = tester.getTopLeft(find.text('Offline'));
      final settingsPos = tester.getTopLeft(find.text('Settings'));
      final profilePos = tester.getTopLeft(find.text('Denis Villeneuve'));

      // Verify vertical sequence: Offline -> (flexible space) -> Settings -> Profile
      expect(
        settingsPos.dy,
        greaterThan(offlinePos.dy + 100),
      ); // Significant flexible space
      expect(profilePos.dy, greaterThan(settingsPos.dy));

      // Profile is near the bottom of the 1000px high viewport (within 100px of bottom)
      expect(profilePos.dy, greaterThan(900));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'Sidebar dynamic resize: profile remains bottom-anchored when height changes',
    (tester) async {
      // 1. Initial height: 700px
      tester.view.physicalSize = const Size(1400, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setUserDisplayName('Guillermo del Toro');

      await tester.pumpWidget(buildShellWidget());
      await tester.pump();

      final profilePosAt700 = tester.getTopLeft(
        find.text('Guillermo del Toro'),
      );
      expect(profilePosAt700.dy, greaterThan(600));

      // 2. Resize height to 1200px
      tester.view.physicalSize = const Size(1400, 1200);
      await tester.pump();

      final profilePosAt1200 = tester.getTopLeft(
        find.text('Guillermo del Toro'),
      );
      expect(profilePosAt1200.dy, greaterThan(1100));
      expect(profilePosAt1200.dy, greaterThan(profilePosAt700.dy + 450));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'Sidebar collapsed: shows avatar tooltip and navigates to ProfileScreen at bottom',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setUserDisplayName('Nolan');

      await tester.pumpWidget(buildShellWidget());
      await tester.pump();

      // Collapse the rail
      await tester.tap(find.byTooltip('Collapse sidebar'));
      await tester.pump();

      // Collapsed state: avatar tooltip contains display name
      expect(find.byTooltip('Nolan'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);

      final settingsIconPos = tester.getTopLeft(find.byTooltip('Settings'));
      final profileAvatarPos = tester.getTopLeft(find.byTooltip('Nolan'));

      // Bottom-anchored relative to settings
      expect(profileAvatarPos.dy, greaterThan(settingsIconPos.dy));
      expect(profileAvatarPos.dy, greaterThan(800));

      // Tap collapsed avatar → navigate to ProfileScreen
      await tester.tap(find.byTooltip('Nolan'));
      await tester.pump();

      expect(find.byType(ProfileScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'Sidebar reactively updates display name and initials on SettingsService change',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setUserDisplayName('Initial Name');

      await tester.pumpWidget(buildShellWidget());
      await tester.pump();

      expect(find.text('Initial Name'), findsOneWidget);
      expect(find.text('IN'), findsOneWidget);

      await settingsService.setUserDisplayName('Stanley Kubrick');
      await tester.pump();

      expect(find.text('Stanley Kubrick'), findsOneWidget);
      expect(find.text('SK'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'SettingsScreen shows profile summary card with Edit Profile callback',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setUserDisplayName('Quentin Tarantino');
      var editProfileTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: SettingsScreen(
            database: db,
            storageIdentityService: storageIdentityService,
            localStorageManager: localStorageManager,
            metadataService: metadataService,
            settingsService: settingsService,
            onNavigateToProfile: () => editProfileTapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Local Cinema Profile'), findsOneWidget);
      expect(find.text('Quentin Tarantino'), findsOneWidget);
      expect(find.text('QT'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);

      await tester.tap(find.text('Edit Profile'));
      await tester.pump();

      expect(editProfileTapped, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
