import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'core/theme/cinema_theme.dart';
import 'data/database/database.dart';
import 'data/network/tmdb_api_client.dart';
import 'data/platform/local_storage_manager_impl.dart';
import 'data/platform/storage_identity_service_impl.dart';
import 'data/repository/drift_library_repository.dart';
import 'domain/metadata/image_cache_service.dart';
import 'domain/metadata/metadata_service.dart';
import 'domain/repository/library_repository.dart';
import 'domain/scanner/library_scanner_service.dart';
import 'domain/services/local_storage_manager.dart';
import 'domain/services/settings_service.dart';
import 'domain/services/storage_identity_service.dart';
import 'domain/services/storage_monitor_service.dart';
import 'presentation/shell/cinema_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final LibraryRepository libraryRepository = DriftLibraryRepository(database);
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
      libraryRepository: libraryRepository,
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
  final LibraryRepository libraryRepository;
  final StorageIdentityService storageIdentityService;
  final LocalStorageManager localStorageManager;
  final LibraryScannerService? libraryScannerService;
  final StorageMonitorService? storageMonitorService;
  final MetadataService? metadataService;
  final SettingsService? settingsService;

  ReelhouseApp({
    super.key,
    required this.database,
    LibraryRepository? libraryRepository,
    required this.storageIdentityService,
    required this.localStorageManager,
    this.libraryScannerService,
    this.storageMonitorService,
    this.metadataService,
    this.settingsService,
  }) : libraryRepository =
           libraryRepository ?? DriftLibraryRepository(database);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = settingsService ?? ChangeNotifier();
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        final currentMode = settingsService?.themeMode ?? ThemeMode.dark;
        return MaterialApp(
          title: 'REELHOUSE',
          debugShowCheckedModeBanner: false,
          theme: CinemaTheme.lightTheme,
          darkTheme: CinemaTheme.darkTheme,
          themeMode: currentMode,
          home: CinemaShell(
            database: database,
            repository: libraryRepository,
            storageIdentityService: storageIdentityService,
            localStorageManager: localStorageManager,
            libraryScannerService: libraryScannerService,
            storageMonitorService: storageMonitorService,
            metadataService: metadataService,
            settingsService: settingsService,
          ),
        );
      },
    );
  }
}
