import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../data/network/tmdb_models.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/metadata/metadata_service.dart';
import '../../domain/query/library_result.dart';
import '../../domain/query/movie_query.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/query/tv_show_query.dart';
import '../../domain/repository/library_repository.dart';

/// Screen displaying the "Needs Verification" queue according to Sections 14 and 44.
///
/// Shows all unmatched movies and TV series where automatic confidence identification
/// was ambiguous or low. Users can review detected attributes, search TMDB manually,
/// and permanently associate the correct entity.
class NeedsVerificationScreen extends StatefulWidget {
  final LibraryRepository repository;
  final MetadataService metadataService;
  final AppDatabase database;

  NeedsVerificationScreen({
    super.key,
    LibraryRepository? repository,
    required this.metadataService,
    required this.database,
  }) : repository = repository ?? DriftLibraryRepository(database);

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
          StreamBuilder<LibraryResult<MovieLibraryItem>>(
            stream: widget.repository.watchMovies(
              MovieQuery.needsVerification(),
            ),
            builder: (context, snapshot) {
              final unmatched = snapshot.data?.items ?? [];
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
          StreamBuilder<LibraryResult<TvShowLibraryItem>>(
            stream: widget.repository.watchTvShows(
              TvShowQuery.needsVerification(),
            ),
            builder: (context, snapshot) {
              final unmatched = snapshot.data?.items ?? [];
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: CinemaColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (year != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '($year)',
                      style: const TextStyle(
                        color: CinemaColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (filename != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      filename,
                      style: const TextStyle(
                        color: CinemaColors.textMuted,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (relativePath != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      relativePath,
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
            ElevatedButton(
              onPressed: onResolve,
              style: ElevatedButton.styleFrom(
                backgroundColor: CinemaColors.amber,
                foregroundColor: CinemaColors.canvas,
              ),
              child: const Text('Resolve'),
            ),
          ],
        ),
      ),
    );
  }
}

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
    this.detectedYear,
    required this.isMovie,
    this.filename,
    this.relativePath,
    required this.metadataService,
    required this.onMatchApplied,
  });

  @override
  State<_ManualMatchDialog> createState() => _ManualMatchDialogState();
}

class _ManualMatchDialogState extends State<_ManualMatchDialog> {
  late TextEditingController _searchController;
  late TextEditingController _yearController;
  List<TmdbMovieSearchResult> _movieCandidates = [];
  List<TmdbTvSearchResult> _tvCandidates = [];
  bool _isSearching = false;
  bool _isApplying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.detectedTitle);
    _yearController = TextEditingController(
      text: widget.detectedYear?.toString() ?? '',
    );
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    final year = int.tryParse(_yearController.text.trim());

    try {
      if (widget.isMovie) {
        final results = await widget.metadataService.tmdbClient.searchMovies(
          query,
          year: year,
        );
        if (mounted) {
          setState(() {
            _movieCandidates = results;
            _isSearching = false;
          });
        }
      } else {
        final results = await widget.metadataService.tmdbClient.searchTvShows(
          query,
          firstAirYear: year,
        );
        if (mounted) {
          setState(() {
            _tvCandidates = results;
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Search failed: $e';
        });
      }
    }
  }

  Future<void> _applyMovieMatch(TmdbMovieSearchResult candidate) async {
    setState(() => _isApplying = true);
    try {
      await widget.metadataService.applyMovieMatch(
        widget.id,
        candidate,
        isManual: true,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onMatchApplied();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApplying = false;
          _errorMessage = 'Failed to apply metadata: $e';
        });
      }
    }
  }

  Future<void> _applyTvMatch(TmdbTvSearchResult candidate) async {
    setState(() => _isApplying = true);
    try {
      await widget.metadataService.applyTvShowMatch(
        widget.id,
        candidate,
        isManual: true,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onMatchApplied();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApplying = false;
          _errorMessage = 'Failed to apply metadata: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CinemaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manual Identification (${widget.isMovie ? 'Movie' : 'TV Show'})',
                    style: const TextStyle(
                      color: CinemaColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: CinemaColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Detected context info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CinemaColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CinemaColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected: "${widget.detectedTitle}" ${widget.detectedYear != null ? '(${widget.detectedYear})' : ''}',
                      style: const TextStyle(
                        color: CinemaColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.filename != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'File: ${widget.filename}',
                        style: const TextStyle(
                          color: CinemaColors.textMuted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search fields
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.search, size: 20),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _yearController,
                      decoration: const InputDecoration(labelText: 'Year'),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CinemaColors.amber,
                      foregroundColor: CinemaColors.canvas,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ),

              // Results List
              Expanded(
                child: _isApplying
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Downloading metadata & caching artwork...',
                              style: TextStyle(
                                color: CinemaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : widget.isMovie
                    ? _buildMovieResults()
                    : _buildTvResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovieResults() {
    if (_movieCandidates.isEmpty && !_isSearching) {
      return const Center(
        child: Text(
          'No matching movies found on TMDB.',
          style: TextStyle(color: CinemaColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      itemCount: _movieCandidates.length,
      itemBuilder: (context, index) {
        final c = _movieCandidates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: CinemaColors.card,
          child: ListTile(
            title: Text(
              c.title,
              style: const TextStyle(
                color: CinemaColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${c.releaseDate ?? 'Unknown'} • Rating: ${c.voteAverage?.toStringAsFixed(1) ?? 'N/A'}\n${c.overview ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CinemaColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () => _applyMovieMatch(c),
              style: ElevatedButton.styleFrom(
                backgroundColor: CinemaColors.amberSubtle,
                foregroundColor: CinemaColors.amber,
              ),
              child: const Text('Select'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTvResults() {
    if (_tvCandidates.isEmpty && !_isSearching) {
      return const Center(
        child: Text(
          'No matching TV shows found on TMDB.',
          style: TextStyle(color: CinemaColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      itemCount: _tvCandidates.length,
      itemBuilder: (context, index) {
        final c = _tvCandidates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: CinemaColors.card,
          child: ListTile(
            title: Text(
              c.name,
              style: const TextStyle(
                color: CinemaColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${c.firstAirDate ?? 'Unknown'} • Rating: ${c.voteAverage?.toStringAsFixed(1) ?? 'N/A'}\n${c.overview ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CinemaColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () => _applyTvMatch(c),
              style: ElevatedButton.styleFrom(
                backgroundColor: CinemaColors.amberSubtle,
                foregroundColor: CinemaColors.amber,
              ),
              child: const Text('Select'),
            ),
          ),
        );
      },
    );
  }
}
