import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
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
import '../settings/settings_screen.dart';
import '../tv_shows/tv_shows_screen.dart';

/// App shell container providing navigation and hosting screens.
///
/// Features:
/// - Desktop / Tablet: Responsive collapsible navigation rail (220px expanded, 72px collapsed).
/// - 3 Functional groups: Browse (Home, Movies, TV), Library (Offline, Collections), Utility (Search, Settings).
/// - Orange accent pill (expanded) vs 3px leading bar (collapsed), zero competing secondary accents.
/// - Tooltip on hover in collapsed state.
/// - Persistent collapse preference via [SettingsService].
/// - Mobile: Standard bottom navigation bar with theme-aware styling.
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
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.settingsService?.isNavRailCollapsed ?? false;
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

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
    widget.settingsService?.setNavRailCollapsed(_isCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    final screens = [
      HomeScreen(
        repository: widget.repository,
        database: widget.database,
        onNavigateToMovies: () => _onDestinationSelected(1),
        onNavigateToTv: () => _onDestinationSelected(2),
        onNavigateToOffline: () => _onDestinationSelected(4),
        onNavigateToSettings: () => _onDestinationSelected(5),
      ),
      MoviesScreen(repository: widget.repository, database: widget.database),
      TvShowsScreen(repository: widget.repository, database: widget.database),
      CollectionsScreen(
        repository: widget.repository,
        database: widget.database,
      ),
      OfflineScreen(repository: widget.repository, database: widget.database),
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
          return Scaffold(
            backgroundColor: tokens.background,
            body: Row(
              children: [
                _CollapsibleCinemaRail(
                  isCollapsed: _isCollapsed,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  onToggleCollapse: _toggleCollapse,
                ),
                VerticalDivider(thickness: 1, width: 1, color: tokens.border),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: screens),
                ),
              ],
            ),
          );
        }

        // Mobile Bottom Navigation Bar
        return Scaffold(
          backgroundColor: tokens.background,
          body: IndexedStack(index: _selectedIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            backgroundColor: tokens.background,
            indicatorColor: tokens.accent.withValues(alpha: 0.14),
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
                icon: Icon(Icons.collections_bookmark_outlined),
                selectedIcon: Icon(Icons.collections_bookmark),
                label: 'Collections',
              ),
              NavigationDestination(
                icon: Icon(Icons.offline_pin_outlined),
                selectedIcon: Icon(Icons.offline_pin),
                label: 'Offline',
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

class _RailDestinationData {
  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _RailDestinationData({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class _CollapsibleCinemaRail extends StatelessWidget {
  final bool isCollapsed;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onToggleCollapse;

  const _CollapsibleCinemaRail({
    required this.isCollapsed,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onToggleCollapse,
  });

  static const _browseGroup = [
    _RailDestinationData(
      index: 0,
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _RailDestinationData(
      index: 1,
      label: 'Movies',
      icon: Icons.movie_outlined,
      selectedIcon: Icons.movie,
    ),
    _RailDestinationData(
      index: 2,
      label: 'TV Shows',
      icon: Icons.tv_outlined,
      selectedIcon: Icons.tv,
    ),
  ];

  static const _libraryGroup = [
    _RailDestinationData(
      index: 3,
      label: 'Collections',
      icon: Icons.collections_bookmark_outlined,
      selectedIcon: Icons.collections_bookmark,
    ),
    _RailDestinationData(
      index: 4,
      label: 'Offline',
      icon: Icons.offline_pin_outlined,
      selectedIcon: Icons.offline_pin,
    ),
  ];

  static const _utilityGroup = [
    _RailDestinationData(
      index: 5,
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);
    final width = isCollapsed ? 72.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: width,
      color: tokens.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / REEL mark
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 16 : 14,
              vertical: 20,
            ),
            child: isCollapsed
                ? Center(
                    child: Tooltip(
                      message: 'Expand sidebar',
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.border, width: 1),
                      ),
                      textStyle: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      child: InkWell(
                        onTap: onToggleCollapse,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: tokens.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tokens.accent, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'REEL',
                            style: TextStyle(
                              color: tokens.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      InkWell(
                        onTap: onToggleCollapse,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: tokens.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: tokens.accent, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'REEL',
                            style: TextStyle(
                              color: tokens.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REELHOUSE',
                              style: TextStyle(
                                color: tokens.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Personal Cinema',
                              style: TextStyle(
                                color: tokens.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: tokens.textSecondary,
                        ),
                        tooltip: 'Collapse sidebar',
                        onPressed: onToggleCollapse,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),

          // Group 1: Browse
          ..._buildGroup(context, _browseGroup),

          // Divider 1
          _buildGroupDivider(tokens),

          // Group 2: Library
          ..._buildGroup(context, _libraryGroup),

          // Divider 2
          _buildGroupDivider(tokens),

          // Group 3: Utility
          ..._buildGroup(context, _utilityGroup),
        ],
      ),
    );
  }

  Widget _buildGroupDivider(CinemaThemeData tokens) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 16 : 14,
        vertical: 12,
      ),
      child: Divider(color: tokens.border, height: 1, thickness: 1),
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    List<_RailDestinationData> items,
  ) {
    return items.map((item) {
      final isSelected = selectedIndex == item.index;
      return _RailItem(
        item: item,
        isCollapsed: isCollapsed,
        isSelected: isSelected,
        onTap: () => onDestinationSelected(item.index),
      );
    }).toList();
  }
}

class _RailItem extends StatelessWidget {
  final _RailDestinationData item;
  final bool isCollapsed;
  final bool isSelected;
  final VoidCallback onTap;

  const _RailItem({
    required this.item,
    required this.isCollapsed,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Positioned(
                left: 0,
                top: 4,
                bottom: 4,
                width: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.accent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            Tooltip(
              message: item.label,
              preferBelow: false,
              verticalOffset: 0,
              margin: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.border, width: 1),
              ),
              textStyle: TextStyle(
                color: tokens.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              child: SizedBox(
                width: 72,
                height: 44,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected ? tokens.accent : tokens.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? tokens.accent.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected ? tokens.accent : tokens.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? tokens.accent : tokens.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
