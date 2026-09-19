import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/domain/services/file_picker_service.dart';
import 'package:reelhouse/domain/services/settings_service.dart';
import 'package:reelhouse/presentation/profile/profile_screen.dart';
import 'package:reelhouse/presentation/widgets/cinema_profile_avatar.dart';

class FakeFilePickerService implements FilePickerService {
  String? imageFileToReturn;

  @override
  Future<String?> pickImageFile({String? dialogTitle}) async =>
      imageFileToReturn;

  @override
  Future<String?> pickBackupFile({String? dialogTitle}) async => null;

  @override
  Future<String?> saveBackupFile({
    String? dialogTitle,
    String? suggestedFileName,
  }) async => null;

  @override
  Future<String?> pickDirectory({String? dialogTitle}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Pure unit tests — no widgets, no stall risk
  // ---------------------------------------------------------------------------

  group('getProfileInitials', () {
    test('single word returns first char uppercased', () {
      expect(getProfileInitials('Christopher'), 'C');
      expect(getProfileInitials('a'), 'A');
    });

    test('two words returns initials of first and last', () {
      expect(getProfileInitials('Prateek Pal'), 'PP');
      expect(getProfileInitials('jane doe'), 'JD');
    });

    test('three+ words returns first and last initial', () {
      expect(getProfileInitials('John Ronald Reuel Tolkien'), 'JT');
    });

    test('empty or whitespace-only returns V', () {
      expect(getProfileInitials(''), 'V');
      expect(getProfileInitials('   '), 'V');
    });
  });

  // ---------------------------------------------------------------------------
  // CinemaProfileAvatar — initials only (no Image.file to avoid async decode
  // contamination that stalls subsequent pumpWidget calls in the same process)
  // ---------------------------------------------------------------------------

  group('CinemaProfileAvatar initials', () {
    testWidgets('renders PP for Prateek Pal', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: const CinemaProfileAvatar(size: 64, displayName: 'Prateek Pal'),
        ),
      );
      await tester.pump();

      expect(find.text('PP'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('renders V for empty displayName', (tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: const CinemaProfileAvatar(size: 64, displayName: ''),
        ),
      );
      await tester.pump();

      expect(find.text('V'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  // ---------------------------------------------------------------------------
  // ProfileScreen widget tests
  // ---------------------------------------------------------------------------

  group('ProfileScreen', () {
    late Directory tempDir;
    late String settingsPath;
    late SettingsService settingsService;
    late FakeFilePickerService fakePicker;

    setUp(() async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      tempDir = await Directory.systemTemp.createTemp('profile_screen_test_');
      settingsPath = p.join(tempDir.path, 'settings.json');
      settingsService = await SettingsService.load(settingsPath);
      fakePicker = FakeFilePickerService();
    });

    tearDown(() async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets('renders display name and initials avatar', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setUserDisplayName('Christopher Nolan');

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: ProfileScreen(
            settingsService: settingsService,
            filePickerService: fakePicker,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('Personal Profile'), findsOneWidget);
      expect(find.text('CN'), findsNWidgets(2));
      expect(find.text('Local Profile Privacy'), findsOneWidget);
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller?.text, 'Christopher Nolan');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('saves a valid display name and shows snackbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setUserDisplayName('Alice');

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: ProfileScreen(
            settingsService: settingsService,
            filePickerService: fakePicker,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Bob Builder');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();

      expect(settingsService.userDisplayName, 'Bob Builder');
      expect(find.text('Display name updated.'), findsOneWidget);
      expect(find.text('BB'), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('shows validation error for empty display name', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await settingsService.setUserDisplayName('Alice');

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: ProfileScreen(
            settingsService: settingsService,
            filePickerService: fakePicker,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();

      expect(find.text('Display Name cannot be empty.'), findsOneWidget);
      expect(settingsService.userDisplayName, 'Alice');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('picks and persists a profile picture path', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final imagePath = p.join(tempDir.path, 'avatar.jpg');
      File(imagePath).writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
      fakePicker.imageFileToReturn = imagePath;

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: ProfileScreen(
            settingsService: settingsService,
            filePickerService: fakePicker,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Choose Picture'));
      await tester.pump();

      expect(settingsService.userProfilePicturePath, imagePath);
      expect(find.text('Profile picture updated.'), findsOneWidget);
      expect(find.text('Change Picture'), findsOneWidget);
      expect(find.text('Remove Picture'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('removes profile picture and reverts to initials avatar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final imagePath = p.join(tempDir.path, 'avatar.jpg');
      File(imagePath).writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
      await settingsService.setUserProfilePicturePath(imagePath);
      await settingsService.setUserDisplayName('David Fincher');

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: ProfileScreen(
            settingsService: settingsService,
            filePickerService: fakePicker,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Remove Picture'));
      await tester.pump();

      expect(settingsService.userProfilePicturePath, isNull);
      expect(find.text('Profile picture removed.'), findsOneWidget);
      expect(find.text('DF'), findsNWidgets(2));
      expect(find.text('Choose Picture'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('reactively updates when SettingsService changes externally', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: ProfileScreen(
            settingsService: settingsService,
            filePickerService: fakePicker,
          ),
        ),
      );
      await tester.pump();

      // Default "Viewer" state
      expect(find.text('V'), findsNWidgets(2));

      await settingsService.setUserDisplayName('George Lucas');
      await tester.pump();

      expect(find.text('GL'), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
