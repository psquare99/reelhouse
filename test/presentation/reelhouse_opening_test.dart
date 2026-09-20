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

    testWidgets(
      'reduced-motion renders branded opening, not transparent placeholder',
      (WidgetTester tester) async {
        bool completed = false;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: ReelhouseOpening(onComplete: () => completed = true),
            ),
          ),
        );

        // Advance one frame so the widget builds.
        await tester.pump();

        // Before the 600ms hold expires the branded content must be visible.
        expect(completed, isFalse);
        expect(find.byIcon(Icons.movie_filter_rounded), findsOneWidget);
        expect(find.text('REELHOUSE'), findsOneWidget);
        expect(find.text('Personal Digital Cinema'), findsOneWidget);

        // Now let the 600ms hold fire and complete.
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(completed, isTrue);
      },
    );

    testWidgets('reduced-motion calls onComplete within ~1 second', (
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

      await tester.pump();

      // Should not have completed during the hold.
      expect(completed, isFalse);

      // 600ms hold + post-frame callback should complete well within 1s.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('onComplete fires exactly once', (WidgetTester tester) async {
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

    testWidgets('reduced-motion onComplete fires exactly once', (
      WidgetTester tester,
    ) async {
      int completionCount = 0;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: ReelhouseOpening(onComplete: () => completionCount++),
          ),
        ),
      );

      // Wait for the 600ms hold plus extra margin.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(completionCount, equals(1));

      // Pump more — should not fire again.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(completionCount, equals(1));
    });
  });
}
