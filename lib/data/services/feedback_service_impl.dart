import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../domain/models/feedback_models.dart';
import '../../domain/services/feedback_service.dart';

/// Concrete implementation of [FeedbackService] connecting to the dedicated
/// stateless Cloudflare feedback submission worker.
class FeedbackServiceImpl implements FeedbackService {
  final String endpointUrl;
  final http.Client _client;
  final Duration timeout;
  final Uuid _uuid;

  FeedbackServiceImpl({
    String? endpointUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    Uuid? uuid,
  }) : endpointUrl =
           endpointUrl ??
           const String.fromEnvironment(
             'FEEDBACK_ENDPOINT_URL',
             defaultValue: 'https://feedback.reelhouse.app',
           ),
       _client = client ?? http.Client(),
       _uuid = uuid ?? const Uuid();

  @override
  String getPlatformIdentifier() {
    try {
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      return Platform.operatingSystem;
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Future<FeedbackSubmissionResult> submitFeedback(
    FeedbackPayload payload,
  ) async {
    final submissionUri = Uri.parse(
      '${endpointUrl.replaceAll(RegExp(r'/+$'), '')}/v1/feedback',
    );

    final idempotencyKey = _uuid.v4();
    final requestBody = jsonEncode(payload.toJson());

    try {
      final response = await _client
          .post(
            submissionUri,
            headers: {
              'Content-Type': 'application/json',
              'Idempotency-Key': idempotencyKey,
              'X-Idempotency-Key': idempotencyKey,
            },
            body: requestBody,
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return FeedbackSubmissionResult.success();
      } else if (response.statusCode == 429) {
        return FeedbackSubmissionResult.rateLimited();
      } else if (response.statusCode == 400) {
        return FeedbackSubmissionResult.validationError();
      } else {
        return FeedbackSubmissionResult.serverError();
      }
    } on SocketException {
      return FeedbackSubmissionResult.networkError();
    } on TimeoutException {
      return FeedbackSubmissionResult.networkError();
    } on http.ClientException {
      return FeedbackSubmissionResult.networkError();
    } catch (_) {
      return FeedbackSubmissionResult.networkError();
    }
  }

  @override
  Future<void> copyFeedbackToClipboard(FeedbackPayload payload) async {
    final text = '${payload.formatSubject()}\n\n${payload.formatBody()}';
    await Clipboard.setData(ClipboardData(text: text));
  }
}
