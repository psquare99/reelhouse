import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../domain/query/query.dart';
import '../../domain/repository/library_repository.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_loading_skeleton.dart';
import '../widgets/cinema_poster_card.dart';
import 'movie_detail_screen.dart';

/// Poster-first movie catalogue grid with availability and user library state indicators.
class MoviesScreen extends StatefulWidget {
  final LibraryRepository repository;
  final AppDatabase database;

  const MoviesScreen({
    super.key,
    required this.repository,
    required this.database,
  });

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  String _filter = 'ALL'; // 'ALL' | 'FAVORITES' | 'WATCHLIST' | 'IN_PROGRESS' | 'UNWATCHED' | 'AVAILABLE' | 'UNAVAILABLE'
  MovieSortField _sortField = MovieSortField.title;
  SortDirection _sortDirection = SortDirection.asc;

  MovieFilter _buildFilter() {
    switch (_filter) {
      case 'FAVORITES':
        return const MovieFilter(isFavorite: true);
      case 'WATCHLIST':
        return const MovieFilter(isWatchlist: true);
      case 'IN_PROGRESS':
        return const MovieFilter(watchStates: {WatchState.inProgress});
      case 'UNWATCHED':
        return const MovieFilter(watchStates: {WatchState.unwatched});
      case 'AVAILABLE':
        return const MovieFilter(availability: AvailabilityFilter.available);
      case 'UNAVAILABLE':
        return const MovieFilter(availability: AvailabilityFilter.unavailable);
      case 'ALL':
      default:
        return MovieFilter.empty;
    }
  }

  MovieQuery _buildQuery() {
    return MovieQuery(
      filter: _buildFilter(),
      sort: [SortClause(_sortField, direction: _sortDirection)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        actions: [
          IconButton(
            icon: Icon(
              _sortDirection.isAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: CinemaColors.amber,
              size: 20,
            ),
            tooltip: _sortDirection.isAscending ? 'Ascending' : 'Descending',
            onPressed: () {
              setState(() {
                _sortDirection = _sortDirection.isAscending
                    ? SortDirection.desc
                    : SortDirection.asc;
              });
            },
          ),
          PopupMenuButton<MovieSortField>(
            icon: const Icon(Icons.sort_rounded, color: CinemaColors.amber),
            tooltip: 'Sort by',
            color: CinemaColors.card,
            initialValue: _sortField,
            onSelected: (field) {
              setState(() {
                _sortField = field;
              });
            },
            itemBuilder: (context) => [
              _buildSortMenuItem(MovieSortField.title, 'Title'),
              _buildSortMenuItem(MovieSortField.year, 'Release Year'),
              _buildSortMenuItem(MovieSortField.rating, 'Rating'),
              _buildSortMenuItem(MovieSortField.createdAt, 'Date Added'),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<LibraryResult<MovieLibraryItem>>(
        stream: widget.repository.watchMovies(query),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CinemaErrorState(
              title: 'Unable to Load Movies',
              message: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Column(
              children: [
                _buildFilterBar(),
                const Expanded(child: CinemaGridSkeleton()),
              ],
            );
          }

          final movies = snapshot.data?.items ?? [];

          if (movies.isEmpty) {
            if (_filter == 'ALL') {
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
                _buildFilterBar(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No movies matching this filter.',
                          style: TextStyle(color: CinemaColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => setState(() => _filter = 'ALL'),
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Show All Movies'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 28,
                    mainAxisSpacing: 32,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];

                    return CinemaPosterCard(
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
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('ALL', 'All'),
            const SizedBox(width: 8),
            _buildFilterChip('FAVORITES', 'Favorites'),
            const SizedBox(width: 8),
            _buildFilterChip('WATCHLIST', 'Watchlist'),
            const SizedBox(width: 8),
            _buildFilterChip('IN_PROGRESS', 'In Progress'),
            const SizedBox(width: 8),
            _buildFilterChip('UNWATCHED', 'Unwatched'),
            const SizedBox(width: 8),
            _buildFilterChip('AVAILABLE', 'Available'),
            const SizedBox(width: 8),
            _buildFilterChip('UNAVAILABLE', 'Unavailable'),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<MovieSortField> _buildSortMenuItem(
    MovieSortField field,
    String label,
  ) {
    final isSelected = _sortField == field;
    return PopupMenuItem<MovieSortField>(
      value: field,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? CinemaColors.amber : CinemaColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (isSelected)
            const Icon(Icons.check, color: CinemaColors.amber, size: 18),
        ],
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
