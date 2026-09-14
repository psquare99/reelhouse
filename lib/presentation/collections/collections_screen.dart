import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.collections_bookmark_outlined,
                size: 56,
                color: CinemaColors.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'No curated collections yet.',
                style: TextStyle(
                  color: CinemaColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Curated collections group related sagas, directors, and custom film lists.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CinemaColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
