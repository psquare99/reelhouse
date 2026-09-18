import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../domain/repository/library_repository.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_loading_skeleton.dart';
import 'system_curation_grid_screen.dart';

/// Screen presenting the complete catalogue of all genres discovered in the library.
class AllGenresScreen extends StatelessWidget {
  final LibraryRepository repository;
  final AppDatabase? database;

  const AllGenresScreen({super.key, required this.repository, this.database});

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(title: const Text('Genres')),
      body: StreamBuilder<List<String>>(
        stream: repository.watchDiscoveredGenres(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CinemaErrorState(
              title: 'Unable to Load Genres',
              message: snapshot.error.toString(),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: CinemaGridSkeleton(),
            );
          }

          final genres = snapshot.data ?? [];
          if (genres.isEmpty) {
            return Center(
              child: Text(
                'No genres found in library.',
                style: TextStyle(color: tokens.textMuted, fontSize: 14),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1200
                  ? 4
                  : width > 800
                  ? 3
                  : width > 500
                  ? 2
                  : 1;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 14,
                  childAspectRatio: crossAxisCount == 1 ? 4.5 : 2.8,
                ),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  return InkWell(
                    onTap: () {
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surface1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tokens.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.movie_filter_outlined,
                              color: tokens.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: tokens.textSecondary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
