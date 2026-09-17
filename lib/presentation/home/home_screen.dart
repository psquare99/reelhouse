import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../domain/query/query.dart';
import '../../domain/repository/library_repository.dart';
import '../movies/movie_detail_screen.dart';
import '../widgets/cinema_poster_card.dart';

/// Cinematic Home screen displaying dynamic, state-aware cinema sections
/// (Continue Watching, Recently Added, Favorites, Watchlist) and catalogue gateways.
class HomeScreen extends StatelessWidget {
  final LibraryRepository repository;
  final AppDatabase database;
  final VoidCallback onNavigateToMovies;
  final VoidCallback onNavigateToTv;
  final VoidCallback? onNavigateToOffline;
  final VoidCallback onNavigateToSettings;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.database,
    required this.onNavigateToMovies,
    required this.onNavigateToTv,
    this.onNavigateToOffline,
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
              const SizedBox(height: 28),

              // Storage & Cinema Status Banner (belongs to storage infrastructure)
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
              const SizedBox(height: 36),

              // 1. CONTINUE WATCHING (Smart View Query)
              StreamBuilder<LibraryResult<MovieLibraryItem>>(
                stream: repository.watchMovies(
                  MovieQuery.continueWatching(limit: 10),
                ),
                builder: (context, snapshot) {
                  final inProgressMovies = snapshot.data?.items ?? [];
                  if (inProgressMovies.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'CONTINUE WATCHING',
                        subtitle: 'Resume playback where you left off',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 275,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: inProgressMovies.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 20),
                          itemBuilder: (context, index) {
                            final movie = inProgressMovies[index];
                            return SizedBox(
                              width: 170,
                              child: CinemaPosterCard(
                                title: movie.displayTitle,
                                year: movie.displayYear,
                                posterPath: movie.posterPath,
                                availabilityStatus: movie.availability,
                                isFavorite: movie.isFavorite,
                                watchState: movie.watchState.toDbString(),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailScreen(
                                        movieId: movie.id,
                                        repository: repository,
                                        database: database,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 38),
                    ],
                  );
                },
              ),

              // 2. RECENTLY ADDED (Smart View Query)
              StreamBuilder<LibraryResult<MovieLibraryItem>>(
                stream: repository.watchMovies(
                  MovieQuery.recentlyAdded(limit: 10),
                ),
                builder: (context, snapshot) {
                  final recent = snapshot.data?.items ?? [];
                  if (recent.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'RECENTLY ADDED',
                        subtitle:
                            'Latest acquisitions discovered across your disks',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 275,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recent.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 20),
                          itemBuilder: (context, index) {
                            final movie = recent[index];
                            return SizedBox(
                              width: 170,
                              child: CinemaPosterCard(
                                title: movie.displayTitle,
                                year: movie.displayYear,
                                posterPath: movie.posterPath,
                                availabilityStatus: movie.availability,
                                isFavorite: movie.isFavorite,
                                watchState: movie.watchState.toDbString(),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailScreen(
                                        movieId: movie.id,
                                        repository: repository,
                                        database: database,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 38),
                    ],
                  );
                },
              ),

              // 3. FAVORITES (Smart View Query)
              StreamBuilder<LibraryResult<MovieLibraryItem>>(
                stream: repository.watchMovies(MovieQuery.favorites()),
                builder: (context, snapshot) {
                  final favorites = snapshot.data?.items ?? [];
                  if (favorites.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'FAVORITES',
                        subtitle: 'Your personal cinema highlights',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 275,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: favorites.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 20),
                          itemBuilder: (context, index) {
                            final movie = favorites[index];
                            return SizedBox(
                              width: 170,
                              child: CinemaPosterCard(
                                title: movie.displayTitle,
                                year: movie.displayYear,
                                posterPath: movie.posterPath,
                                availabilityStatus: movie.availability,
                                isFavorite: true,
                                watchState: movie.watchState.toDbString(),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailScreen(
                                        movieId: movie.id,
                                        repository: repository,
                                        database: database,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 38),
                    ],
                  );
                },
              ),

              // 4. WATCHLIST (Smart View Query)
              StreamBuilder<LibraryResult<MovieLibraryItem>>(
                stream: repository.watchMovies(MovieQuery.watchlist()),
                builder: (context, snapshot) {
                  final watchlist = snapshot.data?.items ?? [];
                  if (watchlist.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'WATCHLIST',
                        subtitle: 'Titles saved for your next screening',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 275,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: watchlist.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 20),
                          itemBuilder: (context, index) {
                            final movie = watchlist[index];
                            return SizedBox(
                              width: 170,
                              child: CinemaPosterCard(
                                title: movie.displayTitle,
                                year: movie.displayYear,
                                posterPath: movie.posterPath,
                                availabilityStatus: movie.availability,
                                isFavorite: movie.isFavorite,
                                watchState: movie.watchState.toDbString(),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailScreen(
                                        movieId: movie.id,
                                        repository: repository,
                                        database: database,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 38),
                    ],
                  );
                },
              ),

              // 5. EXPLORE CATALOGUE (Repository Stream Counts)
              const _SectionHeader(
                title: 'EXPLORE CINEMA',
                subtitle: 'Browse your personal cinema by category',
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 780;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _CatalogueEntryCard(
                              title: 'Movies',
                              subtitle:
                                  'Feature films across all storage disks',
                              icon: Icons.movie_outlined,
                              streamCount: repository.watchMovieCount(),
                              onTap: onNavigateToMovies,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CatalogueEntryCard(
                              title: 'TV Shows',
                              subtitle: 'Series, seasons, and episode archives',
                              icon: Icons.tv_outlined,
                              streamCount: repository.watchTvShowCount(),
                              onTap: onNavigateToTv,
                            ),
                          ),
                          if (isWide && onNavigateToOffline != null) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: _CatalogueEntryCard(
                                title: 'Offline Library',
                                subtitle:
                                    'Media downloaded directly to this device',
                                icon: Icons.offline_pin_outlined,
                                streamCount: repository
                                    .watchMovies(MovieQuery.offline())
                                    .map((r) => r.totalCount),
                                onTap: onNavigateToOffline!,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (!isWide && onNavigateToOffline != null) ...[
                        const SizedBox(height: 16),
                        _CatalogueEntryCard(
                          title: 'Offline Library',
                          subtitle: 'Media downloaded directly to this device',
                          icon: Icons.offline_pin_outlined,
                          streamCount: repository
                              .watchMovies(MovieQuery.offline())
                              .map((r) => r.totalCount),
                          onTap: onNavigateToOffline!,
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 42),

              // Cinema Principle Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CinemaColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CinemaColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.theaters_outlined,
                      size: 40,
                      color: CinemaColors.amber,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Your personal cinema is permanent.',
                      style: TextStyle(
                        color: CinemaColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Disks are sources. Disconnecting a drive never erases your library.\nCopies on this device remain ready to watch offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CinemaColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: CinemaColors.amber,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: CinemaColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CinemaColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CinemaColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CinemaColors.amberSubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: CinemaColors.amber, size: 24),
                ),
                StreamBuilder<int>(
                  stream: streamCount,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '$count',
                      style: const TextStyle(
                        color: CinemaColors.amber,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: CinemaColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CinemaColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
