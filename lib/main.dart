import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'core/theme/cinema_theme.dart';
import 'data/database/database.dart';
import 'data/network/tmdb_api_client.dart';
import 'data/platform/local_storage_manager_impl.dart';
import 'data/platform/storage_identity_service_impl.dart';
import 'domain/metadata/image_cache_service.dart';
import 'domain/metadata/metadata_service.dart';
import 'domain/scanner/library_scanner_service.dart';
import 'domain/services/local_storage_manager.dart';
import 'domain/services/settings_service.dart';
import 'domain/services/storage_identity_service.dart';
import 'domain/services/storage_monitor_service.dart';
import 'presentation/shell/cinema_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final StorageIdentityService storageIdentityService =
      StorageIdentityServiceImpl();
  final LocalStorageManager localStorageManager = LocalStorageManagerImpl();

  final localMediaDir = await localStorageManager.getLocalMediaDirectoryPath();
  final settingsService = await SettingsService.load(
    p.join(localMediaDir, 'reelhouse_settings.json'),
  );

  final tmdbClient = TmdbApiClient(apiKey: settingsService.tmdbApiKey);
  settingsService.addListener(() {
    tmdbClient.updateApiKey(settingsService.tmdbApiKey);
  });

  final imageCacheService = ImageCacheService(
    localStorageManager: localStorageManager,
  );

  final metadataService = MetadataService(
    database: database,
    tmdbClient: tmdbClient,
    imageCacheService: imageCacheService,
  );

  final libraryScannerService = LibraryScannerService(
    database: database,
    storageIdentityService: storageIdentityService,
  );
  final storageMonitorService = StorageMonitorService(
    database: database,
    storageIdentityService: storageIdentityService,
  );

  runApp(
    ReelhouseApp(
      database: database,
      storageIdentityService: storageIdentityService,
      localStorageManager: localStorageManager,
      libraryScannerService: libraryScannerService,
      storageMonitorService: storageMonitorService,
      metadataService: metadataService,
      settingsService: settingsService,
    ),
  );
}

class ReelhouseApp extends StatelessWidget {
  final AppDatabase database;
  final StorageIdentityService storageIdentityService;
  final LocalStorageManager localStorageManager;
  final LibraryScannerService? libraryScannerService;
  final StorageMonitorService? storageMonitorService;
  final MetadataService? metadataService;
  final SettingsService? settingsService;

  const ReelhouseApp({
    super.key,
    required this.database,
    required this.storageIdentityService,
    required this.localStorageManager,
    this.libraryScannerService,
    this.storageMonitorService,
    this.metadataService,
    this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REELHOUSE',
      debugShowCheckedModeBanner: false,
      theme: CinemaTheme.darkTheme,
      home: CinemaShell(
        database: database,
        storageIdentityService: storageIdentityService,
        localStorageManager: localStorageManager,
        libraryScannerService: libraryScannerService,
        storageMonitorService: storageMonitorService,
        metadataService: metadataService,
        settingsService: settingsService,
      ),
    );
  }
}
