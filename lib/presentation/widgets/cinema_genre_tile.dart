import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../domain/query/filter_spec.dart';
import '../../domain/query/library_result.dart';
import '../../domain/query/movie_query.dart';
import '../../domain/query/pagination_spec.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/repository/library_repository.dart';
import '../collections/system_curation_grid_screen.dart';

/// Cinematic visual genre tile with representative background artwork, readable scrim, and chevron.
class CinemaGenreTile extends StatelessWidget {
  final String genre;
  final LibraryRepository repository;
  final AppDatabase? database;
  final VoidCallback? onTap;

  const CinemaGenreTile({
    super.key,
    required this.genre,
    required this.repository,
    this.database,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return StreamBuilder<LibraryResult<MovieLibraryItem>>(
      stream: repository.watchMovies(
        MovieQuery(
          filter: MovieFilter(genre: genre),
          pagination: const PaginationSpec(limit: 1),
        ),
      ),
      builder: (context, snapshot) {
        final firstMovie = snapshot.data?.items.firstOrNull;
        final imagePath = firstMovie?.backdropPath ?? firstMovie?.posterPath;

        Widget? imageWidget;
        if (imagePath != null && File(imagePath).existsSync()) {
          imageWidget = Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.surface1,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.border, width: 1),
            ),
            child: InkWell(
              onTap:
                  onTap ??
                  () {
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background representative movie artwork (if present)
                  ?imageWidget,

                  // 2. Functional Scrim for high contrast & legibility across themes
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          tokens.surface1.withValues(alpha: 0.92),
                          tokens.surface1.withValues(alpha: 0.82),
                          tokens.surface1.withValues(alpha: 0.60),
                        ],
                      ),
                    ),
                  ),

                  // 3. Tile Content: Genre Name + Chevron
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            genre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: tokens.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
