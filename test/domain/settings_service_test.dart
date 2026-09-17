import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/domain/services/settings_service.dart';

void main() {
  late Directory tempDir;
  late String settingsPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('reelhouse_settings_test_');
    settingsPath = p.join(tempDir.path, 'settings.json');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('loads defaults and persists TMDB API key, preferred player, and theme mode', () async {
    final settings = await SettingsService.load(settingsPath);

    expect(settings.hasTmdbApiKey, isFalse);
    expect(settings.preferredPlayer, equals('vlc'));
    expect(settings.themeMode, equals(ThemeMode.dark));

    // Update TMDB API key
    await settings.setTmdbApiKey('test_tmdb_key_123');
    expect(settings.hasTmdbApiKey, isTrue);
    expect(settings.tmdbApiKey, equals('test_tmdb_key_123'));

    // Update preferred player
    await settings.setPreferredPlayer('system');
    expect(settings.preferredPlayer, equals('system'));

    // Update theme mode
    await settings.setThemeMode(ThemeMode.light);
    expect(settings.themeMode, equals(ThemeMode.light));

    // Re-load in a separate instance from the persisted file
    final reloaded = await SettingsService.load(settingsPath);
    expect(reloaded.tmdbApiKey, equals('test_tmdb_key_123'));
    expect(reloaded.preferredPlayer, equals('system'));
    expect(reloaded.themeMode, equals(ThemeMode.light));

    // Switch to system mode and verify
    await reloaded.setThemeMode(ThemeMode.system);
    expect(reloaded.themeMode, equals(ThemeMode.system));

    final reloaded2 = await SettingsService.load(settingsPath);
    expect(reloaded2.themeMode, equals(ThemeMode.system));

    // Clear API key
    await reloaded2.setTmdbApiKey(null);
    expect(reloaded2.hasTmdbApiKey, isFalse);
  });
}
