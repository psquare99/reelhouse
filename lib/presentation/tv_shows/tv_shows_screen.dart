import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../widgets/cinema_poster_card.dart';
import 'tv_show_detail_screen.dart';

/// Poster-first TV series catalogue grid with user library state filters.
class TvShowsScreen extends StatefulWidget {
  final AppDatabase database;

  const TvShowsScreen({super.key, required this.database});

  @override
  State<TvShowsScreen> createState() => _TvShowsScreenState();
}

class _TvShowsScreenState extends State<TvShowsScreen> {
  String _filter = 'ALL'; // 'ALL' | 'FAVORITES' | 'WATCHLIST'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TV Shows')),
      body: StreamBuilder<List<TvShow>>(
        stream: widget.database.select(widget.database.tvShows).watch(),
        builder: (context, snapshot) {
          final allShows = snapshot.data ?? [];

          final filteredShows = allShows.where((s) {
            switch (_filter) {
              case 'FAVORITES':
                return s.isFavorite;
              case 'WATCHLIST':
                return s.isWatchlist;
              case 'ALL':
              default:
                return true;
            }
          }).toList();

          if (allShows.isEmpty) {
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
              // Filter bar
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
                      _buildFilterChip('ALL', 'All (${allShows.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'FAVORITES',
                        'Favorites (${allShows.where((s) => s.isFavorite).length})',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'WATCHLIST',
                        'Watchlist (${allShows.where((s) => s.isWatchlist).length})',
                      ),
                    ],
                  ),
                ),
              ),

              // Poster Grid
              Expanded(
                child: filteredShows.isEmpty
                    ? Center(
                        child: Text(
                          'No TV shows matching this filter.',
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
                        itemCount: filteredShows.length,
                        itemBuilder: (context, index) {
                          final show = filteredShows[index];
                          return CinemaPosterCard(
                            title: show.title ?? show.detectedTitle,
                            year: show.firstAirDate?.year,
                            posterPath: show.posterPath,
                            isFavorite: show.isFavorite,
                            fallbackIcon: Icons.tv,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TvShowDetailScreen(
                                    showId: show.id,
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
