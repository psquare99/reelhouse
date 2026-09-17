import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/database.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/models/playback_resolution.dart';
import '../../domain/models/watch_state.dart';
import '../../domain/query/collection_query.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/repository/library_repository.dart';
import '../../domain/services/availability_resolver.dart';
import '../../domain/services/playback_launcher_service.dart';
import '../../domain/services/playback_source_resolver.dart';
import '../widgets/availability_action_button.dart';
import '../widgets/cinema_poster_image.dart';

/// Cinematic movie detail screen presenting rich metadata, availability-aware
/// playback controls, user-owned library states, and physical media copies.
class MovieDetailScreen extends StatefulWidget {
  final String movieId;
  final LibraryRepository repository;
  final AppDatabase? database;

  MovieDetailScreen({
    super.key,
    required this.movieId,
    LibraryRepository? repository,
    AppDatabase? database,
  }) : repository =
           repository ??
           (database != null
               ? DriftLibraryRepository(database)
               : throw ArgumentError(
                   'Either repository or database must be provided',
                 )),
       database = database;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final PlaybackSourceResolver _resolver = const PlaybackSourceResolver();
  PlaybackLauncherService? _playbackLauncher;
  late Stream<MovieLibraryItem?> _movieStream;
  late Stream<List<Storage>> _storageStream;
  late Stream<List<MediaSource>> _sourcesStream;
  late Stream<List<TransferJob>> _transferStream;

  @override
  void initState() {
    super.initState();
    if (widget.database != null) {
      _playbackLauncher = PlaybackLauncherService(database: widget.database!);
    }
    _initStreams();
  }

