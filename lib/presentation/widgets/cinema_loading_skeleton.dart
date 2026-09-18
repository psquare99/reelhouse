import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';

/// Restrained, ambient cinema loading skeleton poster card placeholder.
class CinemaPosterCardSkeleton extends StatelessWidget {
  const CinemaPosterCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = CinemaColors.ofCard(context);
    final placeholderColor = CinemaColors.ofSurfaceElevated(context);
    final borderColor = CinemaColors.ofBorderSubtle(context);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Placeholder
          Expanded(
            child: Container(
              color: placeholderColor,
              child: Center(
                child: Icon(
                  Icons.movie_outlined,
                  color: CinemaColors.ofTextMuted(context)
                      .withValues(alpha: 0.3),
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
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 50,
                  decoration: BoxDecoration(
                    color: placeholderColor,
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

/// Horizontal carousel skeleton for HomeScreen discovery rows.
class CinemaCarouselSkeleton extends StatelessWidget {
  final String title;
  final String? subtitle;

  const CinemaCarouselSkeleton({super.key, required this.title, this.subtitle});

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
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: TextStyle(
              color: CinemaColors.ofTextSecondary(context),
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 275,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (_, _) =>
                const SizedBox(width: 170, child: CinemaPosterCardSkeleton()),
          ),
        ),
        const SizedBox(height: 38),
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
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, _) {
        final cardColor = CinemaColors.ofCard(context);
        final placeholderColor = CinemaColors.ofSurfaceElevated(context);
        final borderColor = CinemaColors.ofBorderSubtle(context);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: placeholderColor,
                  borderRadius: BorderRadius.circular(10),
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
                        color: placeholderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 220,
                      decoration: BoxDecoration(
                        color: placeholderColor,
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
