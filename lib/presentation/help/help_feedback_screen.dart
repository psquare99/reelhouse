import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../domain/services/feedback_service.dart';
import '../widgets/feedback_dialog.dart';

/// A help center with FAQ accordion and a Send Feedback entry point.
///
/// This screen answers common user questions about REELHOUSE and provides
/// a single entry to the existing FeedbackDialog.
class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key, required this.feedbackService});

  final FeedbackService feedbackService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── FAQ ──────────────────────────────────────────────
            Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: CinemaTheme.eyebrow(context),
            ),
            const SizedBox(height: 8),
            ..._faqSections.map(
              (section) =>
                  _FaqSection(title: section.title, items: section.items),
            ),

            const SizedBox(height: 28),

            // ── Send Feedback ────────────────────────────────────
            Text('SUPPORT', style: CinemaTheme.eyebrow(context)),
            const SizedBox(height: 8),
            _SupportCard(feedbackService: feedbackService),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── FAQ Data ──────────────────────────────────────────────────

class _FaqSectionData {
  const _FaqSectionData({required this.title, required this.items});
  final String title;
  final List<_FaqItemData> items;
}

class _FaqItemData {
  const _FaqItemData({required this.question, required this.answer});
  final String question;
  final String answer;
}

const List<_FaqSectionData> _faqSections = [
  _FaqSectionData(
    title: 'Getting Started',
    items: [
      _FaqItemData(
        question: 'What is REELHOUSE?',
        answer:
            'REELHOUSE is a personal media library app for your computer. '
            'It lets you organize movies and TV shows in one place, with '
            'beautiful metadata like posters and descriptions. You can also '
            'save copies of your files for offline playback.',
      ),
      _FaqItemData(
        question: 'How do I add my media?',
        answer:
            'Go to Settings > Storage Locations and click "Add Storage" to '
            'choose a folder on your computer that contains your video files. '
            'REELHOUSE will scan the folder and add everything it finds to '
            'your library.',
      ),
      _FaqItemData(
        question: 'How do I rescan a folder?',
        answer:
            'In Settings > Storage Locations you can click "Scan Now" next to '
            'a storage location to rescan it. This picks up any new or removed '
            'files since the last scan.',
      ),
    ],
  ),
  _FaqSectionData(
    title: 'Metadata & Organization',
    items: [
      _FaqItemData(
        question: 'Where do movie and TV show details come from?',
        answer:
            'REELHOUSE looks up titles on TMDB (The Movie Database), a free '
            'online database of movies and TV shows. If you enable TMDB in '
            'Settings, the app will automatically fetch posters, descriptions, '
            'ratings, and episode details for your media.',
      ),
      _FaqItemData(
        question: 'How do I set up TMDB?',
        answer:
            'Go to Settings > TMDB and enter your free TMDB API key. You can '
            'get one by creating an account at themoviedb.org and requesting '
            'an API key under your account settings. Once the key is saved, '
            'metadata will start downloading automatically.',
      ),
    ],
  ),
  _FaqSectionData(
    title: 'Playback & Files',
    items: [
      _FaqItemData(
        question: 'Can I watch videos offline?',
        answer:
            'Yes. When you click the download button on a movie or episode, '
            'REELHOUSE saves a copy of the file to the offline storage folder '
            'you configured in Settings > Offline Storage. You can then watch '
            'it without accessing the original file. These are copies, not '
            'moves — your original files stay where they are.',
      ),
      _FaqItemData(
        question: 'What video formats are supported?',
        answer:
            'REELHOUSE plays most common video formats, including MP4, MKV, '
            'AVI, MOV, and WebM. The exact list depends on your system. If a '
            'file does not play, it may use a codec that is not available on '
            'your computer.',
      ),
    ],
  ),
  _FaqSectionData(
    title: 'Storage & Data',
    items: [
      _FaqItemData(
        question: 'Can I use more than one storage location?',
        answer:
            'Yes. You can add as many folders as you need in Settings > Storage '
            'Locations. You can even connect to network drives or shared folders. '
            'REELHOUSE keeps track of which files live in which locations.',
      ),
      _FaqItemData(
        question: 'How do I back up my library data?',
        answer:
            'Go to Settings > Backup & Restore and click "Export Backup" to '
            'save a copy of your library data (playlists, watch history, and '
            'metadata). You can restore it later with "Import Backup." This '
            'does not include your actual video files — just the library data.',
      ),
      _FaqItemData(
        question: 'What does "Identify Unmatched Media" do?',
        answer:
            'If some of your files were not automatically matched to a movie '
            'or TV show, you can click "Identify Unmatched Media" in Settings > '
            'TMDB. This lets you search for a title and link it to a file that '
            'REELHOUSE could not identify.',
      ),
    ],
  ),
  _FaqSectionData(
    title: 'Getting Help',
    items: [
      _FaqItemData(
        question: 'How do I report a bug or send feedback?',
        answer:
            'Scroll down to the "Send Feedback" button at the bottom of this '
            'screen. You can choose a category, describe the issue, and '
            'optionally leave your email so we can follow up.',
      ),
    ],
  ),
];

// ─── Accordion Section ─────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  const _FaqSection({required this.title, required this.items});
  final String title;
  final List<_FaqItemData> items;

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) =>
              _FaqAccordionItem(question: item.question, answer: item.answer),
        ),
      ],
    );
  }
}

// ─── Single Accordion Item ─────────────────────────────────────

class _FaqAccordionItem extends StatefulWidget {
  const _FaqAccordionItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqAccordionItem> createState() => _FaqAccordionItemState();
}

class _FaqAccordionItemState extends State<_FaqAccordionItem> {
  bool _expanded = false;

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Text(
                      widget.answer,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Support Card ──────────────────────────────────────────────

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.feedbackService});
  final FeedbackService feedbackService;

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => FeedbackDialog(feedbackService: feedbackService),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.feedback_outlined, size: 22, color: theme.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Feedback',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Report a bug, suggest a feature, or ask a question',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
