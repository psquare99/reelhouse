import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../domain/query/search_spec.dart';

/// Reusable cinema-styled search bar with search mode selector and clear action.
class CinemaSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final SearchMode searchMode;
  final ValueChanged<SearchMode>? onSearchModeChanged;
  final String hintText;
  final bool showModeSelector;
  final FocusNode? focusNode;
  final bool autofocus;

  const CinemaSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.searchMode = SearchMode.all,
    this.onSearchModeChanged,
    this.hintText = 'Search movies, TV shows, and episodes...',
    this.showModeSelector = true,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);
    final hasText = controller.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: tokens.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              style: TextStyle(color: tokens.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: tokens.textMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          if (hasText)
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: tokens.textSecondary,
                size: 18,
              ),
              tooltip: 'Clear search',
              onPressed: () {
                controller.clear();
                onChanged?.call('');
                onClear?.call();
              },
            ),
          if (showModeSelector && onSearchModeChanged != null) ...[
            Container(height: 20, width: 1, color: tokens.border),
            PopupMenuButton<SearchMode>(
              tooltip: 'Search mode',
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    searchMode == SearchMode.title ? 'Title' : 'All Fields',
                    style: TextStyle(
                      color: tokens.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: tokens.accent,
                    size: 18,
                  ),
                ],
              ),
              color: tokens.surface2,
              initialValue: searchMode,
              onSelected: onSearchModeChanged,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: SearchMode.title,
                  child: Row(
                    children: [
                      Icon(
                        Icons.title_rounded,
                        color: searchMode == SearchMode.title
                            ? tokens.accent
                            : tokens.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Title Only',
                        style: TextStyle(
                          color: searchMode == SearchMode.title
                              ? tokens.accent
                              : tokens.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SearchMode.all,
                  child: Row(
                    children: [
                      Icon(
                        Icons.manage_search_rounded,
                        color: searchMode == SearchMode.all
                            ? tokens.accent
                            : tokens.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'All Fields (Overview, Director)',
                        style: TextStyle(
                          color: searchMode == SearchMode.all
                              ? tokens.accent
                              : tokens.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
