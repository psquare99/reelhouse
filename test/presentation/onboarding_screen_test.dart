import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/network/tmdb_api_client.dart';
import 'package:reelhouse/data/network/tmdb_models.dart';
import 'package:reelhouse/domain/metadata/image_cache_service.dart';
import 'package:reelhouse/domain/metadata/metadata_service.dart';
import 'package:reelhouse/domain/services/file_picker_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/domain/services/settings_service.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/presentation/onboarding/onboarding_screen.dart';
import 'package:reelhouse/presentation/widgets/library_backup_dialogs.dart';

class MockStorageIdentityService implements StorageIdentityService {
  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async => 'fs-1';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      'Mock Drive';

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

class FakeFilePickerService implements FilePickerService {
  String? imageFileToReturn;
  String? backupFileToReturn;
  String? saveFileToReturn;
  String? directoryToReturn;

  @override
  Future<String?> pickImageFile({String? dialogTitle}) async =>
      imageFileToReturn;

  @override
  Future<String?> pickBackupFile({String? dialogTitle}) async =>
      backupFileToReturn;

  @override
  Future<String?> saveBackupFile({
    String? dialogTitle,
    String? suggestedFileName,
  }) async => saveFileToReturn;

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async =>
      directoryToReturn;
}

class MockTmdbApiClient extends TmdbApiClient {
  bool shouldValidateSuccessfully = true;

  MockTmdbApiClient() : super(apiKey: 'dummy_key');

  @override
  Future<TmdbAuthValidationResult> validateAuthentication([
    String? candidateKey,
  ]) async {
    if (shouldValidateSuccessfully) {
      return const TmdbAuthValidationResult(
        status: TmdbAuthStatus.connected,
        message: 'TMDB connection successful.',
        statusCode: 200,
      );
    }
    return const TmdbAuthValidationResult(
      status: TmdbAuthStatus.invalidKey,
      message: 'Invalid TMDB API Key.',
      statusCode: 401,
    );
  }

