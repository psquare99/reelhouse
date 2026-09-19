import '../models/feedback_models.dart';

/// Abstract service contract for composing and handing off user feedback.
abstract class FeedbackService {
  /// Opens the user's external mail client populated with the feedback payload.
  ///
  /// Returns `true` if the external handoff was successfully triggered, or `false`
  /// if launching the external mail client failed.
  Future<bool> launchFeedbackEmail(FeedbackPayload payload);

  /// Copies the formatted feedback payload text to the device clipboard.
  Future<void> copyFeedbackToClipboard(FeedbackPayload payload);

  /// Returns the current runtime platform identifier for non-sensitive diagnostics.
  String getPlatformIdentifier();
}
