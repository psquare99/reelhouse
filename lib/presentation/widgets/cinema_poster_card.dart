import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../domain/models/availability_status.dart';
import 'cinema_poster_image.dart';

/// Poster-first cinema card for movies and TV shows.
///
/// Restrained, artwork-driven presentation with subtle availability
/// and user watch-state indicators.
class CinemaPosterCard extends StatelessWidget {
  final String title;
  final int? year;
  final String? posterPath;
  final AvailabilityStatus? availabilityStatus;
  final bool isFavorite;
  final String watchState; // 'UNWATCHED' | 'IN_PROGRESS' | 'WATCHED'
  final double? watchProgress; // 0.0 to 1.0 (for in-progress)
  final VoidCallback onTap;
  final IconData fallbackIcon;

  const CinemaPosterCard({
    super.key,
    required this.title,
    this.year,
    this.posterPath,
    this.availabilityStatus,
    this.isFavorite = false,
    this.watchState = 'UNWATCHED',
    this.watchProgress,
    required this.onTap,
    this.fallbackIcon = Icons.movie_filter,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: CinemaColors.ofCard(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CinemaColors.ofBorderSubtle(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Artwork with overlays
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CinemaPosterImage(
                    imagePath: posterPath,
                    fallbackIcon: fallbackIcon,
                  ),

                  // Favorite indicator badge (top-right)
                  if (isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: CinemaColors.ofCanvas(context)
                              .withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: CinemaColors.amber,
                          size: 14,
                        ),
                      ),
                    ),

                  // Availability micro-indicator (top-left) - understated so artwork dominates
                  if (availabilityStatus != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildAvailabilityIndicator(
                        context,
                        availabilityStatus!,
                      ),
                    ),

                  // In-progress watch line (bottom of poster)
                  if (watchState == 'IN_PROGRESS')
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: watchProgress ?? 0.4,
                        minHeight: 2.5,
                        backgroundColor: CinemaColors.ofCanvas(context)
                            .withValues(alpha: 0.7),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          CinemaColors.amber,
                        ),
                      ),
                    )
                  else if (watchState == 'WATCHED')
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: CinemaColors.ofCanvas(context)
                              .withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: CinemaColors.amber,
                          size: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Text info below poster: title and year
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CinemaColors.ofTextPrimary(context),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    year != null ? '$year' : '—',
                    style: TextStyle(
                      color: CinemaColors.ofTextSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Understated micro-indicator to avoid competing with poster artwork.
  Widget _buildAvailabilityIndicator(
    BuildContext context,
    AvailabilityStatus status,
  ) {
    Color dotColor;
    IconData? icon;
    String tooltip;

    switch (status) {
      case AvailabilityStatus.availableLocally:
        dotColor = CinemaColors.amber;
        icon = Icons.offline_pin_outlined;
        tooltip = 'Downloaded locally';
      case AvailabilityStatus.availableOnRemovableStorage:
        dotColor = CinemaColors.ofTextSecondary(context);
        icon = Icons.album_outlined;
        tooltip = 'On connected disk';
      case AvailabilityStatus.availableOnMultipleSources:
        dotColor = CinemaColors.amber;
        icon = Icons.done_all;
        tooltip = 'Available locally and on disk';
      case AvailabilityStatus.unavailable:
        dotColor = CinemaColors.ofTextMuted(context);
        icon = Icons.cloud_off_outlined;
        tooltip = 'Storage disk disconnected';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: CinemaColors.ofCanvas(context).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: dotColor.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: dotColor, size: 10),
            const SizedBox(width: 4),
            Text(
              status == AvailabilityStatus.availableLocally
                  ? 'OFFLINE'
                  : status == AvailabilityStatus.availableOnRemovableStorage
                  ? 'DISK'
                  : status == AvailabilityStatus.unavailable
                  ? 'OFFLINE'
                  : 'READY',
              style: TextStyle(
                color: dotColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
