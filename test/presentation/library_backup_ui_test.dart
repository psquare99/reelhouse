import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/network/tmdb_api_client.dart';
import 'package:reelhouse/data/services/library_backup_service_impl.dart';
import 'package:reelhouse/domain/metadata/image_cache_service.dart';
import 'package:reelhouse/domain/metadata/metadata_matcher.dart';
import 'package:reelhouse/domain/metadata/metadata_service.dart';
import 'package:reelhouse/domain/models/library_backup_models.dart';
import 'package:reelhouse/domain/services/file_picker_service.dart';
import 'package:reelhouse/domain/services/library_backup_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/domain/services/settings_service.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/presentation/settings/settings_screen.dart';

class MockStorageIdentityService implements StorageIdentityService {
  bool isConnectedResult = true;
  String displayNameResult = 'Mock Storage';

  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'mock-fs-id';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      displayNameResult;

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async =>
      isConnectedResult;

  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;

  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {}
}

class MockLocalStorageManager implements LocalStorageManager {
  @override
  Future<String> getLocalMediaDirectoryPath() async => '/mock/media';

  @override
  Future<int> getAvailableDeviceStorageBytes() async => 64 * 1024 * 1024 * 1024;

  @override
  Future<int> getTotalDeviceStorageBytes() async => 128 * 1024 * 1024 * 1024;

  @override
  Future<int> getUsedOfflineStorageBytes() async => 1 * 1024 * 1024 * 1024;

  @override
  Future<String> resolveLocalPath(String relativePath) async =>
      '/mock/media/$relativePath';

  @override
  Future<bool> verifyLocalCopyIntegrity(
    String relativePath,
    int expectedBytes,
  ) async => true;

  @override
  Future<bool> deleteLocalCopy(String relativePath) async => true;
}

class FakeFilePickerService implements FilePickerService {
  String? directoryToReturn;
  String? backupFileToReturn;
  String? saveFileToReturn;
  bool pickDirectoryCalled = false;
  bool pickBackupFileCalled = false;
  bool saveBackupFileCalled = false;

  FakeFilePickerService({
    this.directoryToReturn,
    this.backupFileToReturn,
    this.saveFileToReturn,
  });

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async {
    pickDirectoryCalled = true;
    return directoryToReturn;
  }

  @override
  Future<String?> pickBackupFile({String? dialogTitle}) async {
    pickBackupFileCalled = true;
    return backupFileToReturn;
  }

  @override
  Future<String?> saveBackupFile({
    String? dialogTitle,
    String? suggestedFileName,
  }) async {
    saveBackupFileCalled = true;
    return saveFileToReturn;
  }
}

class FakeLibraryBackupService implements LibraryBackupService {
  final BackupSummary? summaryToReturn;
  final BackupImportResult? importResultToReturn;
  final String exportedPathToReturn;
  final bool shouldThrowOnInspect;
  String? lastExportedPath;
  String? lastImportedPath;

  FakeLibraryBackupService({
    this.summaryToReturn,
    this.importResultToReturn,
    this.exportedPathToReturn = '/fake/export.json',
    this.shouldThrowOnInspect = false,
  });

  @override
  Future<LibraryBackupPayload> createBackupPayload() async =>
      throw UnimplementedError();

  @override
  Future<String> exportBackupToFile(String targetFilePath) async {
    lastExportedPath = targetFilePath;
    return exportedPathToReturn;
  }

  @override
  Future<BackupSummary> inspectBackupFile(String filePath) async {
    lastImportedPath = filePath;
    if (shouldThrowOnInspect) {
      throw const FormatException('Invalid JSON payload structure');
    }
    return summaryToReturn ??
        BackupSummary(
          formatVersion: 1,
          appVersion: '1.0.0',
          schemaVersion: 6,
          exportedAt: DateTime.now(),
          movieCount: 1,
          tvShowCount: 0,
          seasonCount: 0,
          episodeCount: 0,
          collectionCount: 0,
          hasSettings: false,
        );
  }

  @override
  Future<BackupSummary> inspectBackupJson(String jsonContent) async =>
      inspectBackupFile('');

  @override
  Future<BackupImportResult> importBackupFromFile(String filePath) async {
    lastImportedPath = filePath;
    return importResultToReturn ??
        const BackupImportResult(
          success: true,
          moviesImported: 1,
          showsImported: 0,
          seasonsImported: 0,
          episodesImported: 0,
          collectionsImported: 0,
        );
  }

  @override
  Future<BackupImportResult> importBackupPayload(
    LibraryBackupPayload payload,
  ) async => importResultToReturn ?? const BackupImportResult(success: true);
}

