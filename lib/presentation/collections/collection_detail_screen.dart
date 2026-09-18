import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
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
    final tokens = CinemaTheme.of(context);
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
      backgroundColor: tokens.surface2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchQuery.trim().toLowerCase();
            final filteredMovies = query.isEmpty
                ? allMovies
                : allMovies.where((m) {
                    final title = (m.title ?? m.detectedTitle).toLowerCase();
                    return title.contains(query);
                  }).toList();
            final filteredShows = query.isEmpty
                ? allShows
                : allShows.where((s) {
                    final title = (s.title ?? s.detectedTitle).toLowerCase();
                    return title.contains(query);
                  }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
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
                          Text(
                            'Add Media to Collection',
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: tokens.textSecondary,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 14,
                        ),
                        cursorColor: tokens.accent,
                        decoration: InputDecoration(
                          hintText: 'Search library to add...',
                          hintStyle: TextStyle(
                            color: tokens.textMuted,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: tokens.textSecondary,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: tokens.surface1,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: tokens.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: tokens.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: tokens.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Divider(color: tokens.border),
                      Expanded(
                        child: (filteredMovies.isEmpty && filteredShows.isEmpty)
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 40,
                                        color: tokens.textMuted,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        searchQuery.isNotEmpty
                                            ? 'No items matching "$searchQuery"'
                                            : 'No media available to add',
                                        style: TextStyle(
                                          color: tokens.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView(
                                controller: scrollController,
                                children: [
                                  if (filteredMovies.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'MOVIES',
                                        style: CinemaTheme.eyebrow(
                                          context,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    ...filteredMovies.map((m) {
                                      final alreadyAdded = existingMovieIds
                                          .contains(m.id);
                                      return ListTile(
                                        title: Text(
                                          m.title ?? m.detectedTitle,
                                          style: TextStyle(
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          (m.year ?? m.detectedYear) != null
                                              ? '${m.year ?? m.detectedYear}'
                                              : '',
                                          style: TextStyle(
                                            color: tokens.textSecondary,
                                          ),
                                        ),
                                        trailing: alreadyAdded
                                            ? Icon(
                                                Icons.check,
                                                color: tokens.accent,
                                              )
                                            : Icon(
                                                Icons.add,
                                                color: tokens.textSecondary,
                                              ),
                                        onTap: alreadyAdded
                                            ? null
                                            : () async {
                                                Navigator.of(ctx).pop();
                                                await repository
                                                    .addMovieToCollection(
                                                      collectionId,
                                                      m.id,
                                                    );
                                              },
                                      );
                                    }),
                                  ],
                                  if (filteredShows.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'TV SHOWS',
                                        style: CinemaTheme.eyebrow(
                                          context,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    ...filteredShows.map((s) {
                                      final alreadyAdded = existingShowIds
                                          .contains(s.id);
                                      return ListTile(
                                        title: Text(
                                          s.title ?? s.detectedTitle,
                                          style: TextStyle(
                                            color: tokens.textPrimary,
                                          ),
                                        ),
                                        trailing: alreadyAdded
                                            ? Icon(
                                                Icons.check,
                                                color: tokens.accent,
                                              )
                                            : Icon(
                                                Icons.add,
                                                color: tokens.textSecondary,
                                              ),
                                        onTap: alreadyAdded
                                            ? null
                                            : () async {
                                                Navigator.of(ctx).pop();
                                                await repository
                                                    .addTvShowToCollection(
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
      },
    );
  }

  void _confirmDeleteCollection(BuildContext context, String collectionName) {
    final tokens = CinemaTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface2,
        title: Text(
          'Delete "$collectionName"?',
          style: TextStyle(color: tokens.textPrimary),
        ),
        content: Text(
          'This will delete the curated collection list.\n\nYour movies and TV shows will remain untouched in your library.',
          style: TextStyle(color: tokens.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: tokens.textSecondary),
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
              backgroundColor: tokens.stateUnavailable,
              foregroundColor: tokens.onAccent,
            ),
            child: const Text('Delete Collection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return StreamBuilder<CollectionLibraryItem?>(
      stream: repository.watchCollectionById(collectionId),
      builder: (context, snapshot) {
        final collection = snapshot.data;
        if (collection == null) {
          return Scaffold(
            backgroundColor: tokens.background,
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: 0.0,
                  color: tokens.accent,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: tokens.background,
          appBar: AppBar(
            title: Text(collection.name),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: tokens.accent),
                tooltip: 'Add Media',
                onPressed: () => _showAddMediaDialog(context),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: tokens.textSecondary),
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
                            Icon(
                              Icons.collections_bookmark_outlined,
                              size: 56,
                              color: tokens.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Collection is empty',
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Curate this collection by adding movies or TV shows from your library.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: tokens.textSecondary,
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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                            child: Text(
                              'MOVIES',
                              style: CinemaTheme.eyebrow(context, fontSize: 12),
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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                            child: Text(
                              'TV SHOWS',
                              style: CinemaTheme.eyebrow(context, fontSize: 12),
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
