import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../domain/repository/library_repository.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_genre_tile.dart';
import '../widgets/cinema_loading_skeleton.dart';

/// Screen presenting the complete catalogue of all genres discovered in the library
/// using a prominent 4-column cinematic grid with substantial artwork tile presence.
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
              final crossAxisCount = width > 1024
                  ? 4
                  : width > 720
                  ? 3
                  : width > 340
                  ? 2
                  : 1;
              const spacing = 16.0;
              final contentWidth = (width - 48).clamp(0.0, double.infinity);
              final tileWidth =
                  (contentWidth - (crossAxisCount - 1) * spacing) /
                  crossAxisCount;
              final tileHeight = width > 1024
                  ? 120.0
                  : width > 720
                  ? 115.0
                  : width > 340
                  ? 90.0
                  : 72.0;
              final childAspectRatio = tileWidth / tileHeight;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  return CinemaGenreTile(
                    genre: genre,
                    repository: repository,
                    database: database,
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
