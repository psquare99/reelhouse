import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/models/availability_status.dart';
import '../../domain/query/library_result.dart';
import '../../domain/query/movie_query.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/query/tv_show_query.dart';
import '../../domain/repository/library_repository.dart';
import '../movies/movie_detail_screen.dart';
import '../tv_shows/tv_show_detail_screen.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_loading_skeleton.dart';
import '../widgets/cinema_poster_card.dart';

/// Dedicated Offline Library destination showing media items with local device copies.
///
/// Operates 100% offline with zero external disks connected.
class OfflineScreen extends StatefulWidget {
  final LibraryRepository repository;
  final AppDatabase? database;

  OfflineScreen({
    super.key,
    LibraryRepository? repository,
    AppDatabase? database,
  }) : repository =
           repository ??
           (database != null
               ? DriftLibraryRepository(database)
               : throw ArgumentError(
                   'Either repository or database must be provided',
                 )),
       database = database;

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  String _filter = 'all'; // 'all' | 'movies' | 'tv'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<LibraryResult<MovieLibraryItem>>(
        stream: widget.repository.watchMovies(MovieQuery.offline()),
        builder: (context, moviesSnapshot) {
          if (moviesSnapshot.hasError) {
            return CinemaErrorState(
              title: 'Unable to Load Offline Media',
              message: moviesSnapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          return StreamBuilder<LibraryResult<TvShowLibraryItem>>(
            stream: widget.repository.watchTvShows(TvShowQuery.offline()),
            builder: (context, showsSnapshot) {
              if (showsSnapshot.hasError) {
                return CinemaErrorState(
                  title: 'Unable to Load Offline Media',
                  message: showsSnapshot.error.toString(),
                  onRetry: () => setState(() {}),
                );
              }

              final isWaiting =
                  (moviesSnapshot.connectionState == ConnectionState.waiting &&
                      !moviesSnapshot.hasData) ||
                  (showsSnapshot.connectionState == ConnectionState.waiting &&
                      !showsSnapshot.hasData);

              if (isWaiting) {
                return const Scaffold(
                  body: SafeArea(child: CinemaGridSkeleton()),
                );
              }

              final offlineMovies = moviesSnapshot.data?.items ?? [];
              final offlineShows = showsSnapshot.data?.items ?? [];
              final totalCount = offlineMovies.length + offlineShows.length;

              final showMovies = _filter == 'all' || _filter == 'movies';
              final showShows = _filter == 'all' || _filter == 'tv';

              return CustomScrollView(
                slivers: [
                  // App Bar / Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: CinemaColors.amberSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.offline_pin,
                                  color: CinemaColors.amber,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OFFLINE LIBRARY',
                                    style: TextStyle(
                                      color: CinemaColors.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalCount ${totalCount == 1 ? 'title' : 'titles'} stored locally on this device',
                                    style: const TextStyle(
                                      color: CinemaColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Filter Row
                          Wrap(
                            spacing: 10,
                            children: [
                              _buildFilterChip('all', 'All ($totalCount)'),
                              _buildFilterChip(
                                'movies',
                                'Movies (${offlineMovies.length})',
                              ),
                              _buildFilterChip(
                                'tv',
                                'TV Shows (${offlineShows.length})',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content Area
                  if (totalCount == 0)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: CinemaColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CinemaColors.borderSubtle,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.offline_pin_outlined,
                                  size: 36,
                                  color: CinemaColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No Offline Media on This Device',
                                style: TextStyle(
                                  color: CinemaColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const SizedBox(
                                width: 440,
                                child: Text(
                                  'Media files downloaded or copied to device-local storage will appear here for untethered viewing without external disks.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: CinemaColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Movies Section
                    if (showMovies && offlineMovies.isNotEmpty) ...[
                      if (_filter == 'all')
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(32, 16, 32, 12),
                            child: Text(
                              'MOVIES',
                              style: TextStyle(
                                color: CinemaColors.amber,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 8,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                childAspectRatio: 0.60,
                                crossAxisSpacing: 28,
                                mainAxisSpacing: 32,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final movie = offlineMovies[index];
                            return CinemaPosterCard(
                              title: movie.title ?? movie.detectedTitle,
                              year: movie.year ?? movie.detectedYear,
                              posterPath: movie.posterPath,
                              availabilityStatus:
                                  AvailabilityStatus.availableLocally,
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
                            );
                          }, childCount: offlineMovies.length),
                        ),
                      ),
                    ],

                    // TV Shows Section
                    if (showShows && offlineShows.isNotEmpty) ...[
                      if (_filter == 'all')
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(32, 28, 32, 12),
                            child: Text(
                              'TV SHOWS',
                              style: TextStyle(
                                color: CinemaColors.amber,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 8,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                childAspectRatio: 0.60,
                                crossAxisSpacing: 28,
                                mainAxisSpacing: 32,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final show = offlineShows[index];
                            return CinemaPosterCard(
                              title: show.title ?? show.detectedTitle,
                              year: show.firstAirDate?.year,
                              posterPath: show.posterPath,
                              availabilityStatus:
                                  AvailabilityStatus.availableLocally,
                              isFavorite: show.isFavorite,
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
                            );
                          }, childCount: offlineShows.length),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _filter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = filterKey);
        }
      },
      selectedColor: CinemaColors.surfaceElevated,
      backgroundColor: CinemaColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? CinemaColors.amber : CinemaColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected ? CinemaColors.amber : CinemaColors.borderSubtle,
        ),
      ),
    );
  }
}
