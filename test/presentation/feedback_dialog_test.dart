import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/models/feedback_models.dart';
import 'package:reelhouse/domain/services/feedback_service.dart';
import 'package:reelhouse/presentation/widgets/feedback_dialog.dart';

class FakeFeedbackService implements FeedbackService {
  FeedbackPayload? lastSubmittedPayload;
  FeedbackPayload? lastCopiedPayload;
  FeedbackSubmissionResult submitResult = FeedbackSubmissionResult.success();
  Duration submitDelay = Duration.zero;

  @override
  String getPlatformIdentifier() => 'TestOS';

  @override
  Future<FeedbackSubmissionResult> submitFeedback(
    FeedbackPayload payload,
  ) async {
    lastSubmittedPayload = payload;
    if (submitDelay > Duration.zero) {
      await Future<void>.delayed(submitDelay);
    }
    return submitResult;
  }

  @override
  Future<void> copyFeedbackToClipboard(FeedbackPayload payload) async {
    lastCopiedPayload = payload;
  }
}

void main() {
  late FakeFeedbackService fakeService;

  setUp(() {
    fakeService = FakeFeedbackService();
  });

  Widget buildTestDialog(
    WidgetTester tester, {
    FeedbackService? service,
    String appVersion = '1.0.0',
  }) {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => FeedbackDialog(
                      feedbackService: service ?? fakeService,
                      appVersion: appVersion,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets(
    'FeedbackDialog renders header, 3 categories, fields, and privacy note',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestDialog(tester));
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
      expect(find.text('REELHOUSE v1.0.0 • Platform: TestOS'), findsOneWidget);
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

  testWidgets('Validation prevents sending or copying empty message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestDialog(tester));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Ensure action buttons are visible
    await tester.ensureVisible(find.text('Send Feedback'));
    await tester.pumpAndSettle();

    // Tap Send Feedback with empty message
    await tester.tap(find.text('Send Feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your feedback message.'), findsOneWidget);
    expect(fakeService.lastSubmittedPayload, isNull);

    // Tap Copy Text with empty message
    await tester.tap(find.text('Copy Text'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your feedback message.'), findsOneWidget);
    expect(fakeService.lastCopiedPayload, isNull);
  });

  testWidgets(
    'Successful submission flow transitions to in-app confirmation and closes',
    (WidgetTester tester) async {
      fakeService.submitResult = FeedbackSubmissionResult.success();

      await tester.pumpWidget(buildTestDialog(tester));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Switch category to Suggest an Improvement
      await tester.tap(find.text('Suggest an Improvement'));
      await tester.pumpAndSettle();

      // Fill Subject and Message
      await tester.enterText(
        find.widgetWithText(TextField, 'Subject (Optional)'),
        'Smart Playlists',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Message *'),
        'Allow creating rule-based collections.',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      // Check submitted payload
      expect(fakeService.lastSubmittedPayload, isNotNull);
      expect(
        fakeService.lastSubmittedPayload!.category,
        FeedbackCategory.improvement,
      );
      expect(fakeService.lastSubmittedPayload!.subject, 'Smart Playlists');
      expect(
        fakeService.lastSubmittedPayload!.message,
        'Allow creating rule-based collections.',
      );
      expect(fakeService.lastSubmittedPayload!.includeDiagnostics, isTrue);

      // Verify in-app success screen rendered
      expect(find.text('Feedback sent'), findsOneWidget);
      expect(
        find.text('Thanks for helping improve REELHOUSE.'),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Feedback sent'), findsNothing);
    },
  );

  testWidgets(
    'Submission failure preserves entered text and displays error message',
    (WidgetTester tester) async {
      fakeService.submitResult = FeedbackSubmissionResult.networkError();

      await tester.pumpWidget(buildTestDialog(tester));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Fill Message
      await tester.enterText(
        find.widgetWithText(TextField, 'Message *'),
        'My very important bug report that should not be lost.',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Subject (Optional)'),
        'Audio sync error',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(
        find.text(
          "Couldn't send feedback. Check your internet connection and try again.",
        ),
        findsOneWidget,
      );

      // Verify user's entered text is completely preserved
      expect(
        find.text('My very important bug report that should not be lost.'),
        findsOneWidget,
      );
      expect(find.text('Audio sync error'), findsOneWidget);

      // Test rate limited error
      fakeService.submitResult = FeedbackSubmissionResult.rateLimited();
      await tester.ensureVisible(find.text('Send Feedback'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      expect(find.text('Please try again later.'), findsOneWidget);
      expect(
        find.text('My very important bug report that should not be lost.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Unchecking diagnostics sets includeDiagnostics to false in payload',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestDialog(tester));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Message *'),
        'Feedback without diagnostics',
      );
      await tester.pumpAndSettle();

      // Uncheck diagnostics
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      expect(fakeService.lastSubmittedPayload, isNotNull);
      expect(fakeService.lastSubmittedPayload!.includeDiagnostics, isFalse);
    },
  );

  testWidgets('Copy Text button copies formatted body to clipboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestDialog(tester));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Subject (Optional)'),
      'Test subject',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Message *'),
      'Test feedback message to copy',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Copy Text'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy Text'));
    await tester.pumpAndSettle();

    expect(fakeService.lastCopiedPayload, isNotNull);
    expect(fakeService.lastCopiedPayload!.subject, 'Test subject');
    expect(
      fakeService.lastCopiedPayload!.message,
      'Test feedback message to copy',
    );
    expect(find.text('Feedback copied to clipboard.'), findsOneWidget);
  });

  testWidgets('Cancel button dismisses dialog', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestDialog(tester));
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Feedback & Suggestions'), findsOneWidget);

    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Feedback & Suggestions'), findsNothing);
  });
}
