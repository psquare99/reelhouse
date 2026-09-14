import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';

class SearchScreen extends StatefulWidget {
  final AppDatabase database;

  const SearchScreen({super.key, required this.database});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: CinemaColors.textPrimary, fontSize: 16),
          cursorColor: CinemaColors.amber,
          decoration: InputDecoration(
            hintText: 'Search movies, TV shows, directors...',
            hintStyle: const TextStyle(color: CinemaColors.textMuted),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: CinemaColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() => _query = val.trim());
          },
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search,
                      size: 56,
                      color: CinemaColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fast Local Cinema Search',
                      style: TextStyle(
                        color: CinemaColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Search operates instantly against your local library index without external network calls.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CinemaColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Text(
                'Searching for "$_query"...',
                style: const TextStyle(color: CinemaColors.textSecondary),
              ),
            ),
    );
  }
}
