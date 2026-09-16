import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../data/network/tmdb_models.dart';
import '../../domain/metadata/metadata_service.dart';

/// Screen displaying the "Needs Verification" queue according to Sections 14 and 44.
///
/// Shows all unmatched movies and TV series where automatic confidence identification
/// was ambiguous or low. Users can review detected attributes, search TMDB manually,
/// and permanently associate the correct entity.
class NeedsVerificationScreen extends StatefulWidget {
  final AppDatabase database;
  final MetadataService metadataService;

  const NeedsVerificationScreen({
    super.key,
    required this.database,
    required this.metadataService,
  });

  @override
  State<NeedsVerificationScreen> createState() =>
      _NeedsVerificationScreenState();
}

class _NeedsVerificationScreenState extends State<NeedsVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openManualMatchDialog({
    required String id,
    required String detectedTitle,
    int? detectedYear,
    required bool isMovie,
    String? filename,
    String? relativePath,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => _ManualMatchDialog(
        id: id,
        detectedTitle: detectedTitle,
        detectedYear: detectedYear,
        isMovie: isMovie,
        filename: filename,
        relativePath: relativePath,
        metadataService: widget.metadataService,
        onMatchApplied: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verified and updated "$detectedTitle"'),
                backgroundColor: CinemaColors.surface,
              ),
            );
            setState(() {});
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Needs Verification'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CinemaColors.amber,
          labelColor: CinemaColors.amber,
          unselectedLabelColor: CinemaColors.textSecondary,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Movies
          StreamBuilder<List<Movie>>(
            stream: widget.database
                .select(widget.database.movies)
                .watch()
                .map((list) => list.where((m) => m.tmdbId == null).toList()),
            builder: (context, snapshot) {
              final unmatched = snapshot.data ?? [];
              if (unmatched.isEmpty) {
                return _buildEmptyState(
                  title: 'No Movies Need Verification',
                  message: 'All discovered movies have verified metadata and artwork.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: unmatched.length,
                itemBuilder: (context, index) {
                  final movie = unmatched[index];
                  return FutureBuilder<List<MediaSource>>(
                    future: widget.database.getSourcesForMovie(movie.id),
                    builder: (context, sourceSnap) {
                      final source = sourceSnap.data?.firstOrNull;
                      return _buildItemCard(
                        title: movie.title ?? movie.detectedTitle,
                        year: movie.year ?? movie.detectedYear,
                        filename: source?.filename,
                        relativePath: source?.relativePath,
                        isMovie: true,
                        onResolve: () => _openManualMatchDialog(
                          id: movie.id,
                          detectedTitle: movie.detectedTitle,
                          detectedYear: movie.detectedYear ?? movie.year,
                          isMovie: true,
                          filename: source?.filename,
                          relativePath: source?.relativePath,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          // Tab 2: TV Shows
          StreamBuilder<List<TvShow>>(
            stream: widget.database
                .select(widget.database.tvShows)
                .watch()
                .map((list) => list.where((t) => t.tmdbId == null).toList()),
            builder: (context, snapshot) {
              final unmatched = snapshot.data ?? [];
              if (unmatched.isEmpty) {
                return _buildEmptyState(
                  title: 'No TV Shows Need Verification',
                  message: 'All discovered TV shows have verified metadata and artwork.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: unmatched.length,
                itemBuilder: (context, index) {
                  final show = unmatched[index];
                  return FutureBuilder<List<MediaSource>>(
                    future: widget.database.getSourcesForTvShow(show.id),
                    builder: (context, sourceSnap) {
                      final source = sourceSnap.data?.firstOrNull;
                      return _buildItemCard(
                        title: show.title ?? show.detectedTitle,
                        year: null,
                        filename: source?.filename,
                        relativePath: source?.relativePath,
                        isMovie: false,
                        onResolve: () => _openManualMatchDialog(
                          id: show.id,
                          detectedTitle: show.detectedTitle,
                          detectedYear: null,
                          isMovie: false,
                          filename: source?.filename,
                          relativePath: source?.relativePath,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 56,
              color: CinemaColors.statusAvailable,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: CinemaColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CinemaColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard({
    required String title,
    required int? year,
    required String? filename,
    required String? relativePath,
    required bool isMovie,
    required VoidCallback onResolve,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isMovie ? Icons.movie_outlined : Icons.tv_outlined,
              color: CinemaColors.amber,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: CinemaColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (year != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '($year)',
                          style: const TextStyle(
                            color: CinemaColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (filename != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CinemaColors.textMuted,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (relativePath != null && relativePath != filename) ...[
                    const SizedBox(height: 2),
                    Text(
                      relativePath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CinemaColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: onResolve,
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Resolve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CinemaColors.amber,
                foregroundColor: CinemaColors.canvas,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog presenting manual verification and candidate search according to Section 14.
class _ManualMatchDialog extends StatefulWidget {
  final String id;
  final String detectedTitle;
  final int? detectedYear;
  final bool isMovie;
  final String? filename;
  final String? relativePath;
  final MetadataService metadataService;
  final VoidCallback onMatchApplied;

  const _ManualMatchDialog({
    required this.id,
    required this.detectedTitle,
    required this.detectedYear,
    required this.isMovie,
    required this.filename,
    required this.relativePath,
    required this.metadataService,
    required this.onMatchApplied,
  });

  @override
  State<_ManualMatchDialog> createState() => _ManualMatchDialogState();
}

class _ManualMatchDialogState extends State<_ManualMatchDialog> {
  late TextEditingController _searchController;
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _candidates = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.detectedTitle);
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isMovie) {
        final results = await widget.metadataService.tmdbClient.searchMovies(
          query,
          year: widget.detectedYear,
        );
        if (mounted) {
          setState(() {
            _candidates = results;
            _isLoading = false;
          });
        }
      } else {
        final results = await widget.metadataService.tmdbClient.searchTvShows(
          query,
        );
        if (mounted) {
          setState(() {
            _candidates = results;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyMatch(dynamic candidate) async {
    setState(() => _isLoading = true);
    try {
      if (widget.isMovie && candidate is TmdbMovieSearchResult) {
        await widget.metadataService.applyMovieMatch(
          widget.id,
          candidate,
          isManual: true,
        );
      } else if (!widget.isMovie && candidate is TmdbTvSearchResult) {
        await widget.metadataService.applyTvShowMatch(
          widget.id,
          candidate,
          isManual: true,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onMatchApplied();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to apply match: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CinemaColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Identify Media',
                        style: TextStyle(
                          color: CinemaColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We could not confidently identify this ${widget.isMovie ? 'movie' : 'TV series'}.',
                        style: const TextStyle(
                          color: CinemaColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: CinemaColors.textMuted,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detected File Information (Section 14)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CinemaColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CinemaColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.filename != null) ...[
                      Text(
                        'File: ${widget.filename}',
                        style: const TextStyle(
                          color: CinemaColors.amber,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (widget.relativePath != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Path: ${widget.relativePath}',
                        style: const TextStyle(
                          color: CinemaColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Detected Title: ${widget.detectedTitle}'
                      '${widget.detectedYear != null ? ' (${widget.detectedYear})' : ''}',
                      style: const TextStyle(
                        color: CinemaColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search TMDB for correct title...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: CinemaColors.textMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _performSearch,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: CinemaColors.textPrimary),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Candidates List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: CinemaColors.amber,
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: CinemaColors.statusUnavailable,
                          ),
                        ),
                      )
                    : _candidates.isEmpty
                    ? const Center(
                        child: Text(
                          'No candidate matches found.\nTry a different search query.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: CinemaColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _candidates.length,
                        itemBuilder: (context, index) {
                          final candidate = _candidates[index];
                          final title = widget.isMovie
                              ? (candidate as TmdbMovieSearchResult).title
                              : (candidate as TmdbTvSearchResult).name;
                          final year = widget.isMovie
                              ? (candidate as TmdbMovieSearchResult).releaseYear
                              : (candidate as TmdbTvSearchResult).firstAirYear;
                          final overview = candidate.overview ?? '';
                          final posterPath = candidate.posterPath;
                          final posterUrl = posterPath != null
                              ? widget.metadataService.tmdbClient.getPosterUrl(
                                  posterPath,
                                  size: 'w92',
                                )
                              : null;

                          return Card(
                            color: CinemaColors.surface,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      width: 46,
                                      height: 69,
                                      color: CinemaColors.card,
                                      child: posterUrl != null
                                          ? Image.network(
                                              posterUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    color:
                                                        CinemaColors.textMuted,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.movie_creation,
                                              color: CinemaColors.textMuted,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$title${year != null ? ' ($year)' : ''}',
                                          style: const TextStyle(
                                            color: CinemaColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (overview.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            overview,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: CinemaColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () => _applyMatch(candidate),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: CinemaColors.amber,
                                      side: const BorderSide(
                                        color: CinemaColors.amber,
                                      ),
                                    ),
                                    child: const Text('Select'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
