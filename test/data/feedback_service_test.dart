import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reelhouse/data/services/feedback_service_impl.dart';
import 'package:reelhouse/domain/models/feedback_models.dart';

void main() {
  group('FeedbackServiceImpl', () {
    test(
      'submits valid payload to /v1/feedback and returns success on HTTP 200',
      () async {
        Uri? requestedUri;
        Map<String, String>? requestedHeaders;
        String? requestedBody;

        final mockClient = MockClient((request) async {
          requestedUri = request.url;
          requestedHeaders = request.headers;
          requestedBody = request.body;

          return http.Response(
            jsonEncode({'ok': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = FeedbackServiceImpl(
          endpointUrl: 'https://feedback.reelhouse.app',
          client: mockClient,
        );

        const payload = FeedbackPayload(
          category: FeedbackCategory.bug,
          subject: 'Video artifacting',
          message: 'Glitch occurs during scenes with fast motion.',
          includeDiagnostics: true,
          appVersion: '1.0.0',
          platformName: 'Windows',
        );

        final result = await service.submitFeedback(payload);

        expect(result.isSuccess, isTrue);
        expect(result.status, FeedbackSubmissionStatus.success);

        expect(
          requestedUri,
          Uri.parse('https://feedback.reelhouse.app/v1/feedback'),
        );
        expect(requestedHeaders?['Content-Type'], 'application/json');
        expect(requestedHeaders?['Idempotency-Key'], isNotEmpty);
        expect(requestedHeaders?['X-Idempotency-Key'], isNotEmpty);

        final decoded = jsonDecode(requestedBody!) as Map<String, dynamic>;
        expect(decoded['category'], 'bug');
        expect(decoded['subject'], 'Video artifacting');
        expect(
          decoded['message'],
          'Glitch occurs during scenes with fast motion.',
        );
        expect(decoded['diagnostics'], {
          'appVersion': '1.0.0',
          'platform': 'Windows',
        });
      },
    );

    test('maps HTTP 429 response to rateLimited result', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'Too many submissions. Please try again later.',
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = FeedbackServiceImpl(
        endpointUrl: 'https://feedback.reelhouse.app',
        client: mockClient,
      );

      const payload = FeedbackPayload(
        category: FeedbackCategory.general,
        message: 'Feedback test',
      );

      final result = await service.submitFeedback(payload);
      expect(result.isSuccess, isFalse);
      expect(result.status, FeedbackSubmissionStatus.rateLimited);
      expect(result.userMessage, 'Please try again later.');
    });

    test('maps HTTP 400 response to validationError result', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Invalid feedback request'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = FeedbackServiceImpl(
        endpointUrl: 'https://feedback.reelhouse.app',
        client: mockClient,
      );

      const payload = FeedbackPayload(
        category: FeedbackCategory.improvement,
        message: 'Feedback test',
      );

      final result = await service.submitFeedback(payload);
      expect(result.isSuccess, isFalse);
      expect(result.status, FeedbackSubmissionStatus.validationError);
      expect(result.userMessage, 'Invalid feedback request.');
    });

    test('maps HTTP 500/502/503 response to serverError result', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Feedback service temporarily unavailable'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = FeedbackServiceImpl(
        endpointUrl: 'https://feedback.reelhouse.app',
        client: mockClient,
      );

      const payload = FeedbackPayload(
        category: FeedbackCategory.bug,
        message: 'Feedback test',
      );

      final result = await service.submitFeedback(payload);
      expect(result.isSuccess, isFalse);
      expect(result.status, FeedbackSubmissionStatus.serverError);
      expect(
        result.userMessage,
        "Feedback couldn't be sent right now. Please try again later.",
      );
    });

    test('maps SocketException to networkError result', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Failed host lookup');
      });

      final service = FeedbackServiceImpl(
        endpointUrl: 'https://feedback.reelhouse.app',
        client: mockClient,
      );

      const payload = FeedbackPayload(
        category: FeedbackCategory.bug,
        message: 'Offline test',
      );

      final result = await service.submitFeedback(payload);
      expect(result.isSuccess, isFalse);
      expect(result.status, FeedbackSubmissionStatus.networkError);
      expect(
        result.userMessage,
        "Couldn't send feedback. Check your internet connection and try again.",
      );
    });

    test('returns correct platform identifier', () {
      final service = FeedbackServiceImpl();
      final platform = service.getPlatformIdentifier();
      expect(platform, isNotEmpty);
    });
  });
}
