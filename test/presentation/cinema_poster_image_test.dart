import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/presentation/widgets/cinema_poster_image.dart';

void main() {
  group('CinemaPosterImage Tests', () {
    testWidgets('renders fallback widget when imagePath is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinemaPosterImage(
              imagePath: null,
              fallbackIcon: Icons.tv,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tv), findsOneWidget);
    });

    testWidgets('renders custom fallbackWidget when provided and path is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinemaPosterImage(
              imagePath: null,
              fallbackWidget: Text('CUSTOM_FALLBACK_SLATE'),
            ),
          ),
        ),
      );

      expect(find.text('CUSTOM_FALLBACK_SLATE'), findsOneWidget);
    });

    testWidgets('resolves relative TMDB still path into Image.network', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinemaPosterImage(
              imagePath: '/sample_episode_still.jpg',
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect(image.image, isA<NetworkImage>());
      final networkImage = image.image as NetworkImage;
      expect(
        networkImage.url,
        'https://image.tmdb.org/t/p/w780/sample_episode_still.jpg',
      );
    });

    testWidgets('resolves full HTTP still URL into Image.network', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinemaPosterImage(
              imagePath: 'https://example.com/stills/ep1.jpg',
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect(image.image, isA<NetworkImage>());
      final networkImage = image.image as NetworkImage;
      expect(networkImage.url, 'https://example.com/stills/ep1.jpg');
    });

    testWidgets('renders fallback for non-existent local Windows path without corrupting TMDB URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CinemaPosterImage(
              imagePath: r'C:\NonExistent\Path\episode_still.jpg',
              fallbackWidget: Text('FALLBACK_FOR_MISSING_LOCAL_FILE'),
            ),
          ),
        ),
      );

      expect(find.text('FALLBACK_FOR_MISSING_LOCAL_FILE'), findsOneWidget);
    });
  });
}