  @override
  void didUpdateWidget(covariant MovieDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != widget.movieId ||
        oldWidget.repository != widget.repository ||
        oldWidget.database != widget.database) {
      _initStreams();
    }
  }

  void _initStreams() {
    _movieStream = widget.repository.watchMovieById(widget.movieId);
    _storageStream = widget.database != null
        ? widget.database!.watchAllStorages()
        : Stream.value([]);
    _sourcesStream = widget.database != null
        ? widget.database!.watchSourcesForMovie(widget.movieId)
        : Stream.value([]);
    _transferStream = widget.database != null
        ? widget.database!.watchActiveTransferJobsForMovie(widget.movieId)
        : Stream.value([]);
  }

  void _showConnectDiskDialog(String? storageName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CinemaColors.card,
        title: Row(
          children: [
            const Icon(
              Icons.storage_outlined,
              color: CinemaColors.amber,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Connect ${storageName ?? 'Storage Disk'}',
                style: const TextStyle(
                  color: CinemaColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This movie is located on "${storageName ?? 'an external drive'}".\n\n'
          'Please connect the storage disk to this device. REELHOUSE will automatically recognize it without re-importing.',
          style: const TextStyle(
            color: CinemaColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: CinemaColors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLocalCopy(MediaSource source) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CinemaColors.card,
        title: const Text(
          'Delete Local Copy?',
          style: TextStyle(color: CinemaColors.textPrimary),
        ),
        content: const Text(
          'This will remove the offline copy from this device to reclaim storage space.\n\n'
          'Your original copy on external storage and your cinema library history will remain untouched.',
          style: TextStyle(color: CinemaColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CinemaColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (widget.database != null) {
                await widget.database!.deleteMediaSource(source.id);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Device-local copy removed.'),
                    backgroundColor: CinemaColors.surface,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Copy'),
          ),
        ],
      ),
    );
  }

  void _handlePlay(PlaybackResolution resolution, String mediaTitle) async {
    final sourceId = resolution.selectedSourceId;
    if (sourceId == null) {
      _showConnectDiskDialog(resolution.storageName);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $mediaTitle in player...'),
        backgroundColor: CinemaColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );

    if (_playbackLauncher != null) {
      final result = await _playbackLauncher!.launchPlayback(
        mediaSourceId: sourceId,
      );
      if (!mounted) return;

      if (!result.isSuccess) {
        _showPlaybackDiagnosticDialog(result);
      }
    }
  }

  void _showPlaybackDiagnosticDialog(PlaybackLaunchResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CinemaColors.card,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: CinemaColors.amber, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Playback Diagnostic',
                style: TextStyle(color: CinemaColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.errorMessage ?? 'Unable to start playback.',
              style: const TextStyle(
                color: CinemaColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (result.resolvedPath != null) ...[
              const SizedBox(height: 16),
              const Text(
                'RESOLVED PATH',
                style: TextStyle(
                  color: CinemaColors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                result.resolvedPath!,
                style: const TextStyle(
                  color: CinemaColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: CinemaColors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _showM5DownloadDialog(String title, String filename) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CinemaColors.card,
        title: const Row(
          children: [
            Icon(
              Icons.download_for_offline_outlined,
              color: CinemaColors.amber,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Offline Download',
                style: TextStyle(color: CinemaColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copying "$filename" to local device storage is scheduled for Milestone 5.',
              style: const TextStyle(
                color: CinemaColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'REELHOUSE maintains this item\'s full identity and physical source location in your library.\n\n'
              'The background file streaming engine with verify-after-write and resume capability will be delivered in Milestone 5.',
              style: TextStyle(
                color: CinemaColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Understood',
              style: TextStyle(color: CinemaColors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCollectionDialog() async {
    final collections = await widget.repository.getCollections(
      CollectionQuery.all(),
    );
    if (!mounted) return;

    if (collections.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: CinemaColors.card,
          title: const Text(
            'No Collections',
            style: TextStyle(color: CinemaColors.textPrimary),
          ),
          content: const Text(
            'You have not created any collections yet. Create a collection from the Collections tab.',
            style: TextStyle(color: CinemaColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: CinemaColors.amber),
              ),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CinemaColors.card,
        title: const Text(
          'Add to Collection',
          style: TextStyle(color: CinemaColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: collections.length,
            itemBuilder: (context, i) {
              final col = collections[i];
              return ListTile(
                leading: const Icon(
                  Icons.collections_bookmark_outlined,
                  color: CinemaColors.amber,
                ),
                title: Text(
                  col.name,
                  style: const TextStyle(color: CinemaColors.textPrimary),
                ),
                subtitle: col.overview != null
                    ? Text(
                        col.overview!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CinemaColors.textSecondary,
                          fontSize: 12,
                        ),
                      )
                    : null,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(ctx).pop();
                  await widget.repository.addMovieToCollection(
                    col.id,
                    widget.movieId,
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Added to "${col.name}"'),
                        backgroundColor: CinemaColors.surface,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CinemaColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MovieLibraryItem?>(
      stream: _movieStream,
      builder: (context, movieSnapshot) {
        final movie = movieSnapshot.data;
        if (movie == null) {
          return const Scaffold(
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: 0.0,
                  color: CinemaColors.amber,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: StreamBuilder<List<Storage>>(
            stream: _storageStream,
            builder: (context, storageSnapshot) {
              final storages = storageSnapshot.data ?? [];
              final storageMap = {for (final s in storages) s.id: s};

              return StreamBuilder<List<MediaSource>>(
                stream: _sourcesStream,
                builder: (context, sourcesSnapshot) {
                  final sources = sourcesSnapshot.data ?? [];

                  // Map to SourceCheckInfo for availability resolver
                  final checkSources = sources.map((s) {
                    final storage = storageMap[s.storageId];
                    return SourceCheckInfo(
                      sourceId: s.id,
                      sourceType: s.sourceType,
                      storageId: s.storageId,
                      storageName: storage?.name ?? 'Storage',
                      isSourceAvailable: s.available,
                      isStorageConnected: storage?.available ?? true,
                    );
                  }).toList();

                  final resolution = _resolver.resolve(checkSources);
                  final hasLocalCopy = sources.any(
                    (s) => s.sourceType == 'localDevice',
                  );
                  final primaryRemovable = sources
                      .cast<MediaSource?>()
                      .firstWhere(
                        (s) =>
                            s?.sourceType == 'removableStorage' && s!.available,
                        orElse: () => null,
                      );

                  return StreamBuilder<List<TransferJob>>(
                    stream: _transferStream,
                    builder: (context, transferSnapshot) {
                      final activeJobs = transferSnapshot.data ?? [];
                      final isDownloading = activeJobs.isNotEmpty;
                      double? downloadProgress;
                      if (isDownloading &&
                          activeJobs.first.totalBytes > BigInt.zero) {
                        downloadProgress =
                            activeJobs.first.bytesTransferred.toDouble() /
                            activeJobs.first.totalBytes.toDouble();
                      }

                      return CustomScrollView(
                        slivers: [
                          // Cinematic Hero App Bar with Backdrop
                          SliverAppBar(
                            expandedHeight: 340,
                            pinned: true,
                            backgroundColor: CinemaColors.canvas,
                            flexibleSpace: FlexibleSpaceBar(
                              background: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CinemaPosterImage(
                                    imagePath:
                                        movie.backdropPath ?? movie.posterPath,
                                    fit: BoxFit.cover,
                                  ),
                                  // Gradient overlay for smooth readability
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          CinemaColors.canvas.withValues(
                                            alpha: 0.6,
                                          ),
                                          CinemaColors.canvas,
                                        ],
                                        stops: const [0.3, 0.7, 1.0],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Content details
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title & Original Title
                                  Text(
                                    movie.title ?? movie.detectedTitle,
                                    style: const TextStyle(
                                      color: CinemaColors.textPrimary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (movie.originalTitle != null &&
                                      movie.originalTitle !=
                                          (movie.title ??
                                              movie.detectedTitle)) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      movie.originalTitle!,
                                      style: const TextStyle(
                                        color: CinemaColors.textSecondary,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),

                                  // Metadata Badges (Year · Runtime · Rating)
                                  Wrap(
                                    spacing: 12,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (movie.year != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CinemaColors.surface,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: CinemaColors.borderSubtle,
                                            ),
                                          ),
                                          child: Text(
                                            '${movie.year}',
                                            style: const TextStyle(
                                              color: CinemaColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      if (movie.runtime != null)
                                        Text(
                                          Formatters.formatRuntime(
                                            movie.runtime,
                                          ),
                                          style: const TextStyle(
                                            color: CinemaColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      if (movie.rating != null &&
                                          movie.rating! > 0)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: CinemaColors.amber,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              movie.rating!.toStringAsFixed(1),
                                              style: const TextStyle(
                                                color: CinemaColors.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Primary Actions Row
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 10,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      // Main Playback / Connect Disk action
                                      AvailabilityActionButton(
                                        resolution: resolution,
                                        isDownloading: isDownloading,
                                        downloadProgress: downloadProgress,
                                        onPlay: () => _handlePlay(
                                          resolution,
                                          movie.title ?? movie.detectedTitle,
                                        ),
                                        onConnectDisk: () =>
                                            _showConnectDiskDialog(
                                              resolution.storageName,
                                            ),
                                      ),

                                      // Download to Device Action (when connected original exists & local copy absent)
                                      if (!hasLocalCopy &&
                                          primaryRemovable != null &&
                                          !isDownloading)
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _showM5DownloadDialog(
                                                movie.title ??
                                                    movie.detectedTitle,
                                                primaryRemovable.filename,
                                              ),
                                          icon: const Icon(
                                            Icons.download_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'DOWNLOAD TO DEVICE',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: CinemaColors.amber,
                                            side: const BorderSide(
                                              color: CinemaColors.amberSubtle,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        )
                                      else if (hasLocalCopy)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CinemaColors.surface,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: CinemaColors.amberSubtle,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: CinemaColors.amber,
                                                size: 14,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'AVAILABLE OFFLINE',
                                                style: TextStyle(
                                                  color: CinemaColors.amber,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Watchlist Toggle
                                      IconButton.outlined(
                                        icon: Icon(
                                          movie.isWatchlist
                                              ? Icons.bookmark_added
                                              : Icons.bookmark_add_outlined,
                                          color: movie.isWatchlist
                                              ? CinemaColors.amber
                                              : CinemaColors.textSecondary,
                                        ),
                                        tooltip: movie.isWatchlist
                                            ? 'In Watchlist'
                                            : 'Add to Watchlist',
                                        onPressed: () => widget.repository
                                            .toggleMovieWatchlist(
                                              movie.id,
                                              !movie.isWatchlist,
                                            ),
                                      ),

                                      // Favorite Toggle
                                      IconButton.outlined(
                                        icon: Icon(
                                          movie.isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: movie.isFavorite
                                              ? CinemaColors.amber
                                              : CinemaColors.textSecondary,
                                        ),
                                        tooltip: movie.isFavorite
                                            ? 'Favorited'
                                            : 'Add to Favorites',
                                        onPressed: () => widget.repository
                                            .toggleMovieFavorite(
                                              movie.id,
                                              !movie.isFavorite,
                                            ),
                                      ),

                                      // Add to Collection
                                      IconButton.outlined(
                                        icon: const Icon(
                                          Icons.playlist_add,
                                          color: CinemaColors.textSecondary,
                                        ),
                                        tooltip: 'Add to Collection',
                                        onPressed: _showAddToCollectionDialog,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Watch State Selector
                                  Row(
                                    children: [
                                      const Text(
                                        'Watch State: ',
                                        style: TextStyle(
                                          color: CinemaColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SegmentedButton<WatchState>(
                                        segments: const [
                                          ButtonSegment(
                                            value: WatchState.unwatched,
                                            label: Text(
                                              'Unwatched',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          ButtonSegment(
                                            value: WatchState.inProgress,
                                            label: Text(
                                              'In Progress',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          ButtonSegment(
                                            value: WatchState.watched,
                                            label: Text(
                                              'Watched',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                        selected: {movie.watchState},
                                        onSelectionChanged: (newSelection) {
                                          widget.repository.setMovieWatchState(
                                            movie.id,
                                            newSelection.first,
                                          );
                                        },
                                        style: SegmentedButton.styleFrom(
                                          backgroundColor: CinemaColors.surface,
                                          selectedBackgroundColor:
                                              CinemaColors.card,
                                          selectedForegroundColor:
                                              CinemaColors.amber,
                                          foregroundColor:
                                              CinemaColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),

                                  // Synopsis / Overview
                                  if (movie.overview != null &&
                                      movie.overview!.isNotEmpty) ...[
                                    const Text(
                                      'Synopsis',
                                      style: TextStyle(
                                        color: CinemaColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      movie.overview!,
                                      style: const TextStyle(
                                        color: CinemaColors.textSecondary,
                                        fontSize: 14,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],

                                  // Active Transfer Progress Card (if any)
                                  if (isDownloading) ...[
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: CinemaColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: CinemaColors.amberSubtle,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Copying to Device Storage...',
                                                style: TextStyle(
                                                  color: CinemaColors.amber,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                downloadProgress != null
                                                    ? '${(downloadProgress * 100).toStringAsFixed(1)}%'
                                                    : 'Queued',
                                                style: const TextStyle(
                                                  color:
                                                      CinemaColors.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          LinearProgressIndicator(
                                            value: downloadProgress,
                                            backgroundColor: CinemaColors.card,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(CinemaColors.amber),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${Formatters.formatBytes(activeJobs.first.bytesTransferred)} of ${Formatters.formatBytes(activeJobs.first.totalBytes)}',
                                            style: const TextStyle(
                                              color: CinemaColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],

                                  // YOUR COPIES SECTION
                                  const Text(
                                    'YOUR COPIES',
                                    style: TextStyle(
                                      color: CinemaColors.amber,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Physical media sources registered for this title.',
                                    style: TextStyle(
                                      color: CinemaColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  if (sources.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: CinemaColors.card,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: CinemaColors.borderSubtle,
                                        ),
                                      ),
                                      child: const Text(
                                        'No physical media copies currently registered.',
                                        style: TextStyle(
                                          color: CinemaColors.textMuted,
                                        ),
                                      ),
                                    )
                                  else
                                    ...sources.map((source) {
                                      final storage =
                                          storageMap[source.storageId];
                                      final isLocal =
                                          source.sourceType == 'localDevice';
                                      final isConnected =
                                          source.available &&
                                          (storage?.available ?? true);

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: CinemaColors.card,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: isConnected
                                                ? CinemaColors.border
                                                : CinemaColors.borderSubtle,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  isConnected
                                                      ? Icons
                                                            .check_circle_outline
                                                      : Icons
                                                            .radio_button_unchecked,
                                                  color: isConnected
                                                      ? CinemaColors.amber
                                                      : CinemaColors.textMuted,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    isLocal
                                                        ? 'On This Device (Offline Copy)'
                                                        : '${storage?.name ?? 'External Storage'} (Original)',
                                                    style: const TextStyle(
                                                      color: CinemaColors
                                                          .textPrimary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                if (isLocal)
                                                  OutlinedButton(
                                                    onPressed: () =>
                                                        _confirmDeleteLocalCopy(
                                                          source,
                                                        ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red.shade400,
                                                      side: BorderSide(
                                                        color:
                                                            Colors.red.shade900,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                    child: const Text(
                                                      'DELETE LOCAL COPY',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              source.relativePath,
                                              style: const TextStyle(
                                                color:
                                                    CinemaColors.textSecondary,
                                                fontSize: 13,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 12,
                                              children: [
                                                Text(
                                                  Formatters.formatBytes(
                                                    source.fileSize,
                                                  ),
                                                  style: const TextStyle(
                                                    color: CinemaColors
                                                        .textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (source.resolution != null)
                                                  Text(
                                                    source.resolution!,
                                                    style: const TextStyle(
                                                      color: CinemaColors
                                                          .textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                if (source.videoCodec != null)
                                                  Text(
                                                    source.videoCodec!,
                                                    style: const TextStyle(
                                                      color: CinemaColors
                                                          .textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                if (source.audioChannels !=
                                                    null)
                                                  Text(
                                                    source.audioChannels!,
                                                    style: const TextStyle(
                                                      color: CinemaColors
                                                          .textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                Text(
                                                  isConnected
                                                      ? 'Connected'
                                                      : 'Disconnected',
                                                  style: TextStyle(
                                                    color: isConnected
                                                        ? CinemaColors.amber
                                                        : CinemaColors
                                                              .textMuted,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  const SizedBox(height: 48),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
