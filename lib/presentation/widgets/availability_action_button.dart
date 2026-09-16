import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../domain/models/playback_resolution.dart';

/// Cinematic action button dynamically reflecting physical source availability
/// and active transfer states.
class AvailabilityActionButton extends StatelessWidget {
  final PlaybackResolution resolution;
  final bool isDownloading;
  final double? downloadProgress; // 0.0 to 1.0
  final VoidCallback? onPlay;
  final VoidCallback? onConnectDisk;
  final bool isCompact;

  const AvailabilityActionButton({
    super.key,
    required this.resolution,
    this.isDownloading = false,
    this.downloadProgress,
    this.onPlay,
    this.onConnectDisk,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDownloading) {
      final percentStr = downloadProgress != null
          ? '${(downloadProgress! * 100).toInt()}%'
          : '...';
      return ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(CinemaColors.amber),
          ),
        ),
        label: Text(
          'DOWNLOADING $percentStr',
          style: TextStyle(
            fontSize: isCompact ? 11 : 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: CinemaColors.surface,
          foregroundColor: CinemaColors.amber,
          disabledBackgroundColor: CinemaColors.surface,
          disabledForegroundColor: CinemaColors.amber,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 18,
            vertical: isCompact ? 8 : 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: CinemaColors.amberSubtle),
          ),
        ),
      );
    }

    switch (resolution.action) {
      case PlaybackAction.playOffline:
        return ElevatedButton.icon(
          onPressed: onPlay,
          icon: Icon(Icons.play_arrow_rounded, size: isCompact ? 16 : 20),
          label: Text(
            'PLAY OFFLINE',
            style: TextStyle(
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: CinemaColors.terracotta,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 18,
              vertical: isCompact ? 8 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

      case PlaybackAction.play:
        return ElevatedButton.icon(
          onPressed: onPlay,
          icon: Icon(Icons.play_arrow_rounded, size: isCompact ? 16 : 20),
          label: Text(
            'PLAY',
            style: TextStyle(
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: CinemaColors.terracotta,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 18,
              vertical: isCompact ? 8 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

      case PlaybackAction.connectDisk:
        final diskLabel = resolution.storageName != null
            ? 'CONNECT ${resolution.storageName!.toUpperCase()}'
            : 'CONNECT DISK';
        return OutlinedButton.icon(
          onPressed: onConnectDisk,
          icon: Icon(Icons.storage_outlined, size: isCompact ? 14 : 18),
          label: Text(
            diskLabel,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: CinemaColors.ofTextSecondary(context),
            side: BorderSide(color: CinemaColors.ofBorderSubtle(context)),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 14,
              vertical: isCompact ? 8 : 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
    }
  }
}
