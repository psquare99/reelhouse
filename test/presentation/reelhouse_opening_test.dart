import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/presentation/splash/reelhouse_opening.dart';

void main() {
  group('ReelhouseOpening', () {
    testWidgets('renders dark background, icon, title, and subtitle', (
      WidgetTester tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(home: ReelhouseOpening(onComplete: () => completed = true)),
      );

      // Advance past the 200ms initial delay — the animation should now be
      // running but not yet complete.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byIcon(Icons.movie_filter_rounded), findsOneWidget);
      expect(find.text('REELHOUSE'), findsOneWidget);
      expect(find.text('Personal Digital Cinema'), findsOneWidget);

      // Animation hasn't completed yet (total ~1600ms).
      expect(completed, isFalse);

      // Let the animation finish to avoid pending-timer errors on dispose.
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
    });

    testWidgets('onComplete fires after animation completes', (
      WidgetTester tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(home: ReelhouseOpening(onComplete: () => completed = true)),
      );

      // Advance past: 200ms initial delay + 1400ms animation = 1600ms.
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('skips animation when reduced-motion is enabled', (
      WidgetTester tester,
    ) async {
      bool completed = false;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: ReelhouseOpening(onComplete: () => completed = true),
          ),
        ),
      );

      // Reduced-motion path: onComplete fires immediately via post-frame callback.
      await tester.pump();
      await tester.pumpAndSettle();

      expect(completed, isTrue);

      // Should show a plain SizedBox instead of the animated content.
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('does not re-trigger after completion', (
      WidgetTester tester,
    ) async {
      int completionCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ReelhouseOpening(onComplete: () => completionCount++),
        ),
      );

      // Complete the animation.
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      expect(completionCount, equals(1));

      // Pump more — should not fire again.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(completionCount, equals(1));
    });
  });
}
