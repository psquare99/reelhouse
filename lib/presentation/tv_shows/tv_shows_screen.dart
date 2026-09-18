import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../domain/query/query.dart';
import '../../domain/repository/library_repository.dart';
import '../widgets/cinema_poster_card.dart';
import 'tv_show_detail_screen.dart';

/// Poster-first TV series catalogue grid with user library state filters.
class TvShowsScreen extends StatefulWidget {
  final LibraryRepository repository;
  final AppDatabase database;

  const TvShowsScreen({
    super.key,
    required this.repository,
    required this.database,
  });

  @override
  State<TvShowsScreen> createState() => _TvShowsScreenState();
}

class _TvShowsScreenState extends State<TvShowsScreen> {
  String _filter = 'ALL'; // 'ALL' | 'FAVORITES' | 'WATCHLIST' | 'IN_PROGRESS' | 'UNWATCHED' | 'AVAILABLE' | 'UNAVAILABLE'
  TvShowSortField _sortField = TvShowSortField.title;
  SortDirection _sortDirection = SortDirection.asc;

  TvShowFilter _buildFilter() {
    switch (_filter) {
      case 'FAVORITES':
        return const TvShowFilter(isFavorite: true);
      case 'WATCHLIST':
        return const TvShowFilter(isWatchlist: true);
      case 'IN_PROGRESS':
        return const TvShowFilter(watchStates: {WatchState.inProgress});
      case 'UNWATCHED':
        return const TvShowFilter(watchStates: {WatchState.unwatched});
      case 'AVAILABLE':
        return const TvShowFilter(availability: AvailabilityFilter.available);
      case 'UNAVAILABLE':
        return const TvShowFilter(availability: AvailabilityFilter.unavailable);
      case 'ALL':
      default:
        return TvShowFilter.empty;
    }
  }

  TvShowQuery _buildQuery() {
    return TvShowQuery(
      filter: _buildFilter(),
      sort: [SortClause(_sortField, direction: _sortDirection)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Shows'),
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
          PopupMenuButton<TvShowSortField>(
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
              _buildSortMenuItem(TvShowSortField.title, 'Title'),
              _buildSortMenuItem(
                TvShowSortField.firstAirDate,
                'First Air Date',
              ),
              _buildSortMenuItem(TvShowSortField.rating, 'Rating'),
              _buildSortMenuItem(TvShowSortField.createdAt, 'Date Added'),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<LibraryResult<TvShowLibraryItem>>(
        stream: widget.repository.watchTvShows(query),
        builder: (context, snapshot) {
          final allShows = snapshot.data?.items ?? [];

          if (allShows.isEmpty) {
            if (_filter == 'ALL') {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tv_outlined,
                        size: 56,
                        color: CinemaColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No TV shows discovered yet.',
                        style: TextStyle(
                          color: CinemaColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan a storage location containing TV series and season folders.',
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
                          'No TV shows matching this filter.',
                          style: TextStyle(color: CinemaColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => setState(() => _filter = 'ALL'),
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Show All TV Shows'),
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
                  itemCount: allShows.length,
                  itemBuilder: (context, index) {
                    final show = allShows[index];
                    return CinemaPosterCard(
                      title: show.displayTitle,
                      year: show.displayYear,
                      posterPath: show.posterPath,
                      isFavorite: show.isFavorite,
                      availabilityStatus: show.availability,
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

  PopupMenuItem<TvShowSortField> _buildSortMenuItem(
    TvShowSortField field,
    String label,
  ) {
    final isSelected = _sortField == field;
    return PopupMenuItem<TvShowSortField>(
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
