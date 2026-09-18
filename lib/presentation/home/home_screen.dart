import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../domain/query/query.dart';
import '../../domain/repository/library_repository.dart';
import '../movies/movie_detail_screen.dart';
import '../search/cinema_search_results_view.dart';
import '../tv_shows/tv_show_detail_screen.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_loading_skeleton.dart';
import '../widgets/cinema_poster_card.dart';
import '../widgets/cinema_search_bar.dart';

/// Cinematic Home screen displaying:
/// 1. Top bar with quiet disk indicator and settings trigger.
/// 2. Prominent contextual search bar across complete library.
/// 3. Escalated missing storage banner (only when registered drives are missing and not dismissed in session).
/// 4. ~180-220px Hero section with backdrop scrim, in-progress resume or recently-added fallback.
/// 5. Dynamic cinema carousels (Continue Watching, Recently Added, conditional Favorites & Watchlist).
/// 6. Compact Explore Cinema navigation cards with secondary counts.
class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _dismissedStorageNotice = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.title;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounceTimer?.cancel();
    final query = val.trim();
    if (query.isEmpty) {
      setState(() => _searchQuery = '');
      return;
    }
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Header + Quiet Disk Indicator + Settings
              _buildTopBar(context, tokens),
              const SizedBox(height: 16),

              // 2. Global Contextual Search Bar
              CinemaSearchBar(
                controller: _searchController,
                searchMode: _searchMode,
                hintText:
                    'Search complete library (Movies, TV Shows, Episodes)...',
                onSearchModeChanged: (mode) {
                  setState(() => _searchMode = mode);
                },
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchDebounceTimer?.cancel();
                  setState(() => _searchQuery = '');
                },
              ),
              const SizedBox(height: 24),

              if (isSearching) ...[
                // Live Library Search Results View
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: CinemaSearchResultsView(
                    repository: widget.repository,
                    database: widget.database,
                    query: _searchQuery,
                    searchMode: _searchMode,
                    onDismiss: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
              ] else ...[
                // 3. Escalated Missing Disk Banner (Conditional)
                _buildEscalatedDiskBanner(tokens),

                // 4. Hero Section (~180-220px)
                _buildHeroSection(context, tokens),
                const SizedBox(height: 36),

                // 5. In-Progress Movies (Continue Watching)
                _buildMovieSection(
                  title: 'CONTINUE WATCHING',
                  subtitle: 'Resume playback where you left off',
                  query: MovieQuery.continueWatching(limit: 10),
                ),

                // 6. In-Progress TV Episodes
                _buildTvContinueWatchingSection(),

                // 7. Recently Added Movies
                _buildMovieSection(
                  title: 'RECENTLY ADDED',
                  subtitle: 'Latest acquisitions discovered across your disks',
                  query: MovieQuery.recentlyAdded(limit: 10),
                ),

                // 8. TV Recently Added Shows
                _buildTvRecentlyAddedSection(),

                // 9. Favorites (Omitted entirely when empty)
                _buildMovieSection(
                  title: 'FAVORITES',
                  subtitle: 'Your personal cinema highlights',
                  query: MovieQuery.favorites(),
                  omitIfEmpty: true,
                ),

                // 10. Watchlist (Omitted entirely when empty)
                _buildMovieSection(
                  title: 'WATCHLIST',
                  subtitle: 'Titles saved for your next screening',
                  query: MovieQuery.watchlist(),
                  omitIfEmpty: true,
                ),

                // 11. Compact Explore Cinema Navigation Cards
                _buildExploreSection(context, tokens),
                const SizedBox(height: 36),

                // 12. Cinema Principle Footer
                _buildCinemaFooter(tokens),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, CinemaThemeData tokens) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REELHOUSE',
                style: CinemaTheme.eyebrow(context, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'Personal Digital Cinema',
                style: CinemaTheme.heading(context, fontSize: 22),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quiet Disk Indicator
            StreamBuilder<List<Storage>>(
              stream: widget.database.watchAllStorages(),
              builder: (context, snapshot) {
                final storages = snapshot.data ?? [];
                final externalStorages = storages
                    .where((s) => s.storageType != 'DEVICE_LOCAL_STORAGE')
                    .toList();
                if (externalStorages.isEmpty) return const SizedBox.shrink();

                final connected = externalStorages
                    .where((s) => s.available)
                    .length;
                final total = externalStorages.length;
                final hasMissing = connected < total;

                return InkWell(
                  onTap: widget.onNavigateToSettings,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: tokens.surface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasMissing
                            ? tokens.stateUnavailable
                            : tokens.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storage_outlined,
                          size: 14,
                          color: hasMissing
                              ? tokens.stateUnavailable
                              : tokens.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$connected/$total Disks',
                          style: TextStyle(
                            color: hasMissing
                                ? tokens.textSecondary
                                : tokens.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: tokens.textSecondary,
                size: 20,
              ),
              tooltip: 'Settings & Storage',
              onPressed: widget.onNavigateToSettings,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEscalatedDiskBanner(CinemaThemeData tokens) {
    if (_dismissedStorageNotice) return const SizedBox.shrink();

    return StreamBuilder<List<Storage>>(
      stream: widget.database.watchAllStorages(),
      builder: (context, snapshot) {
        final storages = snapshot.data ?? [];
        final externalStorages = storages
            .where((s) => s.storageType != 'DEVICE_LOCAL_STORAGE')
            .toList();
        if (externalStorages.isEmpty) return const SizedBox.shrink();

        final disconnected = externalStorages
            .where((s) => !s.available)
            .toList();
        if (disconnected.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderStrong, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: tokens.stateUnavailable,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${disconnected.length} storage disk${disconnected.length > 1 ? 's' : ''} unavailable',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Titles located on these drives will require reconnection before playback.',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: widget.onNavigateToSettings,
                child: const Text('Manage Disks'),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: tokens.textMuted),
                tooltip: 'Dismiss notice for session',
                onPressed: () {
                  setState(() {
                    _dismissedStorageNotice = true;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context, CinemaThemeData tokens) {
    // 1. Check for in-progress Movie
    return StreamBuilder<LibraryResult<MovieLibraryItem>>(
      stream: widget.repository.watchMovies(
        MovieQuery.continueWatching(limit: 1),
      ),
      builder: (context, movieSnap) {
        final inProgressMovie = movieSnap.data?.items.firstOrNull;

        if (inProgressMovie != null) {
          return _HeroCard(
            eyebrow: 'RESUME WATCHING',
            title: inProgressMovie.displayTitle,
            subtitle: inProgressMovie.displayYear != null
                ? '${inProgressMovie.displayYear} • In Progress'
                : 'In Progress',
            backdropPath: inProgressMovie.posterPath,
            posterPath: inProgressMovie.posterPath,
            actionLabel: 'Resume',
            actionIcon: Icons.play_arrow,
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MovieDetailScreen(
                    movieId: inProgressMovie.id,
                    repository: widget.repository,
                    database: widget.database,
                  ),
                ),
              );
            },
            onDetails: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MovieDetailScreen(
                    movieId: inProgressMovie.id,
                    repository: widget.repository,
                    database: widget.database,
                  ),
                ),
              );
            },
          );
        }

        // 2. Fallback: check recently added Movie
        return StreamBuilder<LibraryResult<MovieLibraryItem>>(
          stream: widget.repository.watchMovies(
            MovieQuery.recentlyAdded(limit: 1),
          ),
          builder: (context, recentSnap) {
            final recentMovie = recentSnap.data?.items.firstOrNull;

            if (recentMovie != null) {
              return _HeroCard(
                eyebrow: 'FEATURED SCREENING',
                title: recentMovie.displayTitle,
                subtitle: recentMovie.displayYear != null
                    ? '${recentMovie.displayYear} • Recently Added'
                    : 'Recently Added',
                backdropPath: recentMovie.posterPath,
                posterPath: recentMovie.posterPath,
                actionLabel: 'Play',
                actionIcon: Icons.play_arrow,
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MovieDetailScreen(
                        movieId: recentMovie.id,
                        repository: widget.repository,
                        database: widget.database,
                      ),
                    ),
                  );
                },
                onDetails: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MovieDetailScreen(
                        movieId: recentMovie.id,
                        repository: widget.repository,
                        database: widget.database,
                      ),
                    ),
                  );
                },
              );
            }

            // 3. Fallback: Themed neutral cinema surface
            return _HeroCard(
              eyebrow: 'REELHOUSE CINEMA',
              title: 'Your Personal Digital Cinema',
              subtitle: 'Permanent catalogue preserved across all your storage disks.',
              actionLabel: 'Explore Movies',
              actionIcon: Icons.movie_outlined,
              onAction: widget.onNavigateToMovies,
            );
          },
        );
      },
    );
  }

  Widget _buildMovieSection({
    required String title,
    required String subtitle,
    required MovieQuery query,
    bool omitIfEmpty = false,
  }) {
    return StreamBuilder<LibraryResult<MovieLibraryItem>>(
      stream: widget.repository.watchMovies(query),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return CinemaErrorSection(
            title: title,
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return CinemaCarouselSkeleton(title: title, subtitle: subtitle);
        }

        final items = snapshot.data?.items ?? [];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 16),
            SizedBox(
              height: 275,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final movie = items[index];
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
                              repository: widget.repository,
                              database: widget.database,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 36),
          ],
        );
      },
    );
  }

  Widget _buildTvContinueWatchingSection() {
    return StreamBuilder<LibraryResult<EpisodeLibraryItem>>(
      stream: widget.repository.watchEpisodes(
        EpisodeQuery.continueWatching(limit: 10),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return CinemaErrorSection(
            title: 'TV CONTINUE WATCHING',
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const CinemaCarouselSkeleton(
            title: 'TV CONTINUE WATCHING',
            subtitle: 'Resume episodes where you left off',
          );
        }

        final inProgressEpisodes = snapshot.data?.items ?? [];
        if (inProgressEpisodes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'TV CONTINUE WATCHING',
              subtitle: 'Resume episodes where you left off',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 275,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: inProgressEpisodes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final ep = inProgressEpisodes[index];
                  final progress =
                      (ep.runtime != null &&
                          ep.runtime! > 0 &&
                          ep.playbackPositionSeconds > 0)
                      ? (ep.playbackPositionSeconds / (ep.runtime! * 60)).clamp(
                          0.0,
                          1.0,
                        )
                      : 0.4;

                  return SizedBox(
                    width: 170,
                    child: CinemaPosterCard(
                      title: ep.displayName,
                      subtitle: ep.episodeCode,
                      posterPath: ep.stillPath,
                      availabilityStatus: ep.availability,
                      watchState: ep.watchState.toDbString(),
                      watchProgress: progress,
                      fallbackIcon: Icons.tv,
                      onTap: () {
                        if (ep.showId != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TvShowDetailScreen(
                                showId: ep.showId!,
                                repository: widget.repository,
                                database: widget.database,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 36),
          ],
        );
      },
    );
  }

  Widget _buildTvRecentlyAddedSection() {
    return StreamBuilder<LibraryResult<TvShowLibraryItem>>(
      stream: widget.repository.watchTvShows(
        TvShowQuery.recentlyAdded(limit: 10),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return CinemaErrorSection(
            title: 'TV RECENTLY ADDED',
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const CinemaCarouselSkeleton(
            title: 'TV RECENTLY ADDED',
            subtitle: 'Latest series and seasons discovered across your disks',
          );
        }

        final recentShows = snapshot.data?.items ?? [];
        if (recentShows.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'TV RECENTLY ADDED',
              subtitle:
                  'Latest series and seasons discovered across your disks',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 275,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentShows.length,
                separatorBuilder: (_, _) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final show = recentShows[index];
                  return SizedBox(
                    width: 170,
                    child: CinemaPosterCard(
                      title: show.displayTitle,
                      year: show.displayYear,
                      posterPath: show.posterPath,
                      availabilityStatus: show.availability,
                      isFavorite: show.isFavorite,
                      watchState: show.derivedWatchState.toDbString(),
                      fallbackIcon: Icons.tv,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TvShowDetailScreen(
                              showId: show.id,
                              repository: widget.repository,
                              database: widget.database,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 36),
          ],
        );
      },
    );
  }

  Widget _buildExploreSection(BuildContext context, CinemaThemeData tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'EXPLORE CINEMA',
          subtitle: 'Browse your personal cinema by category',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: _CompactExploreCard(
                      title: 'Movies',
                      icon: Icons.movie_outlined,
                      streamCount: widget.repository.watchMovieCount(),
                      onTap: widget.onNavigateToMovies,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _CompactExploreCard(
                      title: 'TV Shows',
                      icon: Icons.tv_outlined,
                      streamCount: widget.repository.watchTvShowCount(),
                      onTap: widget.onNavigateToTv,
                    ),
                  ),
                  if (widget.onNavigateToOffline != null) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: _CompactExploreCard(
                        title: 'Offline Library',
                        icon: Icons.offline_pin_outlined,
                        streamCount: widget.repository
                            .watchMovies(MovieQuery.offline())
                            .map((r) => r.totalCount),
                        onTap: widget.onNavigateToOffline!,
                      ),
                    ),
                  ],
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CompactExploreCard(
                        title: 'Movies',
                        icon: Icons.movie_outlined,
                        streamCount: widget.repository.watchMovieCount(),
                        onTap: widget.onNavigateToMovies,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _CompactExploreCard(
                        title: 'TV Shows',
                        icon: Icons.tv_outlined,
                        streamCount: widget.repository.watchTvShowCount(),
                        onTap: widget.onNavigateToTv,
                      ),
                    ),
                  ],
                ),
                if (widget.onNavigateToOffline != null) ...[
                  const SizedBox(height: 12),
                  _CompactExploreCard(
                    title: 'Offline Library',
                    icon: Icons.offline_pin_outlined,
                    streamCount: widget.repository
                        .watchMovies(MovieQuery.offline())
                        .map((r) => r.totalCount),
                    onTap: widget.onNavigateToOffline!,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCinemaFooter(CinemaThemeData tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.theaters_outlined, size: 32, color: tokens.accent),
          const SizedBox(height: 10),
          Text(
            'Your personal cinema is permanent.',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Disks are sources. Disconnecting a drive never erases your library.\nCopies on this device remain ready to watch offline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
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
    final tokens = CinemaTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: CinemaTheme.eyebrow(context, fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? backdropPath;
  final String? posterPath;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final VoidCallback? onDetails;

  const _HeroCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.backdropPath,
    this.posterPath,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    // Fallback chain for image artwork:
    // 1. backdropPath file -> 2. posterPath file -> 3. gradient themed background
    Widget? backgroundArtwork;
    if (backdropPath != null && File(backdropPath!).existsSync()) {
      backgroundArtwork = Image.file(
        File(backdropPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (posterPath != null && File(posterPath!).existsSync()) {
      backgroundArtwork = Image.file(
        File(posterPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
        width: double.infinity,
        decoration: BoxDecoration(
          color: tokens.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border, width: 1),
        ),
        child: InkWell(
          onTap: onDetails,
          child: Stack(
            children: [
              // Background Artwork
              if (backgroundArtwork != null)
                Positioned.fill(child: backgroundArtwork),

              // Functional Scrim Overlay for Legibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        tokens.background.withValues(alpha: 0.94),
                        tokens.background.withValues(alpha: 0.80),
                        tokens.background.withValues(alpha: 0.40),
                      ],
                    ),
                  ),
                ),
              ),

              // Hero Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      eyebrow,
                      style: CinemaTheme.eyebrow(context, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CinemaTheme.displaySerif(
                        context,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onAction,
                          icon: Icon(actionIcon, size: 18),
                          label: Text(actionLabel),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                        ),
                        if (onDetails != null)
                          OutlinedButton(
                            onPressed: onDetails,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('View Details'),
                          ),
                      ],
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

class _CompactExploreCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Stream<int> streamCount;
  final VoidCallback onTap;

  const _CompactExploreCard({
    required this.title,
    required this.icon,
    required this.streamCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: tokens.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: tokens.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  StreamBuilder<int>(
                    stream: streamCount,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count items',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: tokens.textMuted),
          ],
        ),
      ),
    );
  }
}
