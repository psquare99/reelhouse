import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/repository/drift_library_repository.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
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
  late DriftLibraryRepository repository;
  late FakeStorageIdentityService storageIdentityService;
  late FakeLocalStorageManager localStorageManager;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftLibraryRepository(db);
    storageIdentityService = FakeStorageIdentityService();
    localStorageManager = FakeLocalStorageManager();
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidget() {
    return MaterialApp(
      home: SettingsScreen(
        database: db,
        repository: repository,
        storageIdentityService: storageIdentityService,
        localStorageManager: localStorageManager,
      ),
    );
  }

  testWidgets(
    'Settings screen renders Remove button for external drive and NOT for local device',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await db
          .into(db.storages)
          .insert(
            StoragesCompanion.insert(
              id: 'ext-usb-1',
              name: 'Samsung T7',
              storageType: 'REMOVABLE_VOLUME',
              filesystemIdentifier: 'SAMSUNG-T7-01',
              rootUri: 'E:\\Media',
              lastSeenAt: DateTime.now(),
            ),
          );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Verify "Simulate Disconnect" does NOT exist
      expect(find.text('Simulate Disconnect'), findsNothing);
      expect(find.text('Simulate Reconnect'), findsNothing);

      // Verify "Remove" button exists exactly once (for the external drive, not local device)
      expect(find.text('Remove'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets('Canceling Remove Storage Location leaves storage intact', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storageId = 'ext-usb-cancel';
    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: storageId,
            name: 'Crucial X8',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: 'CRUCIAL-X8',
            rootUri: 'F:\\Movies',
            lastSeenAt: DateTime.now(),
          ),
        );

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Tap Remove
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    // Dialog appears with warnings and info
    expect(find.text('Remove Storage Location'), findsOneWidget);
    expect(
      find.textContaining(
        'Physical video files on your disk will NOT be deleted',
      ),
      findsOneWidget,
    );

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog dismissed and storage remains
    expect(find.text('Remove Storage Location'), findsNothing);
    expect(await db.getStorageById(storageId), isNotNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('Confirming Remove Location removes storage and shows feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storageId = 'ext-usb-confirm';
    await db
        .into(db.storages)
        .insert(
          StoragesCompanion.insert(
            id: storageId,
            name: 'Seagate Expansion',
            storageType: 'REMOVABLE_VOLUME',
            filesystemIdentifier: 'SEAGATE-01',
            rootUri: 'G:\\Films',
            lastSeenAt: DateTime.now(),
          ),
        );

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text('Seagate Expansion'), findsOneWidget);

    // Tap Remove
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    // Tap Remove Location inside dialog
    await tester.tap(find.text('Remove Location'));
    await tester.pumpAndSettle();

    // Dialog dismissed, storage removed from DB and UI
    expect(find.text('Remove Storage Location'), findsNothing);
    expect(await db.getStorageById(storageId), isNull);
    expect(find.text('Seagate Expansion'), findsNothing);
    expect(
      find.text('Storage location "Seagate Expansion" removed.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
