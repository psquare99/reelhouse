import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/query/collection_query.dart';
import '../../domain/query/library_result.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/repository/library_repository.dart';
import 'collection_detail_screen.dart';

/// Screen displaying all user-curated cinema collections.
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
    final nameController = TextEditingController();
    final overviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CinemaColors.card,
        title: const Text(
          'New Curated Collection',
          style: TextStyle(color: CinemaColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Curate custom lists such as sagas, directors, or thematic groups.',
              style: TextStyle(color: CinemaColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: CinemaColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Collection Name',
                hintText: 'e.g. Christopher Nolan, Marvel Studios',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: overviewController,
              style: const TextStyle(color: CinemaColors.textPrimary),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: CinemaColors.textSecondary),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: CinemaColors.amber),
            tooltip: 'Create Collection',
            onPressed: () => _showCreateCollectionDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<LibraryResult<CollectionLibraryItem>>(
        stream: repository.watchCollections(CollectionQuery.all()),
        builder: (context, snapshot) {
          final collections = snapshot.data?.items ?? [];
          if (collections.isEmpty) {
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
                      'No curated collections yet.',
                      style: TextStyle(
                        color: CinemaColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Curated collections group related sagas, directors, and custom film lists without altering folder structures.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CinemaColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateCollectionDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Collection'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: collections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
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
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: CinemaColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CinemaColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: CinemaColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CinemaColors.amberSubtle),
                        ),
                        child: const Icon(
                          Icons.collections_bookmark,
                          color: CinemaColors.amber,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              col.name,
                              style: const TextStyle(
                                color: CinemaColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (col.overview != null &&
                                col.overview!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                col.overview!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: CinemaColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${col.itemCount} ${col.itemCount == 1 ? 'item' : 'items'}',
                              style: const TextStyle(
                                color: CinemaColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: CinemaColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
