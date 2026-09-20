import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/models/feedback_models.dart';

void main() {
  group('FeedbackCategory', () {
    test('provides distinct user-facing display names and subject tags', () {
      expect(FeedbackCategory.bug.displayName, 'Report a Bug');
      expect(FeedbackCategory.bug.subjectTag, '[Bug]');
      expect(FeedbackCategory.bug.wireCategory, 'bug');

      expect(
        FeedbackCategory.improvement.displayName,
        'Suggest an Improvement',
      );
      expect(FeedbackCategory.improvement.subjectTag, '[Suggestion]');
      expect(FeedbackCategory.improvement.wireCategory, 'suggestion');

      expect(FeedbackCategory.general.displayName, 'General Feedback');
      expect(FeedbackCategory.general.subjectTag, '[General]');
      expect(FeedbackCategory.general.wireCategory, 'general');
    });
  });

  group('FeedbackPayload', () {
    test('formats subject line with and without optional subject', () {
      const pWithSubject = FeedbackPayload(
        category: FeedbackCategory.bug,
        subject: 'Player crash',
        message: 'Something went wrong',
      );
      expect(pWithSubject.formatSubject(), '[MATINEE][Bug] Player crash');

      const pWithoutSubject = FeedbackPayload(
        category: FeedbackCategory.improvement,
        message: 'Add subtitles search',
      );
      expect(pWithoutSubject.formatSubject(), '[MATINEE][Suggestion] Feedback');
    });

    test('formats body with message and non-sensitive diagnostic context', () {
      const payload = FeedbackPayload(
        category: FeedbackCategory.bug,
        subject: 'Subtitle sync issue',
        message: 'Subtitles are 2 seconds ahead of video playback.',
        includeDiagnostics: true,
        appVersion: '1.0.0',
        platformName: 'Windows',
      );

      final body = payload.formatBody();

      expect(body, contains('Category: Report a Bug'));
      expect(body, contains('Subject: Subtitle sync issue'));
      expect(
        body,
        contains('Message:\nSubtitles are 2 seconds ahead of video playback.'),
      );
      expect(body, contains('Diagnostics:\nMATINEE 1.0.0\nPlatform: Windows'));
    });

    test('formats body when diagnostics are omitted', () {
      const payload = FeedbackPayload(
        category: FeedbackCategory.general,
        message: 'Great application!',
        includeDiagnostics: false,
      );

      final body = payload.formatBody();
      expect(body, contains('Category: General Feedback'));
      expect(body, contains('Message:\nGreat application!'));
      expect(body, contains('Diagnostics:\nNot included'));
    });

    test('toJson serializes strictly allowlisted fields with diagnostics', () {
      const payload = FeedbackPayload(
        category: FeedbackCategory.bug,
        subject: 'Crash on launch',
        message: 'App closes immediately',
        includeDiagnostics: true,
        appVersion: '1.0.0',
        platformName: 'macOS',
      );

      final json = payload.toJson();
      expect(json, {
        'category': 'bug',
        'subject': 'Crash on launch',
        'message': 'App closes immediately',
        'diagnostics': {'appVersion': '1.0.0', 'platform': 'macOS'},
      });
    });

    test(
      'toJson serializes null diagnostics when includeDiagnostics is false',
      () {
        const payload = FeedbackPayload(
          category: FeedbackCategory.improvement,
          message: 'Add dark mode auto-schedule',
          includeDiagnostics: false,
        );

        final json = payload.toJson();
        expect(json, {
          'category': 'suggestion',
          'message': 'Add dark mode auto-schedule',
          'diagnostics': null,
        });
      },
    );
  });

  group('FeedbackPayload Security & Privacy Isolation', () {
    test(
      'CRITICAL: Payload serialization NEVER contains sensitive keys or state',
      () {
        const payload = FeedbackPayload(
          category: FeedbackCategory.bug,
          subject: 'Security validation test',
          message: 'Safe test message',
          includeDiagnostics: true,
          appVersion: '1.0.0',
          platformName: 'Windows',
        );

        final json = payload.toJson();

        // Forbidden keys check
        const forbiddenKeys = [
          'tmdbApiKey',
          'apiKey',
          'accessToken',
          'bearerToken',
          'library',
          'movies',
          'tvShows',
          'mediaSources',
          'storagePaths',
          'collections',
          'playbackHistory',
          'profile',
          'profilePhoto',
          'avatarPath',
          'deviceId',
          'ipAddress',
        ];

        for (final key in forbiddenKeys) {
          expect(
            json.containsKey(key),
            isFalse,
            reason: 'Payload must never include $key',
          );
        }

        // Validate top-level keys are only category, subject, message, diagnostics
        expect(
          json.keys.toSet().difference({
            'category',
            'subject',
            'message',
            'diagnostics',
          }),
          isEmpty,
        );

        // Validate diagnostics keys
        if (json['diagnostics'] != null) {
          final diagMap = json['diagnostics'] as Map<String, dynamic>;
          expect(
            diagMap.keys.toSet().difference({'appVersion', 'platform'}),
            isEmpty,
          );
        }
      },
    );
  });

  group('FeedbackSubmissionResult', () {
    test('provides distinct factory results and user messages', () {
      final success = FeedbackSubmissionResult.success();
      expect(success.isSuccess, isTrue);
      expect(success.status, FeedbackSubmissionStatus.success);

      final networkErr = FeedbackSubmissionResult.networkError();
      expect(networkErr.isSuccess, isFalse);
      expect(
        networkErr.userMessage,
        "Couldn't send feedback. Check your internet connection and try again.",
      );

      final rateLimited = FeedbackSubmissionResult.rateLimited();
      expect(rateLimited.isSuccess, isFalse);
      expect(rateLimited.userMessage, 'Please try again later.');

      final serverErr = FeedbackSubmissionResult.serverError();
      expect(serverErr.isSuccess, isFalse);
      expect(
        serverErr.userMessage,
        "Feedback couldn't be sent right now. Please try again later.",
      );

      final valErr = FeedbackSubmissionResult.validationError();
      expect(valErr.isSuccess, isFalse);
      expect(valErr.userMessage, 'Invalid feedback request.');
    });
  });
}
