import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../domain/models/availability_status.dart';
import 'cinema_poster_image.dart';

/// Poster-first cinema card for movies and TV shows.
///
/// Restrained, artwork-driven presentation with subtle availability
/// and user watch-state indicators adhering to the 12px radius, 1px border,
/// flat elevation, and semantic state token rules.
class CinemaPosterCard extends StatelessWidget {
  final String title;
  final int? year;
  final String? subtitle;
  final String? posterPath;
  final AvailabilityStatus? availabilityStatus;
  final bool isFavorite;
  final bool isWatchlist;
  final String watchState; // 'UNWATCHED' | 'IN_PROGRESS' | 'WATCHED'
  final double? watchProgress; // 0.0 to 1.0 (for in-progress)
  final int? playbackPositionSeconds;
  final int? durationSeconds;
  final VoidCallback onTap;
  final IconData fallbackIcon;

  const CinemaPosterCard({
    super.key,
    required this.title,
    this.year,
    this.subtitle,
    this.posterPath,
    AvailabilityStatus? availabilityStatus,
    AvailabilityStatus? availability,
    this.isFavorite = false,
    this.isWatchlist = false,
    this.watchState = 'UNWATCHED',
    this.watchProgress,
    this.playbackPositionSeconds,
    this.durationSeconds,
    required this.onTap,
    this.fallbackIcon = Icons.movie_filter,
  }) : availabilityStatus = availabilityStatus ?? availability;

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);
    final isUnavailable = availabilityStatus == AvailabilityStatus.unavailable;

    final isProgress =
        watchState == 'IN_PROGRESS' ||
        (playbackPositionSeconds != null && playbackPositionSeconds! > 0) ||
        (watchProgress != null && watchProgress! > 0);

    final double progressValue =
        watchProgress ??
        ((playbackPositionSeconds != null &&
                durationSeconds != null &&
                durationSeconds! > 0)
            ? (playbackPositionSeconds! / durationSeconds!).clamp(0.0, 1.0)
            : (isProgress ? 0.4 : 0.0));

    Widget poster = CinemaPosterImage(
      imagePath: posterPath,
      fallbackIcon: fallbackIcon,
    );

    if (isUnavailable) {
      const greyscaleMatrix = <double>[
        0.4,
        0.4,
        0.4,
        0,
        0,
        0.4,
        0.4,
        0.4,
        0,
        0,
        0.4,
        0.4,
        0.4,
        0,
        0,
        0,
        0,
        0,
        0.75,
        0,
      ];
      poster = ColorFiltered(
        colorFilter: const ColorFilter.matrix(greyscaleMatrix),
        child: poster,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border, width: 1),
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
                  poster,

                  // Favorite indicator badge (top-right)
                  if (isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: tokens.background.withValues(alpha: 0.80),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: tokens.accent,
                          size: 13,
                        ),
                      ),
                    ),

                  // Availability micro-indicator (top-left)
                  if (availabilityStatus != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildAvailabilityIndicator(
                        context,
                        tokens,
                        availabilityStatus!,
                      ),
                    ),

                  // In-progress watch line (bottom of poster)
                  if (isProgress && progressValue > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 3,
                        backgroundColor: tokens.background.withValues(
                          alpha: 0.8,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tokens.stateProgress,
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
                          color: tokens.background.withValues(alpha: 0.80),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: tokens.accent,
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
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle ?? (year != null ? '$year' : '—'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
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

  /// Understated micro-indicator with semantic state tokens.
  Widget _buildAvailabilityIndicator(
    BuildContext context,
    CinemaThemeData tokens,
    AvailabilityStatus status,
  ) {
    Color dotColor;
    IconData? icon;
    String tooltip;
    String badgeText;

    switch (status) {
      case AvailabilityStatus.availableLocally:
        dotColor = tokens.stateOffline;
        icon = Icons.offline_pin_outlined;
        tooltip = 'Downloaded locally';
        badgeText = 'OFFLINE';
      case AvailabilityStatus.availableOnRemovableStorage:
        dotColor = tokens.stateAvailable;
        icon = Icons.album_outlined;
        tooltip = 'On connected disk';
        badgeText = 'DISK';
      case AvailabilityStatus.availableOnMultipleSources:
        dotColor = tokens.stateAvailable;
        icon = Icons.done_all;
        tooltip = 'Available locally and on disk';
        badgeText = 'READY';
      case AvailabilityStatus.unavailable:
        dotColor = tokens.stateUnavailable;
        icon = Icons.cloud_off_outlined;
        tooltip = 'Storage disk disconnected';
        badgeText = 'CONNECT';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: tokens.surface1.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: dotColor.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: dotColor, size: 9),
            const SizedBox(width: 3.5),
            Text(
              badgeText,
              style: TextStyle(
                color: dotColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
