/// Supported feedback categories for REELHOUSE.
enum FeedbackCategory {
  /// Bug report.
  bug,

  /// Feature request or improvement suggestion.
  improvement,

  /// General user feedback.
  general,
}

extension FeedbackCategoryExtension on FeedbackCategory {
  /// User-facing display title for the category.
  String get displayName {
    switch (this) {
      case FeedbackCategory.bug:
        return 'Report a Bug';
      case FeedbackCategory.improvement:
        return 'Suggest an Improvement';
      case FeedbackCategory.general:
        return 'General Feedback';
    }
  }

  /// Prefix used in generated email subject lines.
  String get subjectTag {
    switch (this) {
      case FeedbackCategory.bug:
        return '[Bug Report]';
      case FeedbackCategory.improvement:
        return '[Feature Suggestion]';
      case FeedbackCategory.general:
        return '[General Feedback]';
    }
  }
}

/// Structured feedback message payload.
///
/// Pure local representation: Contains zero API keys, zero library catalogue data,
/// zero media file paths, zero personal profile data, and zero telemetry.
class FeedbackPayload {
  final FeedbackCategory category;
  final String? subject;
  final String message;
  final bool includeDiagnostics;
  final String appVersion;
  final String platformName;

  const FeedbackPayload({
    required this.category,
    this.subject,
    required this.message,
    this.includeDiagnostics = true,
    this.appVersion = '1.0.0',
    this.platformName = 'Desktop',
  });

  /// Formats the email subject line.
  String formatSubject() {
    final cleanSubject = subject?.trim();
    if (cleanSubject != null && cleanSubject.isNotEmpty) {
      return 'REELHOUSE ${category.subjectTag}: $cleanSubject';
    }
    return 'REELHOUSE ${category.subjectTag}';
  }

  /// Formats the plain-text feedback body including optional diagnostic block.
  String formatBody() {
    final buffer = StringBuffer();
    buffer.writeln('Category: ${category.displayName}');
    if (subject != null && subject!.trim().isNotEmpty) {
      buffer.writeln('Subject: ${subject!.trim()}');
    }
    buffer.writeln();
    buffer.writeln('Message:');
    buffer.writeln(message.trim());
    buffer.writeln();

    if (includeDiagnostics) {
      buffer.writeln('---');
      buffer.writeln('Diagnostic Context (Non-Sensitive):');
      buffer.writeln('• Application: REELHOUSE v$appVersion');
      buffer.writeln('• Platform: $platformName');
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Generates a standard mailto URI for external mail client handoff.
  Uri toMailtoUri({String recipient = 'feedback@reelhouse.app'}) {
    return Uri(
      scheme: 'mailto',
      path: recipient,
      queryParameters: {'subject': formatSubject(), 'body': formatBody()},
    );
  }
}
