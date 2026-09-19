import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/domain/models/feedback_models.dart';
import 'package:reelhouse/domain/services/feedback_service.dart';
import 'package:reelhouse/presentation/widgets/feedback_dialog.dart';

class MockFeedbackService implements FeedbackService {
  FeedbackPayload? lastLaunchedPayload;
  FeedbackPayload? lastCopiedPayload;
  bool shouldSucceedLaunch = true;
  String mockPlatform = 'Windows';

  @override
  String getPlatformIdentifier() => mockPlatform;

  @override
  Future<bool> launchFeedbackEmail(FeedbackPayload payload) async {
    lastLaunchedPayload = payload;
    return shouldSucceedLaunch;
  }

  @override
  Future<void> copyFeedbackToClipboard(FeedbackPayload payload) async {
    lastCopiedPayload = payload;
  }
}

void main() {
  late MockFeedbackService mockService;

  setUp(() {
    mockService = MockFeedbackService();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: CinemaTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => FeedbackDialog(
                  feedbackService: mockService,
                  appVersion: '1.0.0',
                ),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'FeedbackDialog renders header, 3 categories, fields, and privacy note',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      await tester.pumpWidget(buildTestWidget());

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Feedback & Suggestions'), findsOneWidget);
      expect(find.text('Report a Bug'), findsOneWidget);
      expect(find.text('Suggest an Improvement'), findsOneWidget);
      expect(find.text('General Feedback'), findsOneWidget);

      expect(find.text('Subject (Optional)'), findsOneWidget);
      expect(find.text('Message *'), findsOneWidget);

      expect(
        find.text('Include non-sensitive diagnostic info'),
        findsOneWidget,
      );
      expect(find.text('REELHOUSE v1.0.0 • Platform: Windows'), findsOneWidget);

      expect(
        find.text(
          'Your feedback is sent only when you choose to submit it. '
          'REELHOUSE does not automatically attach your library, media files, TMDB API key, or personal profile data.',
        ),
        findsOneWidget,
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
      expect(find.text('Send Feedback'), findsOneWidget);
    },
  );

  testWidgets('Category selection switches active category', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Select "Suggest an Improvement"
    await tester.tap(find.text('Suggest an Improvement'));
    await tester.pumpAndSettle();

    // Enter message & send
    await tester.enterText(
      find.widgetWithText(TextField, 'Message *'),
      'Please add audio track switching.',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Send Feedback'));
    await tester.tap(find.text('Send Feedback'));
    await tester.pumpAndSettle();

    expect(mockService.lastLaunchedPayload, isNotNull);
    expect(
      mockService.lastLaunchedPayload!.category,
      equals(FeedbackCategory.improvement),
    );
    expect(
      mockService.lastLaunchedPayload!.message,
      equals('Please add audio track switching.'),
    );
  });

  testWidgets('Validation prevents sending or copying empty message', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Tap Send Feedback without typing message
    await tester.ensureVisible(find.text('Send Feedback'));
    await tester.tap(find.text('Send Feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your feedback message.'), findsOneWidget);
    expect(mockService.lastLaunchedPayload, isNull);

    // Tap Copy Text without message
    await tester.ensureVisible(find.text('Copy Text'));
    await tester.tap(find.text('Copy Text'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your feedback message.'), findsOneWidget);
    expect(mockService.lastCopiedPayload, isNull);
  });

  testWidgets('Successful send closes dialog and shows confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Subject (Optional)'),
      'Subtitles bug',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Message *'),
      'SRT subtitles out of sync.',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Send Feedback'));
    await tester.tap(find.text('Send Feedback'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.byType(FeedbackDialog), findsNothing);
    expect(
      find.text(
        'Thanks — your feedback is ready to send in your email client.',
      ),
      findsOneWidget,
    );
    expect(mockService.lastLaunchedPayload!.subject, equals('Subtitles bug'));
  });

  testWidgets('Copy Text button copies formatted body to clipboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Message *'),
      'Great UI theme!',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Copy Text'));
    await tester.tap(find.text('Copy Text'));
    await tester.pumpAndSettle();

    expect(mockService.lastCopiedPayload, isNotNull);
    expect(mockService.lastCopiedPayload!.message, equals('Great UI theme!'));
    expect(find.text('Feedback copied to clipboard.'), findsOneWidget);
  });

  testWidgets('Cancel button dismisses dialog without sending', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Message *'),
      'Draft message',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackDialog), findsNothing);
    expect(mockService.lastLaunchedPayload, isNull);
  });

  testWidgets('Fallback to clipboard when external mail launch fails', (
    tester,
  ) async {
    mockService.shouldSucceedLaunch = false;

    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Message *'),
      'Test fallback',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Send Feedback'));
    await tester.tap(find.text('Send Feedback'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackDialog), findsNothing);
    expect(mockService.lastCopiedPayload, isNotNull);
    expect(
      find.text(
        'Could not launch email client. Feedback copied to clipboard instead.',
      ),
      findsOneWidget,
    );
  });
}
