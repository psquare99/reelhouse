import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../domain/query/query.dart';
import '../../domain/repository/library_repository.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_loading_skeleton.dart';
import '../widgets/cinema_poster_card.dart';
import 'tv_show_detail_screen.dart';

/// Poster-first TV series catalogue grid with contextual search and user library state filters.
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
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  String _searchQuery = '';

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
      search: _searchQuery.isNotEmpty ? SearchSpec(query: _searchQuery) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);
    final query = _buildQuery();

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: _isSearchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: tokens.textPrimary, fontSize: 16),
                cursorColor: tokens.accent,
                decoration: InputDecoration(
                  hintText: 'Search TV shows & episodes...',
                  hintStyle: TextStyle(color: tokens.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('TV Shows'),
        actions: [
          if (_isSearchOpen) ...[
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear_rounded, color: tokens.textSecondary),
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  _searchDebounceTimer?.cancel();
                  setState(() => _searchQuery = '');
                },
              ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: tokens.textSecondary),
              tooltip: 'Close search',
              onPressed: () {
                _searchController.clear();
                _searchDebounceTimer?.cancel();
                setState(() {
                  _isSearchOpen = false;
                  _searchQuery = '';
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.search_rounded, color: tokens.accent),
              tooltip: 'Search TV Shows',
              onPressed: () {
                setState(() => _isSearchOpen = true);
              },
            ),
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
                _buildSortMenuItem(
                  context,
                  TvShowSortField.lastAirDate,
                  'Latest Air Date',
                ),
                _buildSortMenuItem(context, TvShowSortField.rating, 'Rating'),
                _buildSortMenuItem(
                  context,
                  TvShowSortField.createdAt,
                  'Date Added',
                ),
              ],
            ),
          ],
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

          final shows = snapshot.data?.items ?? [];

          if (shows.isEmpty) {
            if (_searchQuery.isNotEmpty) {
              return Column(
                children: [
                  _buildFilterBar(context, tokens),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: tokens.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No TV shows found for "$_searchQuery"',
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear Search'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

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
                        'Register and scan a storage location to populate your TV catalogue.',
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
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: shows.length,
                  itemBuilder: (context, index) {
                    final show = shows[index];
                    return CinemaPosterCard(
                      title: show.displayTitle,
                      subtitle: show.displayYear != null
                          ? '${show.displayYear}'
                          : '',
                      posterPath: show.posterPath,
                      availability: show.availability,
                      isFavorite: show.isFavorite,
                      isWatchlist: show.isWatchlist,
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
    final filters = [
      {'id': 'ALL', 'label': 'All'},
      {'id': 'AVAILABLE', 'label': 'Available'},
      {'id': 'IN_PROGRESS', 'label': 'In Progress'},
      {'id': 'UNWATCHED', 'label': 'Unwatched'},
      {'id': 'FAVORITES', 'label': 'Favorites'},
      {'id': 'WATCHLIST', 'label': 'Watchlist'},
      {'id': 'UNAVAILABLE', 'label': 'Unavailable'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _filter == f['id'];

          return ChoiceChip(
            label: Text(f['label']!),
            selected: isSelected,
            showCheckmark: false,
            backgroundColor: tokens.surface1,
            selectedColor: tokens.accent.withValues(alpha: 0.2),
            side: BorderSide(
              color: isSelected ? tokens.accent : tokens.border,
              width: 1,
            ),
            labelStyle: TextStyle(
              color: isSelected ? tokens.accent : tokens.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _filter = f['id']!;
                });
              }
            },
          );
        },
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
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (isSelected)
            Icon(Icons.check_rounded, color: tokens.accent, size: 18),
        ],
      ),
    );
  }
}
