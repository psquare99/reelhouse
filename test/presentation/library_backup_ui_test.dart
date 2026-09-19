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
import 'package:reelhouse/domain/services/library_backup_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/domain/services/settings_service.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/presentation/settings/settings_screen.dart';

class MockStorageIdentityService implements StorageIdentityService {
  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'mock-fs';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      'Mock Storage';

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

class FakeLibraryBackupService implements LibraryBackupService {
  final BackupSummary? summaryToReturn;
  final BackupImportResult? importResultToReturn;
  final String exportedPathToReturn;
  String? lastExportedPath;
  String? lastImportedPath;

  FakeLibraryBackupService({
    this.summaryToReturn,
    this.importResultToReturn,
    this.exportedPathToReturn = '/fake/export.json',
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
    'ExportBackupDialog renders scope notices and exports library to target path',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeBackup = FakeLibraryBackupService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) =>
                      ExportBackupDialog(libraryBackupService: fakeBackup),
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
      expect(
        find.text(
          'Included: Movies, TV Shows, Episodes, Collections, Watch History, User Preferences',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Excluded: Video files and TMDB API credentials (never exported)',
        ),
        findsOneWidget,
      );

      final exportPath = '${tempDir.path}/direct_export.json';
      final pathField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(pathField, exportPath);
      await tester.pump();

      // Tap Export Backup button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Export Backup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify service was invoked with correct target path
      expect(fakeBackup.lastExportedPath, equals(exportPath));
    },
  );

  testWidgets(
    'ImportBackupDialog inspects backup summary and restores library on confirmation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeBackup = FakeLibraryBackupService(
        summaryToReturn: BackupSummary(
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
        ),
        importResultToReturn: const BackupImportResult(
          success: true,
          moviesImported: 1,
          moviesUpdated: 0,
          showsImported: 0,
          showsUpdated: 0,
          seasonsImported: 0,
          episodesImported: 0,
          episodesUpdated: 0,
          collectionsImported: 0,
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

      final importPath = '${tempDir.path}/sample_import.json';
      final importPathField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(importPathField, importPath);
      await tester.pump();

      // Tap Inspect
      await tester.tap(find.widgetWithText(OutlinedButton, 'Inspect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('1 Movies'), findsOneWidget);
      expect(
        find.textContaining('Notice: Media files are NOT included in backups.'),
        findsOneWidget,
      );

      // Tap Restore Library
      await tester.tap(find.widgetWithText(ElevatedButton, 'Restore Library'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Import complete dialog
      expect(find.text('Import Complete'), findsOneWidget);
      expect(find.textContaining('1 new movies added'), findsOneWidget);
      expect(successNotified, isTrue);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );
}
