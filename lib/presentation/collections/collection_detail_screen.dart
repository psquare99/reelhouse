import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/query/library_result.dart';
import '../../domain/query/movie_query.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/query/tv_show_query.dart';
import '../../domain/repository/library_repository.dart';
import '../movies/movie_detail_screen.dart';
import '../tv_shows/tv_show_detail_screen.dart';
import '../widgets/cinema_poster_card.dart';

/// Detailed view of a curated user collection with contained movies and TV shows.
class CollectionDetailScreen extends StatelessWidget {
  final String collectionId;
  final LibraryRepository repository;
  final AppDatabase? database;

  CollectionDetailScreen({
    super.key,
    required this.collectionId,
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

  void _showAddMediaDialog(BuildContext context) async {
    final allMovies = await repository.getMovies(MovieQuery.all());
    final allShows = await repository.getTvShows(TvShowQuery.all());
    final currentMovies = await repository.getMovies(
      MovieQuery.forCollection(collectionId),
    );
    final currentShows = await repository.getTvShows(
      TvShowQuery.forCollection(collectionId),
    );
    final existingMovieIds = currentMovies.map((m) => m.id).toSet();
    final existingShowIds = currentShows.map((s) => s.id).toSet();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: CinemaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Media to Collection',
                        style: TextStyle(
                          color: CinemaColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: CinemaColors.textSecondary,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: CinemaColors.borderSubtle),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        if (allMovies.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'MOVIES',
                              style: TextStyle(
                                color: CinemaColors.amber,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...allMovies.map((m) {
                            final alreadyAdded = existingMovieIds.contains(
                              m.id,
                            );
                            return ListTile(
                              title: Text(
                                m.title ?? m.detectedTitle,
                                style: const TextStyle(
                                  color: CinemaColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                (m.year ?? m.detectedYear) != null
                                    ? '${m.year ?? m.detectedYear}'
                                    : '',
                                style: const TextStyle(
                                  color: CinemaColors.textSecondary,
                                ),
                              ),
                              trailing: alreadyAdded
                                  ? const Icon(
                                      Icons.check,
                                      color: CinemaColors.amber,
                                    )
                                  : const Icon(
                                      Icons.add,
                                      color: CinemaColors.textSecondary,
                                    ),
                              onTap: alreadyAdded
                                  ? null
                                  : () async {
                                      Navigator.of(ctx).pop();
                                      await repository.addMovieToCollection(
                                        collectionId,
                                        m.id,
                                      );
                                    },
                            );
                          }),
                        ],
                        if (allShows.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'TV SHOWS',
                              style: TextStyle(
                                color: CinemaColors.amber,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...allShows.map((s) {
                            final alreadyAdded = existingShowIds.contains(s.id);
                            return ListTile(
                              title: Text(
                                s.title ?? s.detectedTitle,
                                style: const TextStyle(
                                  color: CinemaColors.textPrimary,
                                ),
                              ),
                              trailing: alreadyAdded
                                  ? const Icon(
                                      Icons.check,
                                      color: CinemaColors.amber,
                                    )
                                  : const Icon(
                                      Icons.add,
                                      color: CinemaColors.textSecondary,
                                    ),
                              onTap: alreadyAdded
                                  ? null
                                  : () async {
                                      Navigator.of(ctx).pop();
                                      await repository.addTvShowToCollection(
                                        collectionId,
                                        s.id,
                                      );
                                    },
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCollection(BuildContext context, String collectionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CinemaColors.card,
        title: Text(
          'Delete "$collectionName"?',
          style: const TextStyle(color: CinemaColors.textPrimary),
        ),
        content: const Text(
          'This will delete the curated collection list.\n\nYour movies and TV shows will remain untouched in your library.',
          style: TextStyle(color: CinemaColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CinemaColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await repository.deleteCollection(collectionId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Collection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CollectionLibraryItem?>(
      stream: repository.watchCollectionById(collectionId),
      builder: (context, snapshot) {
        final collection = snapshot.data;
        if (collection == null) {
          return const Scaffold(
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: 0.0,
                  color: CinemaColors.amber,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(collection.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: CinemaColors.amber),
                tooltip: 'Add Media',
                onPressed: () => _showAddMediaDialog(context),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: CinemaColors.textSecondary,
                ),
                tooltip: 'Delete Collection',
                onPressed: () =>
                    _confirmDeleteCollection(context, collection.name),
              ),
            ],
          ),
          body: StreamBuilder<LibraryResult<MovieLibraryItem>>(
            stream: repository.watchMovies(
              MovieQuery.forCollection(collectionId),
            ),
            builder: (context, moviesSnapshot) {
              final movies = moviesSnapshot.data?.items ?? [];

              return StreamBuilder<LibraryResult<TvShowLibraryItem>>(
                stream: repository.watchTvShows(
                  TvShowQuery.forCollection(collectionId),
                ),
                builder: (context, showsSnapshot) {
                  final shows = showsSnapshot.data?.items ?? [];
                  final totalCount = movies.length + shows.length;

                  if (totalCount == 0) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.collections_bookmark_outlined,
                              size: 56,
                              color: CinemaColors.textMuted,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Collection is empty',
                              style: TextStyle(
                                color: CinemaColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Curate this collection by adding movies or TV shows from your library.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: CinemaColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _showAddMediaDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Media'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      if (movies.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                            child: Text(
                              'MOVIES',
                              style: TextStyle(
                                color: CinemaColors.amber,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 220,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final movie = movies[index];
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
                                        repository: repository,
                                        database: database,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }, childCount: movies.length),
                          ),
                        ),
                      ],
                      if (shows.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24, 28, 24, 12),
                            child: Text(
                              'TV SHOWS',
                              style: TextStyle(
                                color: CinemaColors.amber,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 220,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final show = shows[index];
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
                                        repository: repository,
                                        database: database,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }, childCount: shows.length),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
