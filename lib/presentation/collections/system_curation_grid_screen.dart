import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../domain/query/filter_spec.dart';
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

/// Supported media-type filtering modes on the curation grid screen.
enum CurationMediaTypeFilter {
  all('All'),
  movies('Movies'),
  tvShows('TV Shows');

  final String label;
  const CurationMediaTypeFilter(this.label);
}

/// Screen presenting catalogue views (e.g. Genre or Franchise grouping)
/// over the user's local cinema catalogue with compact media-type filtering.
class SystemCurationGridScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? genre;
  final int? tmdbCollectionId;
  final String? tmdbCollectionName;
  final LibraryRepository repository;
  final AppDatabase? database;

  const SystemCurationGridScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.genre,
    this.tmdbCollectionId,
    this.tmdbCollectionName,
    required this.repository,
    this.database,
  });

  @override
  State<SystemCurationGridScreen> createState() =>
      _SystemCurationGridScreenState();
}

class _SystemCurationGridScreenState extends State<SystemCurationGridScreen> {
  CurationMediaTypeFilter _mediaTypeFilter = CurationMediaTypeFilter.all;

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);
    final isFranchise =
        widget.tmdbCollectionId != null || widget.tmdbCollectionName != null;

    final movieQuery = _mediaTypeFilter == CurationMediaTypeFilter.tvShows
        ? null
        : MovieQuery(
            filter: MovieFilter(
              genre: widget.genre,
              tmdbCollectionId: widget.tmdbCollectionId,
              tmdbCollectionName: widget.tmdbCollectionName,
            ),
          );

    final tvQuery =
        (_mediaTypeFilter == CurationMediaTypeFilter.movies ||
            widget.genre == null)
        ? null
        : TvShowQuery(filter: TvShowFilter(genre: widget.genre));

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: widget.subtitle != null && widget.subtitle!.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              )
            : Text(widget.title),
        actions: [
          if (widget.genre != null && !isFranchise)
            PopupMenuButton<CurationMediaTypeFilter>(
              tooltip: 'Filter by media type',
              color: tokens.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: tokens.border, width: 1),
              ),
              offset: const Offset(0, 40),
              onSelected: (filter) {
                setState(() {
                  _mediaTypeFilter = filter;
                });
              },
              itemBuilder: (context) => [
                _buildFilterMenuItem(
                  context,
                  tokens,
                  CurationMediaTypeFilter.all,
                ),
                _buildFilterMenuItem(
                  context,
                  tokens,
                  CurationMediaTypeFilter.movies,
                ),
                _buildFilterMenuItem(
                  context,
                  tokens,
                  CurationMediaTypeFilter.tvShows,
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: tokens.surface1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.border, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _mediaTypeFilter.label,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: tokens.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: _buildBody(context, tokens, isFranchise, movieQuery, tvQuery),
      ),
    );
  }

  PopupMenuItem<CurationMediaTypeFilter> _buildFilterMenuItem(
    BuildContext context,
    CinemaThemeData tokens,
    CurationMediaTypeFilter filter,
  ) {
    final isSelected = _mediaTypeFilter == filter;
    return PopupMenuItem<CurationMediaTypeFilter>(
      value: filter,
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            filter.label,
            style: TextStyle(
              color: isSelected ? tokens.accent : tokens.textPrimary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_rounded, color: tokens.accent, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CinemaThemeData tokens,
    bool isFranchise,
    MovieQuery? movieQuery,
    TvShowQuery? tvQuery,
  ) {
    if (movieQuery != null && tvQuery != null) {
      // Both Movies and TV Shows (All mode)
      return StreamBuilder<LibraryResult<MovieLibraryItem>>(
        stream: widget.repository.watchMovies(movieQuery),
        builder: (context, movieSnapshot) {
          if (movieSnapshot.hasError) {
            return CinemaErrorState(
              title: 'Unable to Load Movies',
              message: movieSnapshot.error.toString(),
            );
          }

          return StreamBuilder<LibraryResult<TvShowLibraryItem>>(
            stream: widget.repository.watchTvShows(tvQuery),
            builder: (context, tvSnapshot) {
              if (tvSnapshot.hasError) {
                return CinemaErrorState(
                  title: 'Unable to Load TV Shows',
                  message: tvSnapshot.error.toString(),
                );
              }

              final isWaiting =
                  (movieSnapshot.connectionState == ConnectionState.waiting &&
                      !movieSnapshot.hasData) ||
                  (tvSnapshot.connectionState == ConnectionState.waiting &&
                      !tvSnapshot.hasData);

              if (isWaiting) {
                return const CinemaGridSkeleton();
              }

              final movies = movieSnapshot.data?.items ?? [];
              final shows = tvSnapshot.data?.items ?? [];

              if (movies.isEmpty && shows.isEmpty) {
                return _buildEmptyState(
                  context,
                  tokens,
                  'No media found for ${widget.title}',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (movies.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      tokens,
                      'MOVIES (${movies.length})',
                    ),
                    const SizedBox(height: 16),
                    _buildMoviesGrid(context, movies),
                    if (shows.isNotEmpty) const SizedBox(height: 32),
                  ],
                  if (shows.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      tokens,
                      'TV SHOWS (${shows.length})',
                    ),
                    const SizedBox(height: 16),
                    _buildTvShowsGrid(context, shows),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            },
          );
        },
      );
    } else if (movieQuery != null) {
      // Movies only
      return StreamBuilder<LibraryResult<MovieLibraryItem>>(
        stream: widget.repository.watchMovies(movieQuery),
        builder: (context, movieSnapshot) {
          if (movieSnapshot.hasError) {
            return CinemaErrorState(
              title: 'Unable to Load Movies',
              message: movieSnapshot.error.toString(),
            );
          }

          if (movieSnapshot.connectionState == ConnectionState.waiting &&
              !movieSnapshot.hasData) {
            return const CinemaGridSkeleton();
          }

          final movies = movieSnapshot.data?.items ?? [];
          if (movies.isEmpty) {
            return _buildEmptyState(
              context,
              tokens,
              'No movies found for ${widget.title}',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isFranchise) ...[
                _buildSectionHeader(
                  context,
                  tokens,
                  'MOVIES (${movies.length})',
                ),
                const SizedBox(height: 16),
              ],
              _buildMoviesGrid(context, movies),
              const SizedBox(height: 32),
            ],
          );
        },
      );
    } else if (tvQuery != null) {
      // TV Shows only
      return StreamBuilder<LibraryResult<TvShowLibraryItem>>(
        stream: widget.repository.watchTvShows(tvQuery),
        builder: (context, tvSnapshot) {
          if (tvSnapshot.hasError) {
            return CinemaErrorState(
              title: 'Unable to Load TV Shows',
              message: tvSnapshot.error.toString(),
            );
          }

          if (tvSnapshot.connectionState == ConnectionState.waiting &&
              !tvSnapshot.hasData) {
            return const CinemaGridSkeleton();
          }

          final shows = tvSnapshot.data?.items ?? [];
          if (shows.isEmpty) {
            return _buildEmptyState(
              context,
              tokens,
              'No TV shows found for ${widget.title}',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                tokens,
                'TV SHOWS (${shows.length})',
              ),
              const SizedBox(height: 16),
              _buildTvShowsGrid(context, shows),
              const SizedBox(height: 24),
            ],
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(
    BuildContext context,
    CinemaThemeData tokens,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_outlined, size: 48, color: tokens.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: tokens.textPrimary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  Widget _buildMoviesGrid(BuildContext context, List<MovieLibraryItem> movies) {
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
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
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

  Widget _buildTvShowsGrid(
    BuildContext context,
    List<TvShowLibraryItem> shows,
  ) {
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
      itemCount: shows.length,
      itemBuilder: (context, index) {
        final show = shows[index];
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
}
