import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';

class MoviesScreen extends StatelessWidget {
  final AppDatabase database;

  const MoviesScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movies')),
      body: StreamBuilder<List<Movie>>(
        stream: database.select(database.movies).watch(),
        builder: (context, snapshot) {
          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.movie_outlined,
                      size: 56,
                      color: CinemaColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No movies discovered yet.',
                      style: TextStyle(
                        color: CinemaColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Register and scan a storage location to populate your movie cinema.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CinemaColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 0.65,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                decoration: BoxDecoration(
                  color: CinemaColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CinemaColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: CinemaColors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.movie_filter,
                            color: CinemaColors.textMuted,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: CinemaColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            movie.year != null
                                ? '${movie.year}'
                                : 'Unknown Year',
                            style: const TextStyle(
                              color: CinemaColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
