import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/query/episode_query.dart';
import '../../domain/query/movie_query.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/query/search_spec.dart';
import '../../domain/query/tv_show_query.dart';
import '../../domain/repository/library_repository.dart';
import '../movies/movie_detail_screen.dart';
import '../tv_shows/tv_show_detail_screen.dart';
import '../widgets/cinema_poster_card.dart';

/// Result type filter options for search tab bar.
enum SearchResultTypeFilter {
  all,
  movies,
  tvShows,
  episodes;

  String get label {
    switch (this) {
      case SearchResultTypeFilter.all:
        return 'All';
      case SearchResultTypeFilter.movies:
        return 'Movies';
      case SearchResultTypeFilter.tvShows:
        return 'TV Shows';
      case SearchResultTypeFilter.episodes:
        return 'Episodes';
    }
  }
}

/// Fast, offline local cinema search across movies, TV shows, and episodes with
/// debounce, search mode selector (Title vs All Fields), and result type tabs.
class SearchScreen extends StatefulWidget {
  final LibraryRepository repository;
  final AppDatabase? database;

  SearchScreen({
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
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  SearchMode _searchMode = SearchMode.title;
  SearchResultTypeFilter _typeFilter = SearchResultTypeFilter.all;

  List<MovieLibraryItem> _movieResults = [];
  List<TvShowLibraryItem> _showResults = [];
  List<EpisodeLibraryItem> _episodeResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
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

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _onSearchModeSelected(SearchMode mode) {
    if (_searchMode == mode) return;
    setState(() {
      _searchMode = mode;
    });
    if (_query.isNotEmpty) {
      _debounceTimer?.cancel();
      _performSearch(_query);
    }
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    final targetQuery = query;
    final targetMode = _searchMode;

    setState(() => _isSearching = true);

    try {
      final moviesFuture = widget.repository.getMovies(
        MovieQuery.search(targetQuery, mode: targetMode),
      );
      final showsFuture = widget.repository.getTvShows(
        TvShowQuery.search(targetQuery, mode: targetMode),
      );
      final episodesFuture = widget.repository.getEpisodes(
        EpisodeQuery.search(targetQuery, mode: targetMode),
      );

      final results = await Future.wait([
        moviesFuture,
        showsFuture,
        episodesFuture,
      ]);

      if (mounted && _query == targetQuery && _searchMode == targetMode) {
        setState(() {
          _movieResults = results[0] as List<MovieLibraryItem>;
          _showResults = results[1] as List<TvShowLibraryItem>;
          _episodeResults = results[2] as List<EpisodeLibraryItem>;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted && _query == targetQuery) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);
    final hasAnyResults =
        _movieResults.isNotEmpty ||
        _showResults.isNotEmpty ||
        _episodeResults.isNotEmpty;

    final showMovies =
        (_typeFilter == SearchResultTypeFilter.all ||
            _typeFilter == SearchResultTypeFilter.movies) &&
        _movieResults.isNotEmpty;
    final showTvShows =
        (_typeFilter == SearchResultTypeFilter.all ||
            _typeFilter == SearchResultTypeFilter.tvShows) &&
        _showResults.isNotEmpty;
    final showEpisodes =
        (_typeFilter == SearchResultTypeFilter.all ||
            _typeFilter == SearchResultTypeFilter.episodes) &&
        _episodeResults.isNotEmpty;

    final hasVisibleResults = showMovies || showTvShows || showEpisodes;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          style: TextStyle(color: theme.textPrimary, fontSize: 16),
          cursorColor: theme.accent,
          decoration: InputDecoration(
            hintText: 'Search movies, TV shows, episodes...',
            hintStyle: TextStyle(color: theme.textMuted),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: theme.textSecondary,
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
        actions: [
          PopupMenuButton<SearchMode>(
            icon: Icon(Icons.tune_rounded, color: theme.accent),
            tooltip: 'Search Mode',
            color: theme.surface,
            initialValue: _searchMode,
            onSelected: _onSearchModeSelected,
            itemBuilder: (context) => [
              _buildSearchModeMenuItem(context, SearchMode.all, 'All Fields'),
              _buildSearchModeMenuItem(context, SearchMode.title, 'Title'),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_query.isNotEmpty) _buildTypeFilterBar(context),
          Expanded(
            child: _query.isEmpty
                ? _buildEmptyPrompt(context)
                : _isSearching
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: null,
                        color: theme.accent,
                      ),
                    ),
                  )
                : !hasVisibleResults
                ? _buildNoResultsState(context, hasAnyResults)
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    children: [
                      // Movies Section
                      if (showMovies) ...[
                        Text(
                          'MOVIES (${_movieResults.length})',
                          style: CinemaTheme.eyebrow(context),
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
                        const SizedBox(height: 28),
                      ],

                      // TV Shows Section
                      if (showTvShows) ...[
                        Text(
                          'TV SHOWS (${_showResults.length})',
                          style: CinemaTheme.eyebrow(context),
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
                                      repository: widget.repository,
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
                      if (showEpisodes) ...[
                        Text(
                          'EPISODES (${_episodeResults.length})',
                          style: CinemaTheme.eyebrow(context),
                        ),
                        const SizedBox(height: 12),
                        ..._episodeResults.map((ep) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.surface2,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.play_circle_outline,
                                color: theme.accent,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              ep.displayName,
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              ep.overview != null && ep.overview!.isNotEmpty
                                  ? '${ep.episodeCode} • ${ep.overview}'
                                  : ep.episodeCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: theme.textMuted,
                              size: 20,
                            ),
                            onTap: ep.showId != null
                                ? () {
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
                                : null,
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTypeFilterChip(
              context,
              SearchResultTypeFilter.all,
              'All (${_movieResults.length + _showResults.length + _episodeResults.length})',
            ),
            const SizedBox(width: 8),
            _buildTypeFilterChip(
              context,
              SearchResultTypeFilter.movies,
              'Movies (${_movieResults.length})',
            ),
            const SizedBox(width: 8),
            _buildTypeFilterChip(
              context,
              SearchResultTypeFilter.tvShows,
              'TV Shows (${_showResults.length})',
            ),
            const SizedBox(width: 8),
            _buildTypeFilterChip(
              context,
              SearchResultTypeFilter.episodes,
              'Episodes (${_episodeResults.length})',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(
    BuildContext context,
    SearchResultTypeFilter filter,
    String label,
  ) {
    final theme = CinemaTheme.of(context);
    final isSelected = _typeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _typeFilter = filter);
        }
      },
      selectedColor: theme.surface2,
      backgroundColor: theme.surface,
      labelStyle: TextStyle(
        color: isSelected ? theme.accent : theme.textSecondary,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? theme.accent : theme.border),
      ),
    );
  }

  PopupMenuItem<SearchMode> _buildSearchModeMenuItem(
    BuildContext context,
    SearchMode mode,
    String label,
  ) {
    final theme = CinemaTheme.of(context);
    final isSelected = _searchMode == mode;
    return PopupMenuItem<SearchMode>(
      value: mode,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? theme.accent : theme.textPrimary,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (isSelected) Icon(Icons.check, color: theme.accent, size: 18),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt(BuildContext context) {
    final theme = CinemaTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 56, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Fast Local Cinema Search',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search operates instantly against your local library index without external network calls.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, bool hasAnyResults) {
    final theme = CinemaTheme.of(context);
    final filterName = switch (_typeFilter) {
      SearchResultTypeFilter.all => '',
      SearchResultTypeFilter.movies => 'in Movies',
      SearchResultTypeFilter.tvShows => 'in TV Shows',
      SearchResultTypeFilter.episodes => 'in Episodes',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              filterName.isNotEmpty
                  ? 'No matches for "$_query" $filterName'
                  : 'No matches for "$_query"',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyResults
                  ? 'Try switching to the "All" tab to view results in other categories.'
                  : 'Try searching for a different title, year, or keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            if (hasAnyResults && _typeFilter != SearchResultTypeFilter.all) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _typeFilter = SearchResultTypeFilter.all),
                icon: const Icon(Icons.apps, size: 16),
                label: const Text('Show All Results'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
