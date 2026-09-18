import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';

/// Full-surface cinematic error display with retry capability.
class CinemaErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const CinemaErrorState({
    super.key,
    this.title = 'Unable to Load Content',
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CinemaColors.ofAccentSubtle(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CinemaColors.statusError.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, size: 32, color: CinemaColors.statusError),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CinemaColors.ofTextPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: 420,
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CinemaColors.ofTextSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CinemaColors.amber,
                  side: const BorderSide(color: CinemaColors.amber),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact in-place error card for HomeScreen discovery sections.
class CinemaErrorSection extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  const CinemaErrorSection({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: CinemaColors.amber,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: CinemaColors.ofCard(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: CinemaColors.statusError.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: CinemaColors.statusWarning,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Failed to load section',
                      style: TextStyle(
                        color: CinemaColors.ofTextPrimary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message != null && message!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: CinemaColors.ofTextSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: CinemaColors.amber,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 38),
      ],
    );
  }
}
