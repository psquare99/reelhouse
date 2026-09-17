import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/metadata/metadata_service.dart';
import '../../domain/repository/library_repository.dart';
import '../../domain/scanner/library_scanner_service.dart';
import '../../domain/services/local_storage_manager.dart';
import '../../domain/services/settings_service.dart';
import '../../domain/services/storage_identity_service.dart';
import '../../domain/services/storage_monitor_service.dart';
import '../collections/collections_screen.dart';
import '../home/home_screen.dart';
import '../movies/movies_screen.dart';
import '../offline/offline_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../tv_shows/tv_shows_screen.dart';

class CinemaShell extends StatefulWidget {
  final AppDatabase database;
  final LibraryRepository repository;
  final StorageIdentityService storageIdentityService;
  final LocalStorageManager localStorageManager;
  final LibraryScannerService? libraryScannerService;
  final StorageMonitorService? storageMonitorService;
  final MetadataService? metadataService;
  final SettingsService? settingsService;

  CinemaShell({
    super.key,
    required this.database,
    LibraryRepository? repository,
    required this.storageIdentityService,
    required this.localStorageManager,
    this.libraryScannerService,
    this.storageMonitorService,
    this.metadataService,
    this.settingsService,
  }) : repository = repository ?? DriftLibraryRepository(database);

  @override
  State<CinemaShell> createState() => _CinemaShellState();
}

class _CinemaShellState extends State<CinemaShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.storageMonitorService?.startMonitoring();
  }

  @override
  void dispose() {
    widget.storageMonitorService?.stopMonitoring();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        repository: widget.repository,
        database: widget.database,
        onNavigateToMovies: () => _onDestinationSelected(1),
        onNavigateToTv: () => _onDestinationSelected(2),
        onNavigateToOffline: () => _onDestinationSelected(3),
        onNavigateToSettings: () => _onDestinationSelected(6),
      ),
      MoviesScreen(repository: widget.repository, database: widget.database),
      TvShowsScreen(repository: widget.repository, database: widget.database),
      OfflineScreen(repository: widget.repository, database: widget.database),
      CollectionsScreen(
        repository: widget.repository,
        database: widget.database,
      ),
      SearchScreen(repository: widget.repository, database: widget.database),
      SettingsScreen(
        database: widget.database,
        repository: widget.repository,
        storageIdentityService: widget.storageIdentityService,
        localStorageManager: widget.localStorageManager,
        libraryScannerService: widget.libraryScannerService,
        metadataService: widget.metadataService,
        settingsService: widget.settingsService,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        if (isWide) {
          // Desktop / Tablet Landscape Navigation Rail
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: CinemaColors.amberSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CinemaColors.amber,
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.movie_creation,
                            color: CinemaColors.amber,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'REEL',
                          style: TextStyle(
                            color: CinemaColors.amber,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.movie_outlined),
                      selectedIcon: Icon(Icons.movie),
                      label: Text('Movies'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tv_outlined),
                      selectedIcon: Icon(Icons.tv),
                      label: Text('TV Shows'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.offline_pin_outlined),
                      selectedIcon: Icon(Icons.offline_pin),
                      label: Text('Offline'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.collections_bookmark_outlined),
                      selectedIcon: Icon(Icons.collections_bookmark),
                      label: Text('Collections'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Search'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: screens),
                ),
              ],
            ),
          );
        }

        // Mobile Bottom Navigation Bar
        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.movie_outlined),
                selectedIcon: Icon(Icons.movie),
                label: 'Movies',
              ),
              NavigationDestination(
                icon: Icon(Icons.tv_outlined),
                selectedIcon: Icon(Icons.tv),
                label: 'TV',
              ),
              NavigationDestination(
                icon: Icon(Icons.offline_pin_outlined),
                selectedIcon: Icon(Icons.offline_pin),
                label: 'Offline',
              ),
              NavigationDestination(
                icon: Icon(Icons.collections_bookmark_outlined),
                selectedIcon: Icon(Icons.collections_bookmark),
                label: 'Collections',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
