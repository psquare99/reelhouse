import 'dart:io';

import '../../data/database/database.dart';
import '../../data/platform/android_storage_adapter.dart';
import '../../data/platform/platform_storage_adapter.dart';
import '../../data/platform/storage_identity_service_impl.dart';
import '../../data/platform/windows_storage_adapter.dart';
import 'settings_service.dart';

/// Diagnostic outcome status for a playback launch attempt.
enum PlaybackStatus {
  /// External player was successfully launched.
  success,

  /// The requested media source record is missing from the database.
  sourceNotFound,

  /// The physical storage disk is not connected or not mounted.
  storageDisconnected,

  /// The physical media file does not exist on disk at the resolved path.
  fileNotFound,

  /// The user's preferred player (e.g. VLC) was not found on the system.
  playerNotFound,

  /// Operating system process launch failed.
  launchFailed,

  /// External player launch is not supported on this platform.
  unsupportedPlatform,
}

/// Rich diagnostic information returned from a playback launch attempt.
class PlaybackLaunchResult {
  final PlaybackStatus status;
  final bool isSuccess;
  final String? resolvedPath;
  final String? playerUsed;
  final String? commandOrIntent;
  final String? errorMessage;

  const PlaybackLaunchResult({
    required this.status,
    required this.isSuccess,
    this.resolvedPath,
    this.playerUsed,
    this.commandOrIntent,
    this.errorMessage,
  });

  @override
  String toString() =>
      'PlaybackLaunchResult(status: $status, success: $isSuccess, path: $resolvedPath, player: $playerUsed, error: $errorMessage)';
}

/// Orchestrates playback handoff from UI to external platform media players.
///
/// Traces the complete playback lifecycle:
/// 1. Retrieve MediaSource and parent Storage from database.
/// 2. Verify storage connectivity via [PlatformStorageAdapter].
/// 3. Resolve physical path and verify file existence on disk.
/// 4. Resolve configured player preference from [SettingsService].
/// 5. Launch detached process (Windows) or prepare Intent handoff (Android).
class PlaybackLauncherService {
  final AppDatabase database;
  final PlatformStorageAdapter storageAdapter;
  final SettingsService? settingsService;
  final Future<Process> Function(
    String executable,
    List<String> arguments, {
    ProcessStartMode mode,
  })?
  processStarter;

  PlaybackLauncherService({
    required this.database,
    PlatformStorageAdapter? storageAdapter,
    this.settingsService,
    this.processStarter,
  }) : storageAdapter = storageAdapter ?? _createDefaultAdapter();

  static PlatformStorageAdapter _createDefaultAdapter() {
    try {
      if (Platform.isWindows) {
        return WindowsStorageAdapter();
      } else if (Platform.isAndroid) {
        return AndroidStorageAdapter();
      }
    } catch (_) {}
    return GenericStorageAdapter();
  }

