import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';

/// Reusable artwork display supporting cached local filesystem paths,
/// network URLs (web/remote), and a graceful cinematic placeholder.
class CinemaPosterImage extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CinemaPosterImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.movie_filter,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final path = imagePath;

    if (path != null && path.isNotEmpty) {
      if (kIsWeb || path.startsWith('http')) {
        imageWidget = Image.network(
          path,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _buildFallback(),
        );
      } else {
        final file = File(path);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, _, _) => _buildFallback(),
          );
        } else {
          imageWidget = _buildFallback();
        }
      }
    } else {
      imageWidget = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: CinemaColors.surface,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: CinemaColors.textMuted, size: 36),
    );
  }
}
