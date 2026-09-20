import '../models/feedback_models.dart';

/// Abstract service contract for composing and submitting user feedback.
abstract class FeedbackService {
  /// Submits feedback to the dedicated MATINEE submission worker.
  Future<FeedbackSubmissionResult> submitFeedback(FeedbackPayload payload);

  /// Copies the formatted feedback payload text to the device clipboard.
  Future<void> copyFeedbackToClipboard(FeedbackPayload payload);

  /// Returns the current runtime platform identifier for non-sensitive diagnostics.
  String getPlatformIdentifier();
}