  /// Initiates external player playback for a given [mediaSourceId].
  Future<PlaybackLaunchResult> launchPlayback({
    required String mediaSourceId,
  }) async {
    // 1. Fetch MediaSource from database
    final source = await database.getMediaSourceById(mediaSourceId);
    if (source == null) {
      return const PlaybackLaunchResult(
        status: PlaybackStatus.sourceNotFound,
        isSuccess: false,
        errorMessage: 'Media source record not found in cinema catalogue.',
      );
    }

    // 2. Fetch Storage
    final storage = await database.getStorageById(source.storageId);
    if (storage == null) {
      return const PlaybackLaunchResult(
        status: PlaybackStatus.storageDisconnected,
        isSuccess: false,
        errorMessage: 'Storage location record not found.',
      );
    }

    // 3. Verify Storage is connected
    final isConnected = await storageAdapter.isStorageConnected(
      storage.rootUri,
    );
    if (!isConnected) {
      return PlaybackLaunchResult(
        status: PlaybackStatus.storageDisconnected,
        isSuccess: false,
        errorMessage:
            'Storage disk "${storage.name}" is currently disconnected.',
      );
    }

    // 4. Resolve physical path / URI
    final resolvedPath = await storageAdapter.resolvePlaybackUri(
      storage.rootUri,
      source.relativePath,
    );

    // 5. Verify physical file exists on disk
    final exists = await storageAdapter.fileExists(
      storage.rootUri,
      source.relativePath,
    );
    if (!exists) {
      return PlaybackLaunchResult(
        status: PlaybackStatus.fileNotFound,
        isSuccess: false,
        resolvedPath: resolvedPath,
        errorMessage:
            'Media file does not exist on disk at path:\n$resolvedPath',
      );
    }

    // 6. Platform external player handoff
    final playerPref = settingsService?.preferredPlayer ?? 'vlc';

    if (Platform.isWindows) {
      return _launchWindows(resolvedPath, playerPref);
    } else if (Platform.isAndroid) {
      return _diagnoseAndroid(resolvedPath, playerPref);
    } else {
      return PlaybackLaunchResult(
        status: PlaybackStatus.unsupportedPlatform,
        isSuccess: false,
        resolvedPath: resolvedPath,
        errorMessage:
            'External player launching is not supported on this platform.',
      );
    }
  }

  Future<PlaybackLaunchResult> _launchWindows(
    String filePath,
    String playerPref,
  ) async {
    try {
      final starter = processStarter ?? Process.start;

      if (playerPref == 'vlc') {
        final candidatePaths = [
          r'C:\Program Files\VideoLAN\VLC\vlc.exe',
          r'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe',
        ];

        String? vlcExecutable;
        for (final path in candidatePaths) {
          if (File(path).existsSync()) {
            vlcExecutable = path;
            break;
          }
        }

        if (vlcExecutable != null) {
          await starter(vlcExecutable, [
            filePath,
          ], mode: ProcessStartMode.detached);
          return PlaybackLaunchResult(
            status: PlaybackStatus.success,
            isSuccess: true,
            resolvedPath: filePath,
            playerUsed: 'VLC Media Player',
            commandOrIntent: '$vlcExecutable "$filePath"',
          );
        } else {
          // VLC not in standard directory, attempt launch by system PATH
          try {
            await starter('vlc', [filePath], mode: ProcessStartMode.detached);
            return PlaybackLaunchResult(
              status: PlaybackStatus.success,
              isSuccess: true,
              resolvedPath: filePath,
              playerUsed: 'VLC Media Player (PATH)',
              commandOrIntent: 'vlc "$filePath"',
            );
          } catch (_) {
            return PlaybackLaunchResult(
              status: PlaybackStatus.playerNotFound,
              isSuccess: false,
              resolvedPath: filePath,
              errorMessage:
                  'VLC Media Player was not found on this system.\n\n'
                  'Please install VLC Media Player or switch your player preference to '
                  '"System Default Player" in REELHOUSE Settings.',
            );
          }
        }
      } else {
        // System default player handoff via cmd.exe start
        await starter('cmd.exe', [
          '/c',
          'start',
          '',
          filePath,
        ], mode: ProcessStartMode.detached);
        return PlaybackLaunchResult(
          status: PlaybackStatus.success,
          isSuccess: true,
          resolvedPath: filePath,
          playerUsed: 'System Default Player',
          commandOrIntent: 'cmd.exe /c start "" "$filePath"',
        );
      }
    } catch (e) {
      return PlaybackLaunchResult(
        status: PlaybackStatus.launchFailed,
        isSuccess: false,
        resolvedPath: filePath,
        errorMessage: 'Failed to launch external player process: $e',
      );
    }
  }

  PlaybackLaunchResult _diagnoseAndroid(String uriOrPath, String playerPref) {
    return PlaybackLaunchResult(
      status: PlaybackStatus.unsupportedPlatform,
      isSuccess: false,
      resolvedPath: uriOrPath,
      errorMessage:
          'Android ACTION_VIEW external player Intent handoff requires native FileProvider '
          'channel implementation scheduled for Milestone 5.',
    );
  }
}
