import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';

/// Restrained, ambient cinema loading skeleton poster card placeholder.
class CinemaPosterCardSkeleton extends StatelessWidget {
  const CinemaPosterCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Placeholder
          Expanded(
            child: Container(
              color: tokens.surface2,
              child: Center(
                child: Icon(
                  Icons.movie_outlined,
                  color: tokens.textMuted.withValues(alpha: 0.3),
                  size: 32,
                ),
              ),
            ),
          ),

          // Text Placeholders
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 50,
                  decoration: BoxDecoration(
                    color: tokens.surface2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Discovery row loading skeleton for HomeScreen.
class CinemaCarouselSkeleton extends StatelessWidget {
  final String title;
  final String? subtitle;

  const CinemaCarouselSkeleton({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: CinemaTheme.eyebrow(context, fontSize: 12)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 16.0;
            const targetWidth = 160.0;
            const aspectRatio = 0.58;
            final availableWidth = constraints.maxWidth;
            final count = ((availableWidth + spacing) / (targetWidth + spacing))
                .floor()
                .clamp(1, 20);
            final cardWidth = (availableWidth - (count - 1) * spacing) / count;
            final cardHeight = cardWidth / aspectRatio;

            return SizedBox(
              height: cardHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < count; i++) ...[
                    if (i > 0) const SizedBox(width: spacing),
                    const Expanded(child: CinemaPosterCardSkeleton()),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 36),
      ],
    );
  }
}

/// Grid skeleton for MoviesScreen and TvShowsScreen catalogues.
class CinemaGridSkeleton extends StatelessWidget {
  final int itemCount;

  const CinemaGridSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        childAspectRatio: 0.60,
        crossAxisSpacing: 28,
        mainAxisSpacing: 32,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => const CinemaPosterCardSkeleton(),
    );
  }
}

/// List skeleton for CollectionsScreen and list-based discovery surfaces.
class CinemaListSkeleton extends StatelessWidget {
  final int itemCount;

  const CinemaListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: tokens.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 220,
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(4),
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
  }
}
