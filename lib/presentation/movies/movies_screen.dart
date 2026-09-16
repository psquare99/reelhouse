import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../domain/services/availability_resolver.dart';
import '../widgets/cinema_poster_card.dart';
import 'movie_detail_screen.dart';

/// Poster-first movie catalogue grid with availability and user library state indicators.
class MoviesScreen extends StatefulWidget {
  final AppDatabase database;

  const MoviesScreen({super.key, required this.database});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final AvailabilityResolver _availabilityResolver =
      const AvailabilityResolver();
  String _filter = 'ALL'; // 'ALL' | 'FAVORITES' | 'WATCHLIST' | 'IN_PROGRESS'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movies')),
      body: StreamBuilder<List<Storage>>(
        stream: widget.database.watchAllStorages(),
        builder: (context, storageSnapshot) {
          final storages = storageSnapshot.data ?? [];
          final storageMap = {for (final s in storages) s.id: s};

          return StreamBuilder<List<Movie>>(
            stream: widget.database.select(widget.database.movies).watch(),
            builder: (context, snapshot) {
              final allMovies = snapshot.data ?? [];

              final filteredMovies = allMovies.where((m) {
                switch (_filter) {
                  case 'FAVORITES':
                    return m.isFavorite;
                  case 'WATCHLIST':
                    return m.isWatchlist;
                  case 'IN_PROGRESS':
                    return m.watchState == 'IN_PROGRESS';
                  case 'ALL':
                  default:
                    return true;
                }
              }).toList();

              if (allMovies.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.movie_outlined,
                          size: 56,
                          color: CinemaColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No movies discovered yet.',
                          style: TextStyle(
                            color: CinemaColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Register and scan a storage location to populate your movie cinema.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CinemaColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Filter Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'All (${allMovies.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'FAVORITES',
                            'Favorites (${allMovies.where((m) => m.isFavorite).length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'WATCHLIST',
                            'Watchlist (${allMovies.where((m) => m.isWatchlist).length})',
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'IN_PROGRESS',
                            'In Progress (${allMovies.where((m) => m.watchState == 'IN_PROGRESS').length})',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Movie Poster Grid
                  Expanded(
                    child: filteredMovies.isEmpty
                        ? Center(
                            child: Text(
                              'No movies matching this filter.',
                              style: TextStyle(color: CinemaColors.textMuted),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 260,
                                  childAspectRatio: 0.60,
                                  crossAxisSpacing: 28,
                                  mainAxisSpacing: 32,
                                ),
                            itemCount: filteredMovies.length,
                            itemBuilder: (context, index) {
                              final movie = filteredMovies[index];

                              return StreamBuilder<List<MediaSource>>(
                                stream: widget.database.watchSourcesForMovie(
                                  movie.id,
                                ),
                                builder: (context, sourceSnapshot) {
                                  final sources = sourceSnapshot.data ?? [];
                                  final checkSources = sources.map((s) {
                                    final storage = storageMap[s.storageId];
                                    return SourceCheckInfo(
                                      sourceId: s.id,
                                      sourceType: s.sourceType,
                                      storageId: s.storageId,
                                      storageName: storage?.name ?? 'Storage',
                                      isSourceAvailable: s.available,
                                      isStorageConnected:
                                          storage?.available ?? true,
                                    );
                                  }).toList();

                                  final availability = _availabilityResolver
                                      .resolve(checkSources);

                                  return CinemaPosterCard(
                                    title: movie.title ?? movie.detectedTitle,
                                    year: movie.year ?? movie.detectedYear,
                                    posterPath: movie.posterPath,
                                    availabilityStatus: availability,
                                    isFavorite: movie.isFavorite,
                                    watchState: movie.watchState,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => MovieDetailScreen(
                                            movieId: movie.id,
                                            database: widget.database,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
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
