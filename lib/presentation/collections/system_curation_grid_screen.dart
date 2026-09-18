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

/// Screen presenting catalogue views (e.g. Genre or Franchise grouping)
/// over the user's local cinema catalogue.
class SystemCurationGridScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);
    final isFranchise = tmdbCollectionId != null || tmdbCollectionName != null;

    final movieQuery = MovieQuery(
      filter: MovieFilter(
        genre: genre,
        tmdbCollectionId: tmdbCollectionId,
        tmdbCollectionName: tmdbCollectionName,
      ),
    );

    final tvQuery = genre != null
        ? TvShowQuery(filter: TvShowFilter(genre: genre))
        : null;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: subtitle != null && subtitle!.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              )
            : Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movies Section
            StreamBuilder<LibraryResult<MovieLibraryItem>>(
              stream: repository.watchMovies(movieQuery),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return CinemaErrorState(
                    title: 'Unable to Load Movies',
                    message: snapshot.error.toString(),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const CinemaGridSkeleton();
                }

                final movies = snapshot.data?.items ?? [];

                if (movies.isEmpty && isFranchise) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.movie_outlined,
                            size: 48,
                            color: tokens.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No movies found for $title',
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (movies.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isFranchise) ...[
                      Row(
                        children: [
                          Text(
                            'MOVIES (${movies.length})',
                            style: CinemaTheme.eyebrow(context, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(height: 1, color: tokens.border),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildMoviesGrid(context, movies),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),

            // TV Shows Section (Only for Genres)
            if (tvQuery != null)
              StreamBuilder<LibraryResult<TvShowLibraryItem>>(
                stream: repository.watchTvShows(tvQuery),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final shows = snapshot.data?.items ?? [];
                  if (shows.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'TV SHOWS (${shows.length})',
                            style: CinemaTheme.eyebrow(context, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(height: 1, color: tokens.border),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTvShowsGrid(context, shows),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
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
                  repository: repository,
                  database: database,
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
                  repository: repository,
                  database: database,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
