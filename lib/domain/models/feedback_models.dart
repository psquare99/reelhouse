/// Supported feedback categories for MATINEE.
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
        return '[Bug]';
      case FeedbackCategory.improvement:
        return '[Suggestion]';
      case FeedbackCategory.general:
        return '[General]';
    }
  }

  /// Wire format string for the JSON API contract.
  String get wireCategory {
    switch (this) {
      case FeedbackCategory.bug:
        return 'bug';
      case FeedbackCategory.improvement:
        return 'suggestion';
      case FeedbackCategory.general:
        return 'general';
    }
  }
}

/// Status of an in-app feedback submission.
enum FeedbackSubmissionStatus {
  success,
  networkError,
  rateLimited,
  serverError,
  validationError,
}

/// Result of submitting feedback.
class FeedbackSubmissionResult {
  final FeedbackSubmissionStatus status;
  final String? userMessage;

  const FeedbackSubmissionResult({required this.status, this.userMessage});

  bool get isSuccess => status == FeedbackSubmissionStatus.success;

  factory FeedbackSubmissionResult.success() =>
      const FeedbackSubmissionResult(status: FeedbackSubmissionStatus.success);

  factory FeedbackSubmissionResult.networkError([
    String? message,
  ]) => FeedbackSubmissionResult(
    status: FeedbackSubmissionStatus.networkError,
    userMessage:
        message ??
        "Couldn't send feedback. Check your internet connection and try again.",
  );

  factory FeedbackSubmissionResult.rateLimited([String? message]) =>
      FeedbackSubmissionResult(
        status: FeedbackSubmissionStatus.rateLimited,
        userMessage: message ?? 'Please try again later.',
      );

  factory FeedbackSubmissionResult.serverError([String? message]) =>
      FeedbackSubmissionResult(
        status: FeedbackSubmissionStatus.serverError,
        userMessage:
            message ??
            "Feedback couldn't be sent right now. Please try again later.",
      );

  factory FeedbackSubmissionResult.validationError([String? message]) =>
      FeedbackSubmissionResult(
        status: FeedbackSubmissionStatus.validationError,
        userMessage: message ?? 'Invalid feedback request.',
      );

  @override
  String toString() =>
      'FeedbackSubmissionResult(status: $status, userMessage: $userMessage)';
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
      return '[MATINEE]${category.subjectTag} $cleanSubject';
    }
    return '[MATINEE]${category.subjectTag} Feedback';
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
      buffer.writeln('Diagnostics:');
      buffer.writeln('MATINEE $appVersion');
      buffer.writeln('Platform: $platformName');
      buffer.writeln('---');
    } else {
      buffer.writeln('---');
      buffer.writeln('Diagnostics:');
      buffer.writeln('Not included');
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Serializes strictly allowlisted fields for the Cloudflare Worker JSON endpoint.
  ///
  /// CRITICAL SECURITY: Does not and can never serialize library databases, media paths,
  /// TMDB keys, profile images, or arbitrary state.
  Map<String, dynamic> toJson() {
    final cleanSubject = subject?.trim();
    final json = <String, dynamic>{
      'category': category.wireCategory,
      if (cleanSubject != null && cleanSubject.isNotEmpty)
        'subject': cleanSubject,
      'message': message.trim(),
    };

    if (includeDiagnostics) {
      json['diagnostics'] = {
        'appVersion': appVersion.trim(),
        'platform': platformName.trim(),
      };
    } else {
      json['diagnostics'] = null;
    }

    return json;
  }
}
