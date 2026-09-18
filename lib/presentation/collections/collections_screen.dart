import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/query/collection_query.dart';
import '../../domain/query/filter_spec.dart';
import '../../domain/query/library_result.dart';
import '../../domain/query/movie_query.dart';
import '../../domain/query/pagination_spec.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/repository/library_repository.dart';
import '../movies/movie_detail_screen.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_loading_skeleton.dart';
import '../widgets/cinema_poster_card.dart';
import '../widgets/responsive_card_row.dart';
import 'all_franchises_screen.dart';
import 'collection_detail_screen.dart';
import 'system_curation_grid_screen.dart';

/// Prominent genres prioritized for shelves on the landing page.
const List<String> kProminentGenres = [
  'Action',
  'Adventure',
  'Comedy',
  'Crime',
  'Drama',
  'Fantasy',
  'Horror',
  'Romance',
  'Science Fiction',
  'Thriller',
];

/// Collections / Curation Screen featuring:
/// 1. Discovered Genre horizontal chip strip with in-page scroll or direct curation navigation.
/// 2. Prominent genre shelves with responsive poster rows and per-genre View All.
/// 3. Franchises carousel with full browse option.
/// 4. Personal Collections created by the user.
class CollectionsScreen extends StatefulWidget {
  final LibraryRepository repository;
  final AppDatabase? database;

  CollectionsScreen({
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
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final Map<String, GlobalKey> _genreKeys = {};
  String? _selectedGenre;

  void _showCreateCollectionDialog(BuildContext context) {
    final tokens = CinemaTheme.of(context);
    final nameController = TextEditingController();
    final overviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface2,
        title: Text(
          'New Curated Collection',
          style: TextStyle(color: tokens.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Curate custom lists such as sagas, directors, or thematic groups.',
              style: TextStyle(color: tokens.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: tokens.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Collection Name',
                hintText: 'e.g. Christopher Nolan, Comfort Movies',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: overviewController,
              style: TextStyle(color: tokens.textPrimary),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief notes on this curated list',
              ),
            ),
          ],
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              Navigator.of(ctx).pop();
              final overviewText = overviewController.text.trim();
              await widget.repository.createCollection(
                name: name,
                overview: overviewText.isNotEmpty ? overviewText : null,
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: tokens.accent),
            tooltip: 'New Collection',
            onPressed: () => _showCreateCollectionDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Section: Genres (Text-first Chip Strip + Responsive Shelves)
            _buildGenresSection(context, tokens),
            const SizedBox(height: 36),

            // 2. Section: Franchises
            _buildFranchisesSection(context, tokens),
            const SizedBox(height: 36),

            // 3. Section: Your Collections
            _buildPersonalCollectionsSection(context, tokens),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    CinemaThemeData tokens, {
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: CinemaTheme.eyebrow(context, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: tokens.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }

  Widget _buildGenresSection(BuildContext context, CinemaThemeData tokens) {
    return StreamBuilder<List<String>>(
      stream: widget.repository.watchDiscoveredGenres(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, tokens, title: 'GENRES'),
              const SizedBox(height: 14),
              Text(
                'Unable to load genres',
                style: TextStyle(color: tokens.textMuted, fontSize: 13),
              ),
            ],
          );
        }

        final discoveredGenres = snapshot.data ?? [];
        if (discoveredGenres.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, tokens, title: 'GENRES'),
              const SizedBox(height: 14),
              Text(
                'No genres found in library.',
                style: TextStyle(color: tokens.textMuted, fontSize: 13),
              ),
            ],
          );
        }

        // Determine active genres for shelves:
        // Match kProminentGenres that exist in discoveredGenres first.
        final activeGenres = <String>[];
        for (final pg in kProminentGenres) {
          final match = discoveredGenres.firstWhere(
            (g) => g.toLowerCase() == pg.toLowerCase(),
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            activeGenres.add(match);
          }
        }

        // If none of the prominent genres matched, take first 5 discovered
        if (activeGenres.isEmpty) {
          activeGenres.addAll(discoveredGenres.take(5));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, tokens, title: 'GENRES'),
            const SizedBox(height: 14),

