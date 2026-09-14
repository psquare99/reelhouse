import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';

class TvShowsScreen extends StatelessWidget {
  final AppDatabase database;

  const TvShowsScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TV Shows')),
      body: StreamBuilder<List<TvShow>>(
        stream: database.select(database.tvShows).watch(),
        builder: (context, snapshot) {
          final shows = snapshot.data ?? [];
          if (shows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tv_outlined,
                      size: 56,
                      color: CinemaColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No TV shows discovered yet.',
                      style: TextStyle(
                        color: CinemaColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan a storage location containing TV series and season folders.',
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
            itemCount: shows.length,
            itemBuilder: (context, index) {
              final show = shows[index];
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
                            Icons.tv,
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
                            show.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: CinemaColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Series',
                            style: TextStyle(
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
