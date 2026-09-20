import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'core/theme/cinema_theme.dart';
import 'data/database/database.dart';
import 'data/network/tmdb_api_client.dart';
import 'data/platform/device_storage_service_impl.dart';
import 'data/platform/local_storage_manager_impl.dart';
import 'data/platform/storage_identity_service_impl.dart';
import 'data/repository/drift_library_repository.dart';
import 'data/services/transfer_service_impl.dart';
import 'domain/metadata/image_cache_service.dart';
import 'domain/metadata/metadata_service.dart';
import 'domain/repository/library_repository.dart';
import 'domain/scanner/library_scanner_service.dart';
import 'domain/services/device_storage_service.dart';
import 'domain/services/local_storage_manager.dart';
import 'domain/services/settings_service.dart';
import 'domain/services/storage_identity_service.dart';
import 'domain/services/storage_monitor_service.dart';
import 'domain/services/transfer_coordinator.dart';
import 'domain/services/transfer_service.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/shell/cinema_shell.dart';
import 'presentation/splash/reelhouse_opening.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final LibraryRepository libraryRepository = DriftLibraryRepository(database);
  final StorageIdentityService storageIdentityService =
      StorageIdentityServiceImpl();
  final LocalStorageManager localStorageManager = LocalStorageManagerImpl();
  final DeviceStorageService deviceStorageService = DeviceStorageServiceImpl(
    database: database,
    localStorageManager: localStorageManager,
  );

  // Ensure default application-managed device storage destination is registered and rootUri is initialized
  await deviceStorageService.ensureDefaultDestinationRegistered();

  final TransferService transferService = TransferServiceImpl(
    database: database,
    deviceStorageService: deviceStorageService,
  );
  final TransferCoordinator transferCoordinator = TransferCoordinator(
    transferService: transferService,
    database: database,
    deviceStorageService: deviceStorageService,
    storageIdentityService: storageIdentityService,
  );
  await transferCoordinator.initialize();

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
      deviceStorageService: deviceStorageService,
      libraryScannerService: libraryScannerService,
      storageMonitorService: storageMonitorService,
      metadataService: metadataService,
      settingsService: settingsService,
      transferService: transferService,
      transferCoordinator: transferCoordinator,
    ),
  );
}

class ReelhouseApp extends StatefulWidget {
  final AppDatabase database;
  final LibraryRepository libraryRepository;
  final StorageIdentityService storageIdentityService;
  final LocalStorageManager localStorageManager;
  final DeviceStorageService? deviceStorageService;
  final LibraryScannerService? libraryScannerService;
  final StorageMonitorService? storageMonitorService;
  final MetadataService? metadataService;
  final SettingsService? settingsService;
  final TransferService? transferService;
  final TransferCoordinator? transferCoordinator;

  ReelhouseApp({
    super.key,
    required this.database,
    LibraryRepository? libraryRepository,
    required this.storageIdentityService,
    required this.localStorageManager,
    this.deviceStorageService,
    this.libraryScannerService,
    this.storageMonitorService,
    this.metadataService,
    this.settingsService,
    this.transferService,
    this.transferCoordinator,
  }) : libraryRepository =
           libraryRepository ?? DriftLibraryRepository(database);

  @override
  State<ReelhouseApp> createState() => _ReelhouseAppState();
}

class _ReelhouseAppState extends State<ReelhouseApp> {
  bool _showOpening = true;

  void _onOpeningComplete() {
    if (mounted) {
      setState(() {
        _showOpening = false;
      });
    }
  }

  Widget _buildHome() {
    final s = widget.settingsService;
    return (s != null && !s.isOnboardingCompleted)
        ? OnboardingScreen(
            database: widget.database,
            repository: widget.libraryRepository,
            storageIdentityService: widget.storageIdentityService,
            localStorageManager: widget.localStorageManager,
            libraryScannerService: widget.libraryScannerService,
            storageMonitorService: widget.storageMonitorService,
            metadataService: widget.metadataService,
            settingsService: s,
            deviceStorageService: widget.deviceStorageService,
            transferService: widget.transferService,
            transferCoordinator: widget.transferCoordinator,
          )
        : CinemaShell(
            database: widget.database,
            repository: widget.libraryRepository,
            storageIdentityService: widget.storageIdentityService,
            localStorageManager: widget.localStorageManager,
            libraryScannerService: widget.libraryScannerService,
            storageMonitorService: widget.storageMonitorService,
            metadataService: widget.metadataService,
            settingsService: s,
            deviceStorageService: widget.deviceStorageService,
            transferService: widget.transferService,
            transferCoordinator: widget.transferCoordinator,
          );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = widget.settingsService ?? ChangeNotifier();
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        final currentMode = widget.settingsService?.themeMode ?? ThemeMode.dark;
        return MaterialApp(
          title: 'REELHOUSE',
          debugShowCheckedModeBanner: false,
          theme: CinemaTheme.lightTheme,
          darkTheme: CinemaTheme.darkTheme,
          themeMode: currentMode,
          home: _showOpening
              ? ReelhouseOpening(onComplete: _onOpeningComplete)
              : _buildHome(),
        );
      },
    );
  }
}
