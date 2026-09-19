import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/services/library_backup_service_impl.dart';
import 'package:reelhouse/domain/services/settings_service.dart';

void main() {
  late Directory tempDir;
  late String settingsPath;
  late AppDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'reelhouse_onboarding_test_',
    );
    settingsPath = p.join(tempDir.path, 'settings.json');
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Onboarding and Profile Settings Persistence', () {
    test('defaults to onboarding not completed with empty profile', () async {
      final settings = await SettingsService.load(settingsPath);
      expect(settings.isOnboardingCompleted, isFalse);
      expect(settings.userDisplayName, isEmpty);
      expect(settings.userProfilePicturePath, isNull);
    });

    test(
      'persists onboarding completion, display name, and avatar across reloads',
      () async {
        final settings = await SettingsService.load(settingsPath);
        await settings.setUserDisplayName('Stanley Kubrick');
        await settings.setUserProfilePicturePath('C:/avatars/kubrick.png');
        await settings.setOnboardingCompleted(true);

        expect(settings.isOnboardingCompleted, isTrue);
        expect(settings.userDisplayName, equals('Stanley Kubrick'));
        expect(
          settings.userProfilePicturePath,
          equals('C:/avatars/kubrick.png'),
        );

        // Reload fresh instance from disk
        final reloaded = await SettingsService.load(settingsPath);
        expect(reloaded.isOnboardingCompleted, isTrue);
        expect(reloaded.userDisplayName, equals('Stanley Kubrick'));
        expect(
          reloaded.userProfilePicturePath,
          equals('C:/avatars/kubrick.png'),
        );
      },
    );

    test(
      'exports and restores profile details in LibraryBackupService',
      () async {
        final settings = await SettingsService.load(settingsPath);
        await settings.setUserDisplayName('Akira Kurosawa');
        await settings.setUserProfilePicturePath('C:/photos/kurosawa.jpg');
        await settings.setOnboardingCompleted(true);

        final backupService = LibraryBackupServiceImpl(
          database: database,
          settingsService: settings,
        );

        final payload = await backupService.createBackupPayload();
        expect(payload.settings?.userDisplayName, equals('Akira Kurosawa'));
        expect(
          payload.settings?.userProfilePicturePath,
          equals('C:/photos/kurosawa.jpg'),
        );

        // Reset settings
        await settings.setUserDisplayName('Default');
        await settings.setUserProfilePicturePath(null);

        // Restore payload
        final result = await backupService.importBackupPayload(payload);
        expect(result.success, isTrue);
        expect(settings.userDisplayName, equals('Akira Kurosawa'));
        expect(
          settings.userProfilePicturePath,
          equals('C:/photos/kurosawa.jpg'),
        );
      },
    );
  });
}
