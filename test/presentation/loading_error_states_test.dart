import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/presentation/widgets/cinema_error_state.dart';
import 'package:reelhouse/presentation/widgets/cinema_loading_skeleton.dart';

void main() {
  testWidgets('CinemaPosterCardSkeleton renders restrained placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 170,
              height: 275,
              child: CinemaPosterCardSkeleton(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CinemaPosterCardSkeleton), findsOneWidget);
    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
  });

  testWidgets('CinemaCarouselSkeleton renders title and skeleton cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: const Scaffold(
          body: CinemaCarouselSkeleton(
            title: 'RECENTLY ADDED',
            subtitle: 'Latest acquisitions discovered across your disks',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('RECENTLY ADDED'), findsOneWidget);
    expect(
      find.text('Latest acquisitions discovered across your disks'),
      findsOneWidget,
    );
    expect(find.byType(CinemaPosterCardSkeleton), findsWidgets);
  });

  testWidgets('CinemaGridSkeleton renders grid of skeleton cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: const Scaffold(body: CinemaGridSkeleton(itemCount: 6)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CinemaPosterCardSkeleton), findsNWidgets(6));
  });

  testWidgets('CinemaListSkeleton renders list of skeleton cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: const Scaffold(body: CinemaListSkeleton(itemCount: 3)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CinemaListSkeleton), findsOneWidget);
  });

  testWidgets('CinemaErrorState renders error message and triggers retry', (
    tester,
  ) async {
    var retryTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: Scaffold(
          body: CinemaErrorState(
            title: 'Failed to load movie library',
            message: 'Database query timeout',
            onRetry: () => retryTapped = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Failed to load movie library'), findsOneWidget);
    expect(find.text('Database query timeout'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(retryTapped, isTrue);
  });

  testWidgets(
    'CinemaErrorSection renders in-place section error and triggers retry',
    (tester) async {
      var retryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: CinemaTheme.darkTheme,
          home: Scaffold(
            body: CinemaErrorSection(
              title: 'TV CONTINUE WATCHING',
              message: 'Stream interrupted',
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TV CONTINUE WATCHING'), findsOneWidget);
      expect(find.text('Failed to load section'), findsOneWidget);
      expect(find.text('Stream interrupted'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(retryTapped, isTrue);
    },
  );
}