            // Horizontal text-first genre chip strip with edge fade & scroll affordance
            _GenreChipStrip(
              genres: discoveredGenres,
              selectedGenre: _selectedGenre,
              onGenreSelected: (genre) {
                setState(() {
                  _selectedGenre = genre;
                });

                final prominentMatch = activeGenres.firstWhere(
                  (g) => g.toLowerCase() == genre.toLowerCase(),
                  orElse: () => '',
                );

                if (prominentMatch.isNotEmpty &&
                    _genreKeys[prominentMatch]?.currentContext != null) {
                  Scrollable.ensureVisible(
                    _genreKeys[prominentMatch]!.currentContext!,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SystemCurationGridScreen(
                        title: genre,
                        genre: genre,
                        repository: widget.repository,
                        database: widget.database,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 28),

            // Individual Genre Shelves with Responsive Non-Scrolling Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeGenres.length,
              separatorBuilder: (_, _) => const SizedBox(height: 28),
              itemBuilder: (context, index) {
                final genre = activeGenres[index];
                final key = _genreKeys.putIfAbsent(genre, () => GlobalKey());
                return Container(
                  key: key,
                  child: _GenreDiscoveryRow(
                    genre: genre,
                    repository: widget.repository,
                    database: widget.database,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFranchisesSection(BuildContext context, CinemaThemeData tokens) {
    return StreamBuilder<List<FranchiseLibraryItem>>(
      stream: widget.repository.watchFranchises(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final franchises = snapshot.data ?? [];
        if (franchises.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              tokens,
              title: 'FRANCHISES',
              trailing: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllFranchisesScreen(
                        repository: widget.repository,
                        database: widget.database,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: tokens.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: tokens.accent,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ResponsiveCardRow(
              itemCount: franchises.length,
              itemBuilder: (context, index) {
                final franchise = franchises[index];
                return CinemaPosterCard(
                  title: franchise.name,
                  subtitle:
                      '${franchise.movieCount} ${franchise.movieCount == 1 ? 'Film' : 'Films'}',
                  posterPath: franchise.posterPath,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SystemCurationGridScreen(
                          title: franchise.name,
                          tmdbCollectionId: franchise.id,
                          tmdbCollectionName: franchise.name,
                          repository: widget.repository,
                          database: widget.database,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalCollectionsSection(
    BuildContext context,
    CinemaThemeData tokens,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          tokens,
          title: 'YOUR COLLECTIONS',
          trailing: TextButton.icon(
            onPressed: () => _showCreateCollectionDialog(context),
            icon: Icon(Icons.add, size: 16, color: tokens.accent),
            label: Text(
              'New Collection',
              style: TextStyle(
                color: tokens.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<LibraryResult<CollectionLibraryItem>>(
          stream: widget.repository.watchCollections(CollectionQuery.all()),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return CinemaErrorState(
                title: 'Unable to Load Collections',
                message: snapshot.error.toString(),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const CinemaListSkeleton();
            }

            final collections = snapshot.data?.items ?? [];
            if (collections.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: tokens.surface1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.collections_bookmark_outlined,
                        color: tokens.textMuted,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No personal collections yet.',
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create a collection for a marathon, a theme, or anything you want to keep together.',
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _showCreateCollectionDialog(context),
                      child: const Text('Create'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: collections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final col = collections[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CollectionDetailScreen(
                          collectionId: col.id,
                          repository: widget.repository,
                          database: widget.database,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tokens.surface1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: tokens.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tokens.accent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.collections_bookmark,
                            color: tokens.accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                col.name,
                                style: TextStyle(
                                  color: tokens.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (col.overview != null &&
                                  col.overview!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  col.overview!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: tokens.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 3),
                              Text(
                                '${col.itemCount} ${col.itemCount == 1 ? 'item' : 'items'}',
                                style: TextStyle(
                                  color: tokens.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: tokens.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// A responsive horizontal poster row presenting a subset of films in a specific genre.
class _GenreDiscoveryRow extends StatelessWidget {
  final String genre;
  final LibraryRepository repository;
  final AppDatabase? database;

  const _GenreDiscoveryRow({
    required this.genre,
    required this.repository,
    this.database,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return StreamBuilder<LibraryResult<MovieLibraryItem>>(
      stream: repository.watchMovies(
        MovieQuery(
          filter: MovieFilter(genre: genre),
          pagination: const PaginationSpec(limit: 15),
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final movies = snapshot.data?.items ?? [];
        if (movies.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    genre.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SystemCurationGridScreen(
                          title: genre,
                          genre: genre,
                          repository: repository,
                          database: database,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: tokens.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: tokens.accent,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ResponsiveCardRow(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return CinemaPosterCard(
                  title: movie.displayTitle,
                  year: movie.displayYear,
                  posterPath: movie.posterPath,
                  availabilityStatus: movie.availability,
                  isFavorite: movie.isFavorite,
                  isWatchlist: movie.isWatchlist,
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
              },
            ),
          ],
        );
      },
    );
  }
}

/// A horizontal text-first genre chip strip with edge fade and scroll affordance.
class _GenreChipStrip extends StatefulWidget {
  final List<String> genres;
  final String? selectedGenre;
  final ValueChanged<String> onGenreSelected;

  const _GenreChipStrip({
    required this.genres,
    required this.selectedGenre,
    required this.onGenreSelected,
  });

  @override
  State<_GenreChipStrip> createState() => _GenreChipStripState();
}

class _GenreChipStripState extends State<_GenreChipStrip> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollIndicators);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollIndicators();
    });
  }

  @override
  void didUpdateWidget(covariant _GenreChipStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.genres != widget.genres) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateScrollIndicators();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollIndicators);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollIndicators() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final maxScroll = pos.maxScrollExtent;
    final currentScroll = pos.pixels;
    final canScroll = maxScroll > 0 && currentScroll < (maxScroll - 4.0);

    if (canScroll != _canScrollRight) {
      setState(() {
        _canScrollRight = canScroll;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return SizedBox(
      height: 38,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.horizontal) {
                final maxScroll = notification.metrics.maxScrollExtent;
                final currentScroll = notification.metrics.pixels;
                final canScroll =
                    maxScroll > 0 && currentScroll < (maxScroll - 4.0);
                if (canScroll != _canScrollRight) {
                  setState(() {
                    _canScrollRight = canScroll;
                  });
                }
              }
              return false;
            },
            child: ScrollConfiguration(
              behavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
                scrollbars: false,
              ),
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 48),
                itemCount: widget.genres.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final genre = widget.genres[index];
                  final isSelected = widget.selectedGenre == genre;

                  return InkWell(
                    onTap: () => widget.onGenreSelected(genre),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tokens.accent.withValues(alpha: 0.14)
                            : tokens.surface1,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? tokens.accent : tokens.border,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: isSelected
                              ? tokens.accent
                              : tokens.textPrimary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_canScrollRight)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _canScrollRight ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 44,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        tokens.background.withValues(alpha: 0.0),
                        tokens.background.withValues(alpha: 0.8),
                        tokens.background,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: tokens.textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
