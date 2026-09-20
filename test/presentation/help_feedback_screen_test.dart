import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/models/feedback_models.dart';
import 'package:reelhouse/domain/services/feedback_service.dart';
import 'package:reelhouse/presentation/help/help_feedback_screen.dart';

/// Minimal in-file stub so we don't depend on mockito in the test harness.
class _StubFeedbackService implements FeedbackService {
  @override
  Future<FeedbackSubmissionResult> submitFeedback(
    FeedbackPayload payload,
  ) async {
    return FeedbackSubmissionResult.success();
  }

  @override
  Future<void> copyFeedbackToClipboard(FeedbackPayload payload) async {}

  @override
  String getPlatformIdentifier() => 'test';
}

void main() {
  late _StubFeedbackService stub;

  setUp(() {
    stub = _StubFeedbackService();
  });

  Widget buildTestable() {
    return MaterialApp(home: HelpFeedbackScreen(feedbackService: stub));
  }

  group('HelpFeedbackScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(buildTestable());
      expect(find.text('Help & Feedback'), findsOneWidget);
    });

    testWidgets('renders FAQ eyebrow', (tester) async {
      await tester.pumpWidget(buildTestable());
      expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);
    });

    testWidgets('renders SUPPORT eyebrow', (tester) async {
      await tester.pumpWidget(buildTestable());
      expect(find.text('SUPPORT'), findsOneWidget);
    });

    testWidgets('renders all FAQ section headings', (tester) async {
      await tester.pumpWidget(buildTestable());
      expect(find.text('GETTING STARTED'), findsOneWidget);
      expect(find.text('METADATA & ORGANIZATION'), findsOneWidget);
      expect(find.text('PLAYBACK & FILES'), findsOneWidget);
      expect(find.text('STORAGE & DATA'), findsOneWidget);
      expect(find.text('GETTING HELP'), findsOneWidget);
    });

    testWidgets('renders all FAQ questions', (tester) async {
      await tester.pumpWidget(buildTestable());
      expect(find.text('What is MATINEE?'), findsOneWidget);
      expect(find.text('How do I add my media?'), findsOneWidget);
      expect(find.text('How do I rescan a folder?'), findsOneWidget);
      expect(
        find.text('Where do movie and TV show details come from?'),
        findsOneWidget,
      );
      expect(find.text('How do I set up TMDB?'), findsOneWidget);
      expect(find.text('Can I watch videos offline?'), findsOneWidget);
      expect(find.text('What video formats are supported?'), findsOneWidget);
      expect(
        find.text('Can I use more than one storage location?'),
        findsOneWidget,
      );
      expect(find.text('How do I back up my library data?'), findsOneWidget);
      expect(
        find.text('What does "Identify Unmatched Media" do?'),
        findsOneWidget,
      );
      expect(
        find.text('How do I report a bug or send feedback?'),
        findsOneWidget,
      );
    });

    testWidgets('answer is hidden by default', (tester) async {
      await tester.pumpWidget(buildTestable());
      expect(
        find.text(
          'MATINEE is a personal media library app for your computer. '
          'It lets you organize movies and TV shows in one place, with '
          'beautiful metadata like posters and descriptions. You can also '
          'save copies of your files for offline playback.',
        ),
        findsNothing,
      );
    });

    testWidgets('tapping a question reveals the answer', (tester) async {
      await tester.pumpWidget(buildTestable());

      await tester.tap(find.text('What is MATINEE?'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'MATINEE is a personal media library app for your computer. '
          'It lets you organize movies and TV shows in one place, with '
          'beautiful metadata like posters and descriptions. You can also '
          'save copies of your files for offline playback.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping again collapses the answer', (tester) async {
      await tester.pumpWidget(buildTestable());

      // Expand
      await tester.tap(find.text('What is MATINEE?'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'MATINEE is a personal media library app for your computer. '
          'It lets you organize movies and TV shows in one place, with '
          'beautiful metadata like posters and descriptions. You can also '
          'save copies of your files for offline playback.',
        ),
        findsOneWidget,
      );

      // Collapse
      await tester.tap(find.text('What is MATINEE?'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'MATINEE is a personal media library app for your computer. '
          'It lets you organize movies and TV shows in one place, with '
          'beautiful metadata like posters and descriptions. You can also '
          'save copies of your files for offline playback.',
        ),
        findsNothing,
      );
    });

    testWidgets('renders Send Feedback card', (tester) async {
      await tester.pumpWidget(buildTestable());
      expect(find.text('Send Feedback'), findsOneWidget);
      expect(
        find.text('Report a bug, suggest a feature, or ask a question'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Send Feedback opens FeedbackDialog', (tester) async {
      await tester.pumpWidget(buildTestable());

      // The Send Feedback card is near the bottom — scroll it into view first.
      final feedbackFinder = find.text('Send Feedback');
      await tester.ensureVisible(feedbackFinder);
      await tester.tap(feedbackFinder);
      await tester.pumpAndSettle();

      // The dialog should be shown
      expect(find.text('CATEGORY'), findsOneWidget);
    });

    testWidgets('multiple items can be expanded independently', (tester) async {
      await tester.pumpWidget(buildTestable());

      // Expand first
      await tester.tap(find.text('What is MATINEE?'));
      await tester.pumpAndSettle();

      // Expand TMDB question
      await tester.tap(
        find.text('Where do movie and TV show details come from?'),
      );
      await tester.pumpAndSettle();

      // Both answers should be visible
      expect(
        find.text(
          'MATINEE is a personal media library app for your computer. '
          'It lets you organize movies and TV shows in one place, with '
          'beautiful metadata like posters and descriptions. You can also '
          'save copies of your files for offline playback.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'MATINEE looks up titles on TMDB (The Movie Database), a free '
          'online database of movies and TV shows. If you enable TMDB in '
          'Settings, the app will automatically fetch posters, descriptions, '
          'ratings, and episode details for your media.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('chevron icons are present', (tester) async {
      await tester.pumpWidget(buildTestable());
      // Each FAQ item has a chevron_down icon — 11 questions
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNWidgets(11));
    });

    testWidgets('feedback icon is present in support card', (tester) async {
      await tester.pumpWidget(buildTestable());
      expect(find.byIcon(Icons.feedback_outlined), findsOneWidget);
    });
  });
}
