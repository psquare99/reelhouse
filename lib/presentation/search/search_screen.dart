import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../movies/movie_detail_screen.dart';
import '../tv_shows/tv_show_detail_screen.dart';
import '../widgets/cinema_poster_card.dart';

/// Fast, offline local cinema search across movies, TV shows, and episodes.
class SearchScreen extends StatefulWidget {
  final AppDatabase database;

  const SearchScreen({super.key, required this.database});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  List<Movie> _movieResults = [];
  List<TvShow> _showResults = [];
  List<Episode> _episodeResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) async {
    final query = val.trim();
    setState(() {
      _query = query;
    });

    if (query.isEmpty) {
      setState(() {
        _movieResults = [];
        _showResults = [];
        _episodeResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final movies = await widget.database.searchMovies(query);
    final shows = await widget.database.searchTvShows(query);
    final episodes = await widget.database.searchEpisodes(query);

    if (mounted && _query == query) {
      setState(() {
        _movieResults = movies;
        _showResults = shows;
        _episodeResults = episodes;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults =
        _movieResults.isNotEmpty ||
        _showResults.isNotEmpty ||
        _episodeResults.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          style: const TextStyle(color: CinemaColors.textPrimary, fontSize: 16),
          cursorColor: CinemaColors.amber,
          decoration: InputDecoration(
            hintText: 'Search movies, TV shows, episodes...',
            hintStyle: const TextStyle(color: CinemaColors.textMuted),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: CinemaColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search,
                      size: 56,
                      color: CinemaColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fast Local Cinema Search',
                      style: TextStyle(
                        color: CinemaColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Search operates instantly against your local library index without external network calls.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CinemaColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _isSearching
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: 0.0,
                  color: CinemaColors.amber,
                ),
              ),
            )
          : !hasResults
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 48,
                      color: CinemaColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No matches for "$_query"',
                      style: const TextStyle(
                        color: CinemaColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Try searching for a different title, year, or keyword.',
                      style: TextStyle(
                        color: CinemaColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                // Movies Section
                if (_movieResults.isNotEmpty) ...[
                  Text(
                    'MOVIES (${_movieResults.length})',
                    style: const TextStyle(
                      color: CinemaColors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemCount: _movieResults.length,
                    itemBuilder: (context, index) {
                      final movie = _movieResults[index];
                      return CinemaPosterCard(
                        title: movie.title ?? movie.detectedTitle,
                        year: movie.year ?? movie.detectedYear,
                        posterPath: movie.posterPath,
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
                  ),
                  const SizedBox(height: 28),
                ],

                // TV Shows Section
                if (_showResults.isNotEmpty) ...[
                  Text(
                    'TV SHOWS (${_showResults.length})',
                    style: const TextStyle(
                      color: CinemaColors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemCount: _showResults.length,
                    itemBuilder: (context, index) {
                      final show = _showResults[index];
                      return CinemaPosterCard(
                        title: show.title ?? show.detectedTitle,
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
                  const SizedBox(height: 28),
                ],

                // Episodes Section
                if (_episodeResults.isNotEmpty) ...[
                  Text(
                    'EPISODES (${_episodeResults.length})',
                    style: const TextStyle(
                      color: CinemaColors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._episodeResults.map((ep) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.play_circle_outline,
                        color: CinemaColors.amber,
                      ),
                      title: Text(
                        ep.name ?? 'Episode ${ep.episodeNumber}',
                        style: const TextStyle(
                          color: CinemaColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: ep.overview != null
                          ? Text(
                              ep.overview!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CinemaColors.textSecondary,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
