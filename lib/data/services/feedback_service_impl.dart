import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/models/feedback_models.dart';
import '../../domain/services/feedback_service.dart';

/// Concrete implementation of [FeedbackService] using native OS process execution
/// and Flutter platform clipboard services.
class FeedbackServiceImpl implements FeedbackService {
  final String recipientEmail;

  const FeedbackServiceImpl({this.recipientEmail = 'feedback@reelhouse.app'});

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
  Future<bool> launchFeedbackEmail(FeedbackPayload payload) async {
    final mailtoUri = payload.toMailtoUri(recipient: recipientEmail);
    final urlString = mailtoUri.toString();

    try {
      if (Platform.isWindows) {
        final result = await Process.run('cmd', ['/c', 'start', '', urlString]);
        return result.exitCode == 0;
      } else if (Platform.isMacOS) {
        final result = await Process.run('open', [urlString]);
        return result.exitCode == 0;
      } else if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [urlString]);
        return result.exitCode == 0;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> copyFeedbackToClipboard(FeedbackPayload payload) async {
    final text = '${payload.formatSubject()}\n\n${payload.formatBody()}';
    await Clipboard.setData(ClipboardData(text: text));
  }
}
