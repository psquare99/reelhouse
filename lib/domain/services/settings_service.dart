import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Manages application-level user preferences and settings for REELHOUSE.
///
/// Implements persistent settings storage for:
/// - TMDB API key (with environment variable fallback)
/// - Preferred media player handoff preference
/// - Application theme mode (dark, light, system)
class SettingsService extends ChangeNotifier {
  final String settingsFilePath;
  final Map<String, dynamic> _settings = {};

  SettingsService({required this.settingsFilePath});

  /// Loads settings from disk. If no settings file exists yet, initializes with defaults.
  static Future<SettingsService> load(String settingsFilePath) async {
    final service = SettingsService(settingsFilePath: settingsFilePath);
    await service._init();
    return service;
  }

  Future<void> _init() async {
    if (kIsWeb) return;

    try {
      final file = File(settingsFilePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _settings.addAll(data);
      }
    } catch (_) {
      // If parsing fails, proceed with defaults
    }
  }

  Future<void> _save() async {
    if (kIsWeb) return;

    try {
      final file = File(settingsFilePath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(jsonEncode(_settings));
    } catch (_) {
      // Log or ignore disk write failure
    }
  }

  /// TMDB API Key.
  ///
  /// Checks saved user preferences first, then falls back to `TMDB_API_KEY`
  /// environment variable (Section 13, Rule 9).
  String? get tmdbApiKey {
    final saved = _settings['tmdbApiKey'] as String?;
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }

    if (!kIsWeb) {
      final envKey = Platform.environment['TMDB_API_KEY'];
      if (envKey != null && envKey.trim().isNotEmpty) {
        return envKey.trim();
      }
    }

    return null;
  }

  /// Whether a TMDB API Key is currently available.
  bool get hasTmdbApiKey => tmdbApiKey != null && tmdbApiKey!.isNotEmpty;

  /// Updates and saves the TMDB API Key.
  Future<void> setTmdbApiKey(String? key) async {
    final trimmed = key?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _settings.remove('tmdbApiKey');
    } else {
      _settings['tmdbApiKey'] = trimmed;
    }
    await _save();
    notifyListeners();
  }

  /// Preferred media player identifier (e.g. 'vlc' | 'system').
  String get preferredPlayer {
    return _settings['preferredPlayer'] as String? ?? 'vlc';
  }

  /// Updates and saves preferred media player.
  Future<void> setPreferredPlayer(String player) async {
    _settings['preferredPlayer'] = player;
    await _save();
    notifyListeners();
  }

  /// Active theme mode (ThemeMode.dark | ThemeMode.light | ThemeMode.system).
  ThemeMode get themeMode {
    final modeStr = _settings['themeMode'] as String?;
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  /// Updates and persists the active theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        _settings['themeMode'] = 'light';
        break;
      case ThemeMode.system:
        _settings['themeMode'] = 'system';
        break;
      case ThemeMode.dark:
        _settings['themeMode'] = 'dark';
        break;
    }
    await _save();
    notifyListeners();
  }

  /// Whether the desktop navigation rail is collapsed (72px) vs expanded (220px).
  bool get isNavRailCollapsed {
    return _settings['isNavRailCollapsed'] as bool? ?? false;
  }

  /// Updates and persists the navigation rail collapse state.
  Future<void> setNavRailCollapsed(bool collapsed) async {
    _settings['isNavRailCollapsed'] = collapsed;
    await _save();
    notifyListeners();
  }

  /// Whether the user has completed initial first-run onboarding.
  bool get isOnboardingCompleted {
    return _settings['onboardingCompleted'] as bool? ?? false;
  }

  /// Updates and persists the onboarding completed state.
  Future<void> setOnboardingCompleted(bool completed) async {
    _settings['onboardingCompleted'] = completed;
    await _save();
    notifyListeners();
  }

  /// Local user profile display name (e.g. 'Alex' or 'Cinema Room').
  String get userDisplayName {
    return _settings['userDisplayName'] as String? ?? '';
  }

  /// Updates and persists the local user profile display name.
  Future<void> setUserDisplayName(String name) async {
    _settings['userDisplayName'] = name.trim();
    await _save();
    notifyListeners();
  }

  /// Local filesystem path to optional profile picture.
  String? get userProfilePicturePath {
    final path = _settings['userProfilePicturePath'] as String?;
    if (path != null && path.trim().isNotEmpty) {
      return path.trim();
    }
    return null;
  }

  /// Updates and persists the local profile picture path.
  Future<void> setUserProfilePicturePath(String? path) async {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _settings.remove('userProfilePicturePath');
    } else {
      _settings['userProfilePicturePath'] = trimmed;
    }
    await _save();
    notifyListeners();
  }
}
