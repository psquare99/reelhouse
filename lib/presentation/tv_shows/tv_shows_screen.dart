import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../domain/query/query.dart';
import '../../domain/repository/library_repository.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_loading_skeleton.dart';
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
    final tokens = CinemaTheme.of(context);
    final query = _buildQuery();

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: const Text('TV Shows'),
        actions: [
          IconButton(
            icon: Icon(
              _sortDirection.isAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: tokens.accent,
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
            icon: Icon(Icons.sort_rounded, color: tokens.accent),
            tooltip: 'Sort by',
            color: tokens.surface2,
            initialValue: _sortField,
            onSelected: (field) {
              setState(() {
                _sortField = field;
              });
            },
            itemBuilder: (context) => [
              _buildSortMenuItem(context, TvShowSortField.title, 'Title'),
              _buildSortMenuItem(
                context,
                TvShowSortField.firstAirDate,
                'First Air Date',
              ),
              _buildSortMenuItem(context, TvShowSortField.rating, 'Rating'),
              _buildSortMenuItem(
                context,
                TvShowSortField.createdAt,
                'Date Added',
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<LibraryResult<TvShowLibraryItem>>(
        stream: widget.repository.watchTvShows(query),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CinemaErrorState(
              title: 'Unable to Load TV Shows',
              message: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Column(
              children: [
                _buildFilterBar(context, tokens),
                const Expanded(child: CinemaGridSkeleton()),
              ],
            );
          }

          final allShows = snapshot.data?.items ?? [];

          if (allShows.isEmpty) {
            if (_filter == 'ALL') {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tv_outlined,
                        size: 56,
                        color: tokens.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No TV shows discovered yet.',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan a storage location containing TV series and season folders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: tokens.textSecondary,
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
                _buildFilterBar(context, tokens),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No TV shows matching this filter.',
                          style: TextStyle(color: tokens.textMuted),
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
              _buildFilterBar(context, tokens),
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

  Widget _buildFilterBar(BuildContext context, CinemaThemeData tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(tokens, 'ALL', 'All'),
            const SizedBox(width: 8),
            _buildFilterChip(tokens, 'FAVORITES', 'Favorites'),
            const SizedBox(width: 8),
            _buildFilterChip(tokens, 'WATCHLIST', 'Watchlist'),
            const SizedBox(width: 8),
            _buildFilterChip(tokens, 'IN_PROGRESS', 'In Progress'),
            const SizedBox(width: 8),
            _buildFilterChip(tokens, 'UNWATCHED', 'Unwatched'),
            const SizedBox(width: 8),
            _buildFilterChip(tokens, 'AVAILABLE', 'Available'),
            const SizedBox(width: 8),
            _buildFilterChip(tokens, 'UNAVAILABLE', 'Unavailable'),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<TvShowSortField> _buildSortMenuItem(
    BuildContext context,
    TvShowSortField field,
    String label,
  ) {
    final tokens = CinemaTheme.of(context);
    final isSelected = _sortField == field;
    return PopupMenuItem<TvShowSortField>(
      value: field,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? tokens.accent : tokens.textPrimary,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (isSelected) Icon(Icons.check, color: tokens.accent, size: 18),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    CinemaThemeData tokens,
    String filterKey,
    String label,
  ) {
    final isSelected = _filter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = filterKey);
        }
      },
      selectedColor: tokens.accent.withValues(alpha: 0.14),
      backgroundColor: tokens.surface1,
      labelStyle: TextStyle(
        color: isSelected ? tokens.accent : tokens.textSecondary,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? tokens.accent : tokens.border,
          width: 1,
        ),
      ),
    );
  }
}
