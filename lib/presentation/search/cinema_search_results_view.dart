import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
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

/// Reusable search results view for displaying live matches across movies,
/// TV series, and episodes with category tabs and cinematic cards.
class CinemaSearchResultsView extends StatefulWidget {
  final LibraryRepository repository;
  final AppDatabase? database;
  final String query;
  final SearchMode searchMode;
  final VoidCallback? onDismiss;

  const CinemaSearchResultsView({
    super.key,
    required this.repository,
    this.database,
    required this.query,
    this.searchMode = SearchMode.title,
    this.onDismiss,
  });

  @override
  State<CinemaSearchResultsView> createState() =>
      _CinemaSearchResultsViewState();
}

class _CinemaSearchResultsViewState extends State<CinemaSearchResultsView> {
  SearchResultTypeFilter _typeFilter = SearchResultTypeFilter.all;
  List<MovieLibraryItem> _movieResults = [];
  List<TvShowLibraryItem> _showResults = [];
  List<EpisodeLibraryItem> _episodeResults = [];
  bool _isLoading = false;
  String _activeQuery = '';
  SearchMode _activeMode = SearchMode.title;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  @override
  void didUpdateWidget(CinemaSearchResultsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.searchMode != widget.searchMode) {
      _fetchResults();
    }
  }

  Future<void> _fetchResults() async {
    final targetQuery = widget.query.trim();
    final targetMode = widget.searchMode;

    if (targetQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _movieResults = [];
          _showResults = [];
          _episodeResults = [];
          _isLoading = false;
          _activeQuery = '';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _activeQuery = targetQuery;
      _activeMode = targetMode;
    });

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

      if (mounted &&
          widget.query.trim() == targetQuery &&
          widget.searchMode == targetMode) {
        setState(() {
          _movieResults = results[0] as List<MovieLibraryItem>;
          _showResults = results[1] as List<TvShowLibraryItem>;
          _episodeResults = results[2] as List<EpisodeLibraryItem>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && widget.query.trim() == targetQuery) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);
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

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: tokens.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Searching catalogue...',
                style: TextStyle(color: tokens.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasAnyResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 56, color: tokens.textMuted),
              const SizedBox(height: 16),
              Text(
                'No titles found for "$_activeQuery"',
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _activeMode == SearchMode.title
                    ? 'Try switching search mode to "All Fields" or check your spelling.'
                    : 'Check your spelling or try searching by keyword or director.',
                style: TextStyle(color: tokens.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeFilterBar(context, tokens),
        if (!hasVisibleResults)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No ${_typeFilter.label} matching "$_activeQuery"',
                style: TextStyle(color: tokens.textSecondary, fontSize: 14),
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                if (showMovies) ...[
                  _buildSectionHeader(
                    context,
                    tokens,
                    'MOVIES (${_movieResults.length})',
                  ),
                  const SizedBox(height: 12),
                  _buildMoviesGrid(context),
                  const SizedBox(height: 24),
                ],
                if (showTvShows) ...[
                  _buildSectionHeader(
                    context,
                    tokens,
                    'TV SHOWS (${_showResults.length})',
                  ),
                  const SizedBox(height: 12),
                  _buildTvShowsGrid(context),
                  const SizedBox(height: 24),
                ],
                if (showEpisodes) ...[
                  _buildSectionHeader(
                    context,
                    tokens,
                    'EPISODES (${_episodeResults.length})',
                  ),
                  const SizedBox(height: 12),
                  _buildEpisodesList(context, tokens),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTypeFilterBar(BuildContext context, CinemaThemeData tokens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: SearchResultTypeFilter.values.map((type) {
          final isSelected = _typeFilter == type;
          int count = 0;
          switch (type) {
            case SearchResultTypeFilter.all:
              count =
                  _movieResults.length +
                  _showResults.length +
                  _episodeResults.length;
              break;
            case SearchResultTypeFilter.movies:
              count = _movieResults.length;
              break;
            case SearchResultTypeFilter.tvShows:
              count = _showResults.length;
              break;
            case SearchResultTypeFilter.episodes:
              count = _episodeResults.length;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${type.label} ($count)'),
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
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              onSelected: (_) {
                setState(() => _typeFilter = type);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    CinemaThemeData tokens,
    String title,
  ) {
    return Row(
      children: [
        Text(title, style: CinemaTheme.eyebrow(context, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: tokens.border)),
      ],
    );
  }

  Widget _buildMoviesGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
        ? 6
        : width > 900
        ? 5
        : width > 600
        ? 4
        : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.58,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: _movieResults.length,
      itemBuilder: (context, index) {
        final movie = _movieResults[index];
        return CinemaPosterCard(
          title: movie.displayTitle,
          subtitle: movie.displayYear?.toString() ?? '',
          posterPath: movie.posterPath,
          availability: movie.availability,
          isFavorite: movie.isFavorite,
          isWatchlist: movie.isWatchlist,
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
    );
  }

  Widget _buildTvShowsGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
        ? 6
        : width > 900
        ? 5
        : width > 600
        ? 4
        : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.58,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: _showResults.length,
      itemBuilder: (context, index) {
        final show = _showResults[index];
        return CinemaPosterCard(
          title: show.displayTitle,
          subtitle: show.displayYear != null ? '${show.displayYear}' : '',
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
    );
  }

  Widget _buildEpisodesList(BuildContext context, CinemaThemeData tokens) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _episodeResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final episode = _episodeResults[index];
        return Container(
          decoration: BoxDecoration(
            color: tokens.surface1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tokens.surface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  'E${episode.episodeNumber}',
                  style: TextStyle(
                    color: tokens.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            title: Text(
              episode.displayName,
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: episode.overview != null && episode.overview!.isNotEmpty
                ? Text(
                    episode.overview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                  )
                : null,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: tokens.textSecondary,
              size: 20,
            ),
            onTap: episode.showId != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TvShowDetailScreen(
                          showId: episode.showId!,
                          repository: widget.repository,
                          database: widget.database,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        );
      },
    );
  }
}
