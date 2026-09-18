import 'package:flutter/material.dart';

/// A non-scrolling, responsive single-row container for poster cards.
///
/// Dynamically computes the maximum number of cards that fit completely
/// within the available layout width, ensuring no partially-visible, clipped,
/// or horizontally-scrollable cards appear.
class ResponsiveCardRow extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double targetCardWidth;
  final double spacing;
  final double cardAspectRatio;

  const ResponsiveCardRow({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.targetCardWidth = 160.0,
    this.spacing = 16.0,
    this.cardAspectRatio = 0.58,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final maxCapacity =
            ((availableWidth + spacing) / (targetCardWidth + spacing))
                .floor()
                .clamp(1, 20);
        final visibleCount = maxCapacity.clamp(1, itemCount);
        final cardWidth =
            (availableWidth - (maxCapacity - 1) * spacing) / maxCapacity;
        final cardHeight = cardWidth / cardAspectRatio;
        final isFull = visibleCount == maxCapacity;

        return SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < visibleCount; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                if (isFull)
                  Expanded(child: itemBuilder(context, i))
                else
                  SizedBox(width: cardWidth, child: itemBuilder(context, i)),
              ],
            ],
          ),
        );
      },
    );
  }
}
