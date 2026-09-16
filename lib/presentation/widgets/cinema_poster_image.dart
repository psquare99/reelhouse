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
  final Widget? fallbackWidget;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CinemaPosterImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.movie_filter,
    this.fallbackWidget,
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
          errorBuilder: (_, _, _) => _buildFallback(context),
        );
      } else {
        final file = File(path);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, _, _) => _buildFallback(context),
          );
        } else if (!path.contains('\\') &&
            !path.contains(':') &&
            (path.startsWith('/') ||
                path.endsWith('.jpg') ||
                path.endsWith('.png') ||
                path.endsWith('.jpeg') ||
                path.endsWith('.webp'))) {
          final cleanPath = path.startsWith('/') ? path : '/$path';
          imageWidget = Image.network(
            'https://image.tmdb.org/t/p/w780$cleanPath',
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, _, _) => _buildFallback(context),
          );
        } else {
          imageWidget = _buildFallback(context);
        }
      }
    } else {
      imageWidget = _buildFallback(context);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildFallback(BuildContext context) {
    if (fallbackWidget != null) {
      return fallbackWidget!;
    }

    return Container(
      width: width,
      height: height,
      color: CinemaColors.ofSurface(context),
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: CinemaColors.ofTextMuted(context),
        size: 36,
      ),
    );
  }
}
