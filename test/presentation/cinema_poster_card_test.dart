import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/domain/models/availability_status.dart';
import 'package:reelhouse/presentation/widgets/cinema_poster_card.dart';

void main() {
  Widget buildCard({
    String title = 'Test Movie',
    int? year = 2024,
    AvailabilityStatus? availabilityStatus,
    String watchState = 'UNWATCHED',
    double? watchProgress,
    int? playbackPositionSeconds,
    int? durationSeconds,
    bool isFavorite = false,
  }) {
    return MaterialApp(
      theme: CinemaTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 320,
          child: CinemaPosterCard(
            title: title,
            year: year,
            availabilityStatus: availabilityStatus,
            watchState: watchState,
            watchProgress: watchProgress,
            playbackPositionSeconds: playbackPositionSeconds,
            durationSeconds: durationSeconds,
            isFavorite: isFavorite,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  group('CinemaPosterCard Playback & Visual Tests', () {
    testWidgets('renders progress bar for IN_PROGRESS watch state', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(
          watchState: 'IN_PROGRESS',
          playbackPositionSeconds: 1200,
          durationSeconds: 2400,
        ),
      );

      final progressFinder = find.byType(LinearProgressIndicator);
      expect(progressFinder, findsOneWidget);
      final progressWidget = tester.widget<LinearProgressIndicator>(
        progressFinder,
      );
      expect(progressWidget.value, closeTo(0.5, 0.01));
    });

    testWidgets('renders progress bar when playbackPositionSeconds > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(
          watchState: 'UNWATCHED',
          playbackPositionSeconds: 600,
          durationSeconds: 3600,
        ),
      );

      final progressFinder = find.byType(LinearProgressIndicator);
      expect(progressFinder, findsOneWidget);
    });

    testWidgets('renders checkmark for WATCHED state', (tester) async {
      await tester.pumpWidget(buildCard(watchState: 'WATCHED'));

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets(
      'renders no progress bar or checkmark for clean UNWATCHED state',
      (tester) async {
        await tester.pumpWidget(buildCard(watchState: 'UNWATCHED'));

        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.byIcon(Icons.check_circle), findsNothing);
      },
    );

    testWidgets('renders pill availability badges correctly', (tester) async {
      await tester.pumpWidget(
        buildCard(availabilityStatus: AvailabilityStatus.unavailable),
      );
      expect(find.text('CONNECT'), findsOneWidget);

      await tester.pumpWidget(
        buildCard(
          availabilityStatus: AvailabilityStatus.availableOnRemovableStorage,
        ),
      );
      expect(find.text('DISK'), findsOneWidget);

      await tester.pumpWidget(
        buildCard(availabilityStatus: AvailabilityStatus.availableLocally),
      );
      expect(find.text('OFFLINE'), findsOneWidget);

      await tester.pumpWidget(
        buildCard(
          availabilityStatus: AvailabilityStatus.availableOnMultipleSources,
        ),
      );
      expect(find.text('READY'), findsOneWidget);
    });

    testWidgets('applies ColorFiltered desaturation only when unavailable', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(availabilityStatus: AvailabilityStatus.unavailable),
      );

      expect(find.byType(ColorFiltered), findsOneWidget);

      await tester.pumpWidget(
        buildCard(availabilityStatus: AvailabilityStatus.availableLocally),
      );

      expect(find.byType(ColorFiltered), findsNothing);
    });
  });
}
