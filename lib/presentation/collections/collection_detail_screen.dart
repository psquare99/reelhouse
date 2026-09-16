import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../movies/movie_detail_screen.dart';
import '../tv_shows/tv_show_detail_screen.dart';
import '../widgets/cinema_poster_card.dart';

/// Detailed view of a curated user collection with contained movies and TV shows.
class CollectionDetailScreen extends StatelessWidget {
  final String collectionId;
  final AppDatabase database;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.database,
  });

  void _showAddMediaDialog(BuildContext context) async {
    final allMovies = await database.getAllMovies();
    final allShows = await database.getAllTvShows();
    final currentItems = await database.getItemsForCollection(collectionId);
    final existingMovieIds = currentItems.map((ci) => ci.movieId).toSet();
    final existingShowIds = currentItems.map((ci) => ci.tvShowId).toSet();

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
                                      await database.addItemToCollection(
                                        CollectionItemsCompanion.insert(
                                          id: 'ci-${DateTime.now().millisecondsSinceEpoch}',
                                          collectionId: collectionId,
                                          movieId: drift.Value(m.id),
                                          addedAt: DateTime.now(),
                                        ),
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
                                      await database.addItemToCollection(
                                        CollectionItemsCompanion.insert(
                                          id: 'ci-${DateTime.now().millisecondsSinceEpoch}',
                                          collectionId: collectionId,
                                          tvShowId: drift.Value(s.id),
                                          addedAt: DateTime.now(),
                                        ),
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
              await database.deleteCollection(collectionId);
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
    return StreamBuilder<Collection?>(
      stream: database.watchCollection(collectionId),
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
          body: StreamBuilder<List<CollectionItem>>(
            stream: database.watchItemsForCollection(collectionId),
            builder: (context, itemsSnapshot) {
              final items = itemsSnapshot.data ?? [];
              if (items.isEmpty) {
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

              return FutureBuilder<Map<String, dynamic>>(
                future: () async {
                  final movieIds = items
                      .where((i) => i.movieId != null)
                      .map((i) => i.movieId!)
                      .toList();
                  final showIds = items
                      .where((i) => i.tvShowId != null)
                      .map((i) => i.tvShowId!)
                      .toList();

                  final movies = await (database.select(
                    database.movies,
                  )..where((m) => m.id.isIn(movieIds))).get();
                  final shows = await (database.select(
                    database.tvShows,
                  )..where((t) => t.id.isIn(showIds))).get();

                  return {
                    'movies': {for (final m in movies) m.id: m},
                    'shows': {for (final s in shows) s.id: s},
                  };
                }(),
                builder: (context, mediaSnapshot) {
                  final movieMap =
                      (mediaSnapshot.data?['movies'] as Map<String, Movie>?) ??
                      {};
                  final showMap =
                      (mediaSnapshot.data?['shows'] as Map<String, TvShow>?) ??
                      {};

                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item.movieId != null) {
                        final movie = movieMap[item.movieId];
                        if (movie == null) return const SizedBox.shrink();
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
                                  database: database,
                                ),
                              ),
                            );
                          },
                        );
                      } else if (item.tvShowId != null) {
                        final show = showMap[item.tvShowId];
                        if (show == null) return const SizedBox.shrink();
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
                                  database: database,
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
