import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
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
    final tokens = CinemaTheme.of(context);

    if (isDownloading) {
      final percentStr = downloadProgress != null
          ? '${(downloadProgress! * 100).toInt()}%'
          : '...';
      return ElevatedButton.icon(
        onPressed: null,
        icon: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(tokens.stateProgress),
          ),
        ),
        label: Text(
          'DOWNLOADING $percentStr',
          style: TextStyle(
            fontSize: isCompact ? 11 : 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.surface1,
          foregroundColor: tokens.stateProgress,
          disabledBackgroundColor: tokens.surface1,
          disabledForegroundColor: tokens.stateProgress,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 18,
            vertical: isCompact ? 8 : 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: tokens.border, width: 1),
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
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.stateOffline,
            foregroundColor: tokens.onAccent,
            elevation: 0,
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
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.accent,
            foregroundColor: tokens.onAccent,
            elevation: 0,
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
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.stateUnavailable,
            side: BorderSide(color: tokens.border, width: 1),
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
