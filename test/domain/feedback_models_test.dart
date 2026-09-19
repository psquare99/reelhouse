import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/models/feedback_models.dart';

void main() {
  group('FeedbackCategory', () {
    test('provides distinct user-facing display names and subject tags', () {
      expect(FeedbackCategory.bug.displayName, equals('Report a Bug'));
      expect(FeedbackCategory.bug.subjectTag, equals('[Bug Report]'));

      expect(
        FeedbackCategory.improvement.displayName,
        equals('Suggest an Improvement'),
      );
      expect(
        FeedbackCategory.improvement.subjectTag,
        equals('[Feature Suggestion]'),
      );

      expect(FeedbackCategory.general.displayName, equals('General Feedback'));
      expect(FeedbackCategory.general.subjectTag, equals('[General Feedback]'));
    });
  });

  group('FeedbackPayload', () {
    test('formats subject line with and without optional subject', () {
      const withSubject = FeedbackPayload(
        category: FeedbackCategory.bug,
        subject: 'Poster loading issue',
        message: 'Posters do not appear on startup.',
      );
      expect(
        withSubject.formatSubject(),
        equals('REELHOUSE [Bug Report]: Poster loading issue'),
      );

      const withoutSubject = FeedbackPayload(
        category: FeedbackCategory.improvement,
        message: 'Add custom theme colors.',
      );
      expect(
        withoutSubject.formatSubject(),
        equals('REELHOUSE [Feature Suggestion]'),
      );
    });

    test('formats body with message and non-sensitive diagnostic context', () {
      const payload = FeedbackPayload(
        category: FeedbackCategory.bug,
        subject: 'Playback glitch',
        message: 'Video stuttered at minute 14.',
        includeDiagnostics: true,
        appVersion: '1.0.0',
        platformName: 'Windows',
      );

      final body = payload.formatBody();

      expect(body, contains('Category: Report a Bug'));
      expect(body, contains('Subject: Playback glitch'));
      expect(body, contains('Video stuttered at minute 14.'));
      expect(body, contains('Diagnostic Context (Non-Sensitive):'));
      expect(body, contains('Application: REELHOUSE v1.0.0'));
      expect(body, contains('Platform: Windows'));

      // Privacy verification: ensures no sensitive data or keywords exist
      expect(body, isNot(contains('api_key')));
      expect(body, isNot(contains('tmdbApiKey')));
      expect(body, isNot(contains('password')));
      expect(body, isNot(contains('secret')));
      expect(body, isNot(contains('movies')));
    });

    test('omits diagnostic context when includeDiagnostics is false', () {
      const payload = FeedbackPayload(
        category: FeedbackCategory.general,
        message: 'Love the cinema design!',
        includeDiagnostics: false,
      );

      final body = payload.formatBody();
      expect(body, contains('Love the cinema design!'));
      expect(body, isNot(contains('Diagnostic Context')));
    });

    test('generates valid mailto URI with encoded query parameters', () {
      const payload = FeedbackPayload(
        category: FeedbackCategory.improvement,
        subject: 'Keyboard shortcuts',
        message: 'Please add spacebar to pause.',
      );

      final uri = payload.toMailtoUri(recipient: 'feedback@reelhouse.app');

      expect(uri.scheme, equals('mailto'));
      expect(uri.path, equals('feedback@reelhouse.app'));
      expect(
        uri.queryParameters['subject'],
        equals('REELHOUSE [Feature Suggestion]: Keyboard shortcuts'),
      );
      expect(
        uri.queryParameters['body'],
        contains('Please add spacebar to pause.'),
      );
    });
  });
}
