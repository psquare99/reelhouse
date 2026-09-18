import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../domain/repository/library_repository.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_genre_tile.dart';
import '../widgets/cinema_loading_skeleton.dart';

/// Screen presenting the complete catalogue of all genres discovered in the library
/// using the shared cinematic artwork-backed genre tiles.
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
                  ? 5
                  : width > 900
                  ? 4
                  : width > 600
                  ? 3
                  : width > 360
                  ? 2
                  : 1;
              const spacing = 12.0;
              final contentWidth = (width - 48).clamp(0.0, double.infinity);
              final tileWidth =
                  (contentWidth - (crossAxisCount - 1) * spacing) /
                  crossAxisCount;
              const tileHeight = 52.0;
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
