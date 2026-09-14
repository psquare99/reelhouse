import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';

class HomeScreen extends StatelessWidget {
  final AppDatabase database;
  final VoidCallback onNavigateToMovies;
  final VoidCallback onNavigateToTv;
  final VoidCallback onNavigateToSettings;

  const HomeScreen({
    super.key,
    required this.database,
    required this.onNavigateToMovies,
    required this.onNavigateToTv,
    required this.onNavigateToSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cinematic Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REELHOUSE',
                          style: TextStyle(
                            color: CinemaColors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Personal Digital Cinema',
                          style: TextStyle(
                            color: CinemaColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: CinemaColors.textSecondary,
                    ),
                    tooltip: 'Settings & Storage',
                    onPressed: onNavigateToSettings,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Storage and Availability Status Banner
              StreamBuilder<List<Storage>>(
                stream: database.watchAllStorages(),
                builder: (context, snapshot) {
                  final storages = snapshot.data ?? [];
                  final externalStorages = storages
                      .where((s) => s.storageType != 'DEVICE_LOCAL_STORAGE')
                      .toList();
                  final connectedExternal = externalStorages
                      .where((s) => s.available)
                      .length;

                  return LayoutBuilder(
                    builder: (context, bannerConstraints) {
                      final isCompact = bannerConstraints.maxWidth < 560;

                      final content = Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: CinemaColors.amberSubtle,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.movie_filter_outlined,
                              color: CinemaColors.amber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cinema Status',
                                  style: TextStyle(
                                    color: CinemaColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  externalStorages.isEmpty
                                      ? 'No external storage disks registered. Connect a drive in Settings.'
                                      : '$connectedExternal of ${externalStorages.length} external storage disks connected.',
                                  style: const TextStyle(
                                    color: CinemaColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final button = OutlinedButton.icon(
                        onPressed: onNavigateToSettings,
                        icon: const Icon(Icons.storage, size: 16),
                        label: const Text('Manage Storage'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      );

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: CinemaColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CinemaColors.borderSubtle),
                        ),
                        child: isCompact
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  content,
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: button,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: content),
                                  const SizedBox(width: 16),
                                  button,
                                ],
                              ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),

              // Quick Access Tiles
              Text(
                'Explore Catalogue',
                style: const TextStyle(
                  color: CinemaColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return Row(
                    children: [
                      Expanded(
                        child: _CatalogueEntryCard(
                          title: 'Movies',
                          subtitle: 'Browse your personal feature film library',
                          icon: Icons.movie_outlined,
                          streamCount: database.watchMovieCount(),
                          onTap: onNavigateToMovies,
                        ),
                      ),
                      SizedBox(width: isWide ? 20 : 12),
                      Expanded(
                        child: _CatalogueEntryCard(
                          title: 'TV Shows',
                          subtitle: 'Series, seasons, and episode collections',
                          icon: Icons.tv_outlined,
                          streamCount: database.watchTvShowCount(),
                          onTap: onNavigateToTv,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),

              // Empty Library Welcome
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: CinemaColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CinemaColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.theaters_outlined,
                      size: 48,
                      color: CinemaColors.amber,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your personal cinema is ready.',
                      style: TextStyle(
                        color: CinemaColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The library is permanent; disks are sources.\nDisconnecting a drive never erases your cinema.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CinemaColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogueEntryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Stream<int> streamCount;
  final VoidCallback onTap;

  const _CatalogueEntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.streamCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: CinemaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CinemaColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: CinemaColors.amber, size: 28),
                StreamBuilder<int>(
                  stream: streamCount,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CinemaColors.amberSubtle,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count Titles',
                        style: const TextStyle(
                          color: CinemaColors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: CinemaColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: CinemaColors.textMuted,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