  @override
  Future<List<TmdbMovieSearchResult>> searchMovies(
    String query, {
    int? year,
  }) async {
    if (shouldValidateSuccessfully) {
      return [
        const TmdbMovieSearchResult(
          id: 27205,
          title: 'Inception',
          overview: 'A thief who steals corporate secrets...',
          releaseDate: '2010-07-15',
        ),
      ];
    }
    return [];
  }
}

void main() {
  late Directory tempDir;
  late String settingsPath;
  late AppDatabase database;
  late SettingsService settingsService;
  late StorageIdentityService storageIdentityService;
  late LocalStorageManager localStorageManager;
  late FakeFilePickerService fakeFilePickerService;
  late MockTmdbApiClient mockTmdbClient;
  late MetadataService metadataService;

  setUp(() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    tempDir = await Directory.systemTemp.createTemp(
      'reelhouse_onboarding_ui_test_',
    );
    settingsPath = p.join(tempDir.path, 'settings.json');
    database = AppDatabase(NativeDatabase.memory());
    settingsService = await SettingsService.load(settingsPath);
    storageIdentityService = MockStorageIdentityService();
    localStorageManager = MockLocalStorageManager();
    fakeFilePickerService = FakeFilePickerService();
    mockTmdbClient = MockTmdbApiClient();
    metadataService = MetadataService(
      database: database,
      tmdbClient: mockTmdbClient,
      imageCacheService: ImageCacheService(
        localStorageManager: localStorageManager,
      ),
    );
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestWidget({VoidCallback? onComplete}) {
    return MaterialApp(
      theme: CinemaTheme.darkTheme,
      home: OnboardingScreen(
        database: database,
        storageIdentityService: storageIdentityService,
        localStorageManager: localStorageManager,
        settingsService: settingsService,
        filePickerService: fakeFilePickerService,
        metadataService: metadataService,
        onComplete: onComplete,
      ),
    );
  }

  group('Onboarding Flow UI Tests', () {
    testWidgets('Step 1: Displays Welcome Screen and advances to Step 2', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to MATINEE'), findsOneWidget);
      expect(find.text('Your personal digital cinema.'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should now be on Step 2 (Profile Setup)
      expect(find.text('Your Profile'), findsOneWidget);
      expect(find.text('How should MATINEE greet you?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets(
      'Step 2: Profile validation, avatar selection, and step transition',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Go to Step 2
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Clear display name and try to continue -> should show validation error
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        expect(find.text('Display Name is required.'), findsOneWidget);

        // Select avatar image via fake file picker
        fakeFilePickerService.imageFileToReturn = 'C:/photos/my_avatar.png';
        await tester.tap(find.text('Add Photo'));
        await tester.pump();

        expect(find.text('Remove'), findsOneWidget);

        // Enter valid display name and continue
        await tester.enterText(find.byType(TextField), 'Christopher Nolan');
        await tester.pump();

        await tester.tap(find.text('Continue'));
        await tester.pump();
        await tester.pump();

        // Verify settings persisted
        expect(settingsService.userDisplayName, equals('Christopher Nolan'));
        expect(
          settingsService.userProfilePicturePath,
          equals('C:/photos/my_avatar.png'),
        );

        // Should now be on Step 3 (TMDB)
        expect(find.text('Connect MATINEE to TMDB'), findsOneWidget);
      },
    );

    testWidgets('Step 3: TMDB test connection and skip flow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.enterText(find.byType(TextField), 'Viewer');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Connect MATINEE to TMDB'), findsOneWidget);
      expect(find.text('I Have an API Key'), findsOneWidget);
      expect(find.text('Skip for Now'), findsOneWidget);

      // Advance to Step 4 via Skip for Now
      await tester.tap(find.text('Skip for Now'));
      await tester.pumpAndSettle();

      // Should now be on Step 4 (Library Setup)
      expect(find.text('Your Library'), findsOneWidget);
      expect(
        find.text('Start a New Library'),
        findsNWidgets(2),
      ); // Card title + button
      expect(find.text('Import Existing Library'), findsOneWidget);
    });

    testWidgets('Step 3: Entering valid TMDB key validates and saves key', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.enterText(find.byType(TextField), 'Viewer');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Reveal input
      await tester.tap(find.text('I Have an API Key'));
      await tester.pumpAndSettle();

      // Enter key
      await tester.enterText(find.byType(TextField), 'my-valid-api-key');
      await tester.pumpAndSettle();

      // Test & Save
      await tester.tap(find.text('Test & Save'));
      await tester.pumpAndSettle();

      expect(find.text('TMDB connection successful.'), findsOneWidget);
      expect(settingsService.tmdbApiKey, equals('my-valid-api-key'));
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Step 4: Start a New Library completes onboarding', (
      tester,
    ) async {
      bool completed = false;
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(
        buildTestWidget(
          onComplete: () {
            completed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.enterText(find.byType(TextField), 'Quentin');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3 -> Step 4
      await tester.tap(find.text('Skip for Now'));
      await tester.pumpAndSettle();

      expect(settingsService.isOnboardingCompleted, isFalse);

      // Click "Start a New Library" button (elevated button)
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Start a New Library'),
      );
      await tester.pumpAndSettle();

      expect(settingsService.isOnboardingCompleted, isTrue);
      expect(completed, isTrue);
    });

    testWidgets('Step 4: Import Existing Library opens ImportBackupDialog', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.enterText(find.byType(TextField), 'Stanley');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3 -> Step 4
      await tester.tap(find.text('Skip for Now'));
      await tester.pumpAndSettle();

      // Click "Import Backup File"
      await tester.tap(find.text('Import Backup File'));
      await tester.pumpAndSettle();

      // Expect ImportBackupDialog to appear
      expect(find.byType(ImportBackupDialog), findsOneWidget);
      expect(find.text('Import Library Backup'), findsOneWidget);
    });
  });
}
