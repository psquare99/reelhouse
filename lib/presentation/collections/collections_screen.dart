import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/query/collection_query.dart';
import '../../domain/query/library_result.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/repository/library_repository.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_loading_skeleton.dart';
import '../widgets/cinema_poster_card.dart';
import 'collection_detail_screen.dart';
import 'system_curation_grid_screen.dart';

/// Canonical genres defined by TMDB and standard cinema taxonomy.
const List<String> kCanonicalGenres = [
  'Action',
  'Adventure',
  'Animation',
  'Comedy',
  'Crime',
  'Documentary',
  'Drama',
  'Family',
  'Fantasy',
  'History',
  'Horror',
  'Music',
  'Mystery',
  'Romance',
  'Science Fiction',
  'TV Movie',
  'Thriller',
  'War',
  'Western',
];

/// Redesigned Collections / Curation Screen featuring:
/// 1. System Curation — Dynamic query-derived views over genres & canonical TMDB franchises.
/// 2. Personal Collections — User-curated custom collections & lists.
class CollectionsScreen extends StatelessWidget {
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
              await repository.createCollection(
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
        title: const Text('Curation & Collections'),
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
            // 1. Section: System Curation (Genres)
            _buildGenresSection(context, tokens),
            const SizedBox(height: 36),

            // 2. Section: Canonical Franchises / Collections (TMDB-derived)
            _buildFranchisesSection(context, tokens),
            const SizedBox(height: 36),

            // 3. Section: Your Collections (Personal User-created lists)
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
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: CinemaTheme.eyebrow(context, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: tokens.textSecondary, fontSize: 13),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildGenresSection(BuildContext context, CinemaThemeData tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          tokens,
          title: 'SYSTEM CURATION — GENRES',
          subtitle: 'Dynamic metadata-derived catalogue views',
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<String>>(
          stream: repository.watchDiscoveredGenres(),
          builder: (context, snapshot) {
            final discoveredSet = (snapshot.data ?? []).toSet();

            // Put discovered genres first, then remaining canonical genres
            final sortedGenres = List<String>.from(kCanonicalGenres);
            sortedGenres.sort((a, b) {
              final aHas = discoveredSet.contains(a);
              final bHas = discoveredSet.contains(b);
              if (aHas && !bHas) return -1;
              if (!aHas && bHas) return 1;
              return a.compareTo(b);
            });

            return Wrap(
              spacing: 8,
              runSpacing: 10,
              children: sortedGenres.map((genre) {
                final hasMedia = discoveredSet.contains(genre);

                return ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasMedia) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(genre),
                    ],
                  ),
                  backgroundColor: hasMedia ? tokens.surface2 : tokens.surface1,
                  side: BorderSide(
                    color: hasMedia ? tokens.borderStrong : tokens.border,
                    width: 1,
                  ),
                  labelStyle: TextStyle(
                    color: hasMedia ? tokens.textPrimary : tokens.textSecondary,
                    fontSize: 13,
                    fontWeight: hasMedia ? FontWeight.w600 : FontWeight.w400,
                  ),
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
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFranchisesSection(BuildContext context, CinemaThemeData tokens) {
    return StreamBuilder<List<FranchiseLibraryItem>>(
      stream: repository.watchFranchises(),
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
              title: 'FRANCHISES & SAGAS',
              subtitle:
                  'Canonical provider groupings discovered in your library',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: franchises.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final franchise = franchises[index];
                  return SizedBox(
                    width: 140,
                    child: CinemaPosterCard(
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
                              repository: repository,
                              database: database,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
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
          subtitle: 'Custom lists curated by you',
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
        const SizedBox(height: 16),
        StreamBuilder<LibraryResult<CollectionLibraryItem>>(
          stream: repository.watchCollections(CollectionQuery.all()),
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
                            'Create custom lists for director retrospectives, weekend marathons, or thematic film collections.',
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
                          repository: repository,
                          database: database,
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
