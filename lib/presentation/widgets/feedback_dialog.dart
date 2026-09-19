import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../domain/models/feedback_models.dart';
import '../../domain/services/feedback_service.dart';

/// Modal dialog for composing and submitting user feedback and suggestions.
///
/// Implements Milestone RC.4 of REELHOUSE Release Completeness.
class FeedbackDialog extends StatefulWidget {
  final FeedbackService feedbackService;
  final String appVersion;

  const FeedbackDialog({
    super.key,
    required this.feedbackService,
    this.appVersion = '1.0.0',
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  FeedbackCategory _selectedCategory = FeedbackCategory.bug;
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;
  bool _includeDiagnostics = true;
  String? _validationError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  FeedbackPayload _buildPayload() {
    return FeedbackPayload(
      category: _selectedCategory,
      subject: _subjectController.text.trim().isNotEmpty
          ? _subjectController.text.trim()
          : null,
      message: _messageController.text.trim(),
      includeDiagnostics: _includeDiagnostics,
      appVersion: widget.appVersion,
      platformName: widget.feedbackService.getPlatformIdentifier(),
    );
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _validationError = 'Please enter your feedback message.';
      });
      return;
    }

    setState(() {
      _validationError = null;
      _isSubmitting = true;
    });

    final payload = _buildPayload();
    final success = await widget.feedbackService.launchFeedbackEmail(payload);

    if (!mounted) return;

    final theme = CinemaTheme.of(context);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thanks — your feedback is ready to send in your email client.',
            style: TextStyle(color: theme.textPrimary),
          ),
          backgroundColor: theme.surface2,
        ),
      );
    } else {
      // Fallback: copy to clipboard
      await widget.feedbackService.copyFeedbackToClipboard(payload);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not launch email client. Feedback copied to clipboard instead.',
            style: TextStyle(color: theme.textPrimary),
          ),
          backgroundColor: theme.surface2,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleCopy() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _validationError = 'Please enter your feedback message.';
      });
      return;
    }

    final payload = _buildPayload();
    await widget.feedbackService.copyFeedbackToClipboard(payload);

    if (!mounted) return;
    final theme = CinemaTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Feedback copied to clipboard.',
          style: TextStyle(color: theme.textPrimary),
        ),
        backgroundColor: theme.surface2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);

    return Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.feedback_outlined,
                      color: theme.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feedback & Suggestions',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Help improve REELHOUSE by reporting bugs or sharing ideas.',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.textMuted, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Selection
              Text(
                'CATEGORY',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FeedbackCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  IconData icon;
                  switch (category) {
                    case FeedbackCategory.bug:
                      icon = Icons.bug_report_outlined;
                      break;
                    case FeedbackCategory.improvement:
                      icon = Icons.lightbulb_outline;
                      break;
                    case FeedbackCategory.general:
                      icon = Icons.chat_bubble_outline;
                      break;
                  }

                  return ChoiceChip(
                    avatar: Icon(
                      icon,
                      size: 15,
                      color: isSelected ? theme.onAccent : theme.textSecondary,
                    ),
                    label: Text(category.displayName),
                    selected: isSelected,
                    selectedColor: theme.accent,
                    backgroundColor: theme.surface2,
                    labelStyle: TextStyle(
                      color: isSelected ? theme.onAccent : theme.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Subject (Optional)
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject (Optional)',
                  hintText: 'Brief summary of your feedback',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  hintStyle: TextStyle(color: theme.textMuted),
                  filled: true,
                  fillColor: theme.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: TextStyle(color: theme.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 10),

              // Message (Required)
              TextField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Message *',
                  hintText: 'Describe the bug, idea, or feedback in detail...',
                  errorText: _validationError,
                  labelStyle: TextStyle(color: theme.textSecondary),
                  hintStyle: TextStyle(color: theme.textMuted),
                  filled: true,
                  fillColor: theme.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: TextStyle(color: theme.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 12),

              // Diagnostic Context Disclosure & Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _includeDiagnostics,
                      activeColor: theme.accent,
                      onChanged: (val) {
                        setState(() {
                          _includeDiagnostics = val ?? true;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Include non-sensitive diagnostic info',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'REELHOUSE v${widget.appVersion} • Platform: ${widget.feedbackService.getPlatformIdentifier()}',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Privacy Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface2.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: theme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your feedback is sent only when you choose to submit it. '
                        'REELHOUSE does not automatically attach your library, media files, TMDB API key, or personal profile data.',
                        style: TextStyle(
                          color: theme.textMuted,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                overflowSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _handleCopy,
                    icon: const Icon(Icons.copy_outlined, size: 14),
                    label: const Text('Copy Text'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textPrimary,
                      side: BorderSide(color: theme.border),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSend,
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.onAccent,
                            ),
                          )
                        : const Icon(Icons.send, size: 14),
                    label: const Text('Send Feedback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: theme.onAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