void main() {
  late AppDatabase db;
  late MetadataService metadataService;
  late SettingsService settingsService;
  late LibraryBackupService backupService;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('reelhouse_ui_backup_');
    metadataService = MetadataService(
      database: db,
      tmdbClient: TmdbApiClient(apiKey: 'test_key'),
      matcher: const MetadataMatcher(),
      imageCacheService: ImageCacheService(
        localStorageManager: MockLocalStorageManager(),
      ),
    );
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
  });

  testWidgets(
    'SettingsScreen renders LIBRARY BACKUP & RESTORE section and opens Export dialog',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            database: db,
            storageIdentityService: MockStorageIdentityService(),
            localStorageManager: MockLocalStorageManager(),
            metadataService: metadataService,
            settingsService: settingsService,
            libraryBackupService: backupService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll down to reveal Backup & Restore section
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final exportBtnFinder = find.widgetWithText(
        ElevatedButton,
        'Export Library',
      );
      final importBtnFinder = find.widgetWithText(
        OutlinedButton,
        'Import Library',
      );
      expect(find.text('LIBRARY BACKUP & RESTORE'), findsOneWidget);
      expect(find.text('Backup & Portability'), findsOneWidget);
      expect(exportBtnFinder, findsOneWidget);
      expect(importBtnFinder, findsOneWidget);

      // Tap Export Library to trigger dialog
      await tester.tap(exportBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ExportBackupDialog), findsOneWidget);
      expect(find.text('Export Library Backup'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Unmount cleanly
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'ExportBackupDialog opens picker, selects destination, and exports library',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final exportPath = '${tempDir.path}/reelhouse_backup.json';
      final fakePicker = FakeFilePickerService(saveFileToReturn: exportPath);
      final fakeBackup = FakeLibraryBackupService(
        exportedPathToReturn: exportPath,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => ExportBackupDialog(
                    libraryBackupService: fakeBackup,
                    filePickerService: fakePicker,
                  ),
                ),
                child: const Text('Open Export Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Export Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Export Library Backup'), findsOneWidget);
      expect(find.text('Choose where to save your backup.'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Choose Save Location'),
        findsOneWidget,
      );

      // Tap Choose Save Location
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Choose Save Location'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakePicker.saveBackupFileCalled, isTrue);
      expect(find.text(exportPath), findsOneWidget);

      // Tap Export Backup
      await tester.tap(find.widgetWithText(ElevatedButton, 'Export Backup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeBackup.lastExportedPath, equals(exportPath));
    },
  );

  testWidgets(
    'ExportBackupDialog cancellation does not export and does not display error',
    (WidgetTester tester) async {
      final fakePicker = FakeFilePickerService(saveFileToReturn: null);
      final fakeBackup = FakeLibraryBackupService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => ExportBackupDialog(
                    libraryBackupService: fakeBackup,
                    filePickerService: fakePicker,
                  ),
                ),
                child: const Text('Open Export Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Export Dialog'));
      await tester.pump();

      // Tap Choose Save Location and cancel picker
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Choose Save Location'),
      );
      await tester.pump();

      expect(fakePicker.saveBackupFileCalled, isTrue);
      expect(fakeBackup.lastExportedPath, isNull);
      expect(find.textContaining('failed'), findsNothing);
    },
  );

  testWidgets(
    'ImportBackupDialog selects backup file, inspects summary, and restores library',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final importPath = '${tempDir.path}/sample_backup.json';
      final fakePicker = FakeFilePickerService(backupFileToReturn: importPath);
      final fakeBackup = FakeLibraryBackupService(
        summaryToReturn: BackupSummary(
          formatVersion: 1,
          appVersion: '1.0.0',
          schemaVersion: 6,
          exportedAt: DateTime.now(),
          movieCount: 3,
          tvShowCount: 1,
          seasonCount: 2,
          episodeCount: 10,
          collectionCount: 2,
          hasSettings: false,
        ),
        importResultToReturn: const BackupImportResult(
          success: true,
          moviesImported: 3,
          moviesUpdated: 0,
          showsImported: 1,
          showsUpdated: 0,
          seasonsImported: 2,
          episodesImported: 10,
          episodesUpdated: 0,
          collectionsImported: 2,
          collectionsUpdated: 0,
          settingsImported: false,
        ),
      );

      bool successNotified = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => ImportBackupDialog(
                    libraryBackupService: fakeBackup,
                    filePickerService: fakePicker,
                    onImportSuccess: () {
                      successNotified = true;
                    },
                  ),
                ),
                child: const Text('Open Import Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Import Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Import Library Backup'), findsOneWidget);
      expect(
        find.text('Select a REELHOUSE backup to restore.'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Choose Backup'),
        findsOneWidget,
      );

      // Tap Choose Backup
      await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Backup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakePicker.pickBackupFileCalled, isTrue);
      expect(fakeBackup.lastImportedPath, equals(importPath));
      expect(find.text(importPath), findsOneWidget);
      expect(find.textContaining('3 Movies'), findsOneWidget);
      expect(find.textContaining('1 TV Shows'), findsOneWidget);

      // Tap Restore Library
      await tester.tap(find.widgetWithText(ElevatedButton, 'Restore Library'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Import complete dialog
      expect(find.text('Import Complete'), findsOneWidget);
      expect(find.textContaining('3 new movies added'), findsOneWidget);
      expect(successNotified, isTrue);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets(
    'ImportBackupDialog handles picker cancellation and corrupt backup inspection failure',
    (WidgetTester tester) async {
      final fakePicker = FakeFilePickerService(backupFileToReturn: null);
      final fakeBackup = FakeLibraryBackupService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => ImportBackupDialog(
                    libraryBackupService: fakeBackup,
                    filePickerService: fakePicker,
                    onImportSuccess: () {},
                  ),
                ),
                child: const Text('Open Import Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Import Dialog'));
      await tester.pump();

      // Tap Choose Backup and cancel
      await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Backup'));
      await tester.pump();

      expect(fakePicker.pickBackupFileCalled, isTrue);
      expect(fakeBackup.lastImportedPath, isNull);
      expect(fakePicker.pickBackupFileCalled, isTrue);
      expect(fakeBackup.lastImportedPath, isNull);
      expect(find.textContaining('Failed to inspect'), findsNothing);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Now set corrupt file and re-trigger
      fakePicker.backupFileToReturn = '/bad/corrupt.json';
      final corruptBackup = FakeLibraryBackupService(
        shouldThrowOnInspect: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => ImportBackupDialog(
                    libraryBackupService: corruptBackup,
                    filePickerService: fakePicker,
                    onImportSuccess: () {},
                  ),
                ),
                child: const Text('Open Import Dialog 2'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Import Dialog 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Backup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Failed to inspect backup:'), findsOneWidget);
    },
  );

  testWidgets(
    'AddStorageDialog selects folder, creates storage, and deduplicates existing storage',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakePicker = FakeFilePickerService(directoryToReturn: 'D:\\Movies');
      final mockIdentity = MockStorageIdentityService();
      bool addedNotified = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => AddStorageDialog(
                    database: db,
                    storageIdentityService: mockIdentity,
                    filePickerService: fakePicker,
                    onStorageAdded: () {
                      addedNotified = true;
                    },
                  ),
                ),
                child: const Text('Open Storage Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Storage Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Add Storage Location'), findsOneWidget);
      expect(
        find.text('Choose the folder containing your media library.'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Choose Folder'),
        findsOneWidget,
      );

      // Tap Choose Folder
      await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakePicker.pickDirectoryCalled, isTrue);
      expect(find.text('D:\\Movies'), findsOneWidget);
      expect(find.text('Mock Storage'), findsOneWidget);

      // Tap Add Storage
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Storage'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(addedNotified, isTrue);

      final storages = (await db.getAllStorages())
          .where((s) => s.storageType != 'DEVICE_LOCAL_STORAGE')
          .toList();
      expect(storages.length, equals(1));
      expect(storages.first.rootUri, equals('D:\\Movies'));
      expect(storages.first.name, equals('Mock Storage'));
      expect(storages.first.filesystemIdentifier, equals('mock-fs-id'));

      // Test deduplication: re-adding same folder does not create duplicate storage record
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => AddStorageDialog(
                    database: db,
                    storageIdentityService: mockIdentity,
                    filePickerService: fakePicker,
                  ),
                ),
                child: const Text('Open Storage Dialog 2'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Storage Dialog 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Storage'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final deduplicatedStorages = (await db.getAllStorages())
          .where((s) => s.storageType != 'DEVICE_LOCAL_STORAGE')
          .toList();
      expect(deduplicatedStorages.length, equals(1));
    },
  );

  testWidgets(
    'AddStorageDialog handles cancellation and inaccessible directory cleanly',
    (WidgetTester tester) async {
      final fakePicker = FakeFilePickerService(directoryToReturn: null);
      final mockIdentity = MockStorageIdentityService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => AddStorageDialog(
                    database: db,
                    storageIdentityService: mockIdentity,
                    filePickerService: fakePicker,
                  ),
                ),
                child: const Text('Open Storage Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Open Storage Dialog'));
      await tester.pump();

      // Tap Choose Folder and cancel
      await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Folder'));
      await tester.pump();

      expect(fakePicker.pickDirectoryCalled, isTrue);
      final removableStorages = (await db.getAllStorages())
          .where((s) => s.storageType != 'DEVICE_LOCAL_STORAGE')
          .toList();
      expect(removableStorages, isEmpty);
      expect(find.textContaining('inaccessible'), findsNothing);

      // Now set inaccessible directory
      fakePicker.directoryToReturn = 'E:\\Inaccessible';
      mockIdentity.isConnectedResult = false;

      await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Folder'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.textContaining('Selected directory is inaccessible'),
        findsOneWidget,
      );
    },
  );
}
