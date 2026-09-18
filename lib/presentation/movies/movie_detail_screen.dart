import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/database.dart';
import '../../data/platform/device_storage_service_impl.dart';
import '../../data/platform/local_storage_manager_impl.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../data/services/transfer_service_impl.dart';
import '../../domain/models/playback_resolution.dart';
import '../../domain/models/watch_state.dart';
import '../../domain/query/collection_query.dart';
import '../../domain/query/library_result.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/repository/library_repository.dart';
import '../../domain/services/availability_resolver.dart';
import '../../domain/services/playback_launcher_service.dart';
import '../../domain/services/playback_source_resolver.dart';
import '../../domain/services/transfer_coordinator.dart';
import '../../domain/services/transfer_service.dart';
import '../widgets/availability_action_button.dart';
import '../widgets/cinema_poster_image.dart';

/// Cinematic movie detail screen presenting rich metadata, availability-aware
/// playback controls, user-owned library states, and physical media copies.
class MovieDetailScreen extends StatefulWidget {
  final String movieId;
  final LibraryRepository repository;
  final AppDatabase? database;
  final TransferCoordinator? transferCoordinator;
  final TransferService? transferService;

  MovieDetailScreen({
    super.key,
    required this.movieId,
    LibraryRepository? repository,
    AppDatabase? database,
    this.transferCoordinator,
    this.transferService,
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
  late TransferCoordinator _transferCoordinator;
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
    _initCoordinator();
    _initStreams();
  }

  void _initCoordinator() {
    if (widget.transferCoordinator != null) {
      _transferCoordinator = widget.transferCoordinator!;
    } else if (widget.database != null) {
      final storageMgr = LocalStorageManagerImpl();
      final deviceStorage = DeviceStorageServiceImpl(
        database: widget.database!,
        localStorageManager: storageMgr,
      );
      final transferService =
          widget.transferService ??
          TransferServiceImpl(
            database: widget.database!,
            deviceStorageService: deviceStorage,
          );
      _transferCoordinator = TransferCoordinator(
        transferService: transferService,
        database: widget.database!,
        deviceStorageService: deviceStorage,
      );
    }
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
    final tokens = CinemaTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface2,
        title: Row(
          children: [
            Icon(Icons.storage_outlined, color: tokens.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Connect ${storageName ?? 'Storage Disk'}',
                style: TextStyle(color: tokens.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'This movie is located on "${storageName ?? 'an external drive'}".\n\n'
          'Please connect the storage disk to this device. REELHOUSE will automatically recognize it without re-importing.',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Dismiss',
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLocalCopy(MediaSource source) {
    final tokens = CinemaTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface2,
        title: Text(
          'Delete Local Copy?',
          style: TextStyle(color: tokens.textPrimary),
        ),
        content: Text(
          'This will remove the offline copy from this device to reclaim storage space.\n\n'
          'Your original copy on external storage and your cinema library history will remain untouched.',
          style: TextStyle(color: tokens.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _transferCoordinator.deleteOfflineCopy(source.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Device-local copy removed.'),
                    backgroundColor: tokens.surface1,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.stateUnavailable,
              foregroundColor: tokens.onAccent,
            ),
            child: const Text('Delete Copy'),
          ),
        ],
      ),
    );
  }

  void _handlePlay(
    PlaybackResolution resolution,
    String mediaTitle, {
    int? startPositionSeconds,
  }) async {
    final tokens = CinemaTheme.of(context);
    final sourceId = resolution.selectedSourceId;
    if (sourceId == null) {
      _showConnectDiskDialog(resolution.storageName);
      return;
    }

    if (_playbackLauncher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting playback for: $mediaTitle'),
          backgroundColor: tokens.surface1,
        ),
      );
      return;
    }

    final result = await _playbackLauncher!.launchPlayback(
      mediaSourceId: sourceId,
      startPositionSeconds: startPositionSeconds,
    );
    if (!mounted) return;

    if (!result.isSuccess) {
      final message = switch (result.status) {
        PlaybackStatus.storageDisconnected =>
          'Physical source is currently disconnected.',
        PlaybackStatus.fileNotFound =>
          'Media file not found at the expected path on disk.',
        PlaybackStatus.playerNotFound => 'No compatible media player found.',
        _ =>
          'Unable to launch playback: ${result.errorMessage ?? 'Unknown error'}',
      };

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: tokens.surface2,
          title: Row(
            children: [
              Icon(Icons.error_outline, color: tokens.accent, size: 24),
              const SizedBox(width: 10),
              Text(
                'Playback Error',
                style: TextStyle(color: tokens.textPrimary, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: tokens.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (result.resolvedPath != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Path: ${result.resolvedPath}',
                  style: TextStyle(
                    color: tokens.textMuted,
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
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }
  }

  void _handleSaveOffline(String title) async {
    final tokens = CinemaTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saving "$title" offline...'),
        backgroundColor: tokens.surface1,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await _transferCoordinator.requestMovieTransfer(widget.movieId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TransferCoordinator.formatError(e.toString())),
          backgroundColor: tokens.surface1,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleCancelTransfer() async {
    final tokens = CinemaTheme.of(context);
    await _transferCoordinator.cancelMediaTransfer(widget.movieId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Offline transfer cancelled.'),
        backgroundColor: tokens.surface1,
      ),
    );
  }

  void _showAddToCollectionDialog() {
    final tokens = CinemaTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface2,
        title: Text(
          'Add to Collection',
          style: TextStyle(color: tokens.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<LibraryResult<CollectionLibraryItem>>(
            stream: widget.repository.watchCollections(const CollectionQuery()),
            builder: (context, snapshot) {
              final collections = snapshot.data?.items ?? [];
              if (collections.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No custom collections created yet.\nCreate one in the Collections tab.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final col = collections[index];
                  return ListTile(
                    leading: Icon(
                      Icons.folder_special_outlined,
                      color: tokens.accent,
                    ),
                    title: Text(
                      col.name,
                      style: TextStyle(color: tokens.textPrimary),
                    ),
                    subtitle: col.overview != null
                        ? Text(
                            col.overview!,
                            style: TextStyle(color: tokens.textSecondary),
                          )
                        : null,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(ctx).pop();
                      await widget.repository.addMovieToCollection(
                        col.id,
                        widget.movieId,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Added to "${col.name}" collection.'),
                          backgroundColor: tokens.surface1,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: TextStyle(color: tokens.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      body: StreamBuilder<MovieLibraryItem?>(
        stream: _movieStream,
        builder: (context, movieSnapshot) {
          if (movieSnapshot.connectionState == ConnectionState.waiting &&
              !movieSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final movie = movieSnapshot.data;
          if (movie == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: tokens.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Movie not found in library.',
                    style: TextStyle(color: tokens.textPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Return to Movies'),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<Storage>>(
            stream: _storageStream,
            builder: (context, storageSnapshot) {
              final storages = storageSnapshot.data ?? [];
              final storageMap = {for (final s in storages) s.id: s};

              return StreamBuilder<List<MediaSource>>(
                stream: _sourcesStream,
                builder: (context, sourcesSnapshot) {
                  final sources = sourcesSnapshot.data ?? [];

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
                                s?.sourceType == 'removableStorage' &&
                                s!.available,
                            orElse: () => null,
                          );

                      return CustomScrollView(
                        slivers: [
                          // Cinematic Hero App Bar with Backdrop
                          SliverAppBar(
                            expandedHeight: 340,
                            pinned: true,
                            backgroundColor: tokens.background,
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
                                          tokens.background.withValues(
                                            alpha: 0.6,
                                          ),
                                          tokens.background,
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
                                  // Title & Original Title (Display serif per Section 6)
                                  Text(
                                    movie.title ?? movie.detectedTitle,
                                    style: CinemaTheme.displaySerif(
                                      context,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (movie.originalTitle != null &&
                                      movie.originalTitle !=
                                          (movie.title ??
                                              movie.detectedTitle)) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      movie.originalTitle!,
                                      style: TextStyle(
                                        color: tokens.textSecondary,
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
                                            color: tokens.surface1,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: tokens.border,
                                            ),
                                          ),
                                          child: Text(
                                            '${movie.year}',
                                            style: TextStyle(
                                              color: tokens.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      if (movie.runtime != null)
                                        Text(
                                          Formatters.formatRuntime(
                                            movie.runtime,
                                          ),
                                          style: TextStyle(
                                            color: tokens.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      if (movie.rating != null &&
                                          movie.rating! > 0)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: tokens.accent,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              movie.rating!.toStringAsFixed(1),
                                              style: TextStyle(
                                                color: tokens.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
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
                                        watchState: movie.watchState,
                                        playbackPositionSeconds:
                                            movie.playbackPositionSeconds,
                                        isDownloading: isDownloading,
                                        downloadProgress: downloadProgress,
                                        onPlay: () => _handlePlay(
                                          resolution,
                                          movie.title ?? movie.detectedTitle,
                                          startPositionSeconds:
                                              movie.playbackPositionSeconds,
                                        ),
                                        onConnectDisk: () =>
                                            _showConnectDiskDialog(
                                              resolution.storageName,
                                            ),
                                      ),

                                      // Save Offline Action
                                      if (!hasLocalCopy && !isDownloading)
                                        OutlinedButton.icon(
                                          onPressed: primaryRemovable != null
                                              ? () => _handleSaveOffline(
                                                  movie.title ??
                                                      movie.detectedTitle,
                                                )
                                              : null,
                                          icon: const Icon(
                                            Icons.offline_pin_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('SAVE OFFLINE'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: tokens.accent,
                                            disabledForegroundColor:
                                                tokens.textMuted,
                                            side: BorderSide(
                                              color: primaryRemovable != null
                                                  ? tokens.borderStrong
                                                  : tokens.border,
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
                                            color: tokens.surface1,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: tokens.border,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: tokens.stateOffline,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'AVAILABLE OFFLINE',
                                                style: TextStyle(
                                                  color: tokens.stateOffline,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
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
                                              ? tokens.accent
                                              : tokens.textSecondary,
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
                                              ? tokens.accent
                                              : tokens.textSecondary,
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
                                        icon: Icon(
                                          Icons.playlist_add,
                                          color: tokens.textSecondary,
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
                                      Text(
                                        'Watch State: ',
                                        style: TextStyle(
                                          color: tokens.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
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
                                          backgroundColor: tokens.surface1,
                                          selectedBackgroundColor:
                                              tokens.surface2,
                                          selectedForegroundColor:
                                              tokens.accent,
                                          foregroundColor: tokens.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),

                                  // Synopsis / Overview
                                  if (movie.overview != null &&
                                      movie.overview!.isNotEmpty) ...[
                                    Text(
                                      'Synopsis',
                                      style: TextStyle(
                                        color: tokens.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      movie.overview!,
                                      style: TextStyle(
                                        color: tokens.textSecondary,
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
                                        color: tokens.surface1,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: tokens.border,
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
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            tokens
                                                                .stateProgress,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    'Saving Offline...',
                                                    style: TextStyle(
                                                      color:
                                                          tokens.stateProgress,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    downloadProgress != null
                                                        ? '${(downloadProgress * 100).toStringAsFixed(1)}%'
                                                        : activeJobs
                                                              .first
                                                              .status,
                                                    style: TextStyle(
                                                      color: tokens.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  TextButton(
                                                    onPressed:
                                                        _handleCancelTransfer,
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          tokens.textSecondary,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          LinearProgressIndicator(
                                            value: downloadProgress,
                                            backgroundColor: tokens.surface2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  tokens.stateProgress,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${Formatters.formatBytes(activeJobs.first.bytesTransferred)} of ${Formatters.formatBytes(activeJobs.first.totalBytes)}',
                                            style: TextStyle(
                                              color: tokens.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                  ],

                                  // YOUR COPIES SECTION
                                  Text(
                                    'YOUR COPIES',
                                    style: CinemaTheme.eyebrowStyle(
                                      context,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Physical media sources registered for this title.',
                                    style: TextStyle(
                                      color: tokens.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  if (sources.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: tokens.surface1,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: tokens.border,
                                        ),
                                      ),
                                      child: Text(
                                        'No physical media copies currently registered.',
                                        style: TextStyle(
                                          color: tokens.textMuted,
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
                                          color: tokens.surface1,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isConnected
                                                ? tokens.borderStrong
                                                : tokens.border,
                                            width: 1,
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
                                                      ? tokens.accent
                                                      : tokens.textMuted,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    isLocal
                                                        ? 'On This Device (Offline Copy)'
                                                        : '${storage?.name ?? 'External Storage'} (Original)',
                                                    style: TextStyle(
                                                      color: tokens.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                      foregroundColor: tokens
                                                          .stateUnavailable,
                                                      side: BorderSide(
                                                        color: tokens.border,
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
                                              style: TextStyle(
                                                color: tokens.textSecondary,
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
                                                  style: TextStyle(
                                                    color: tokens.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if (source.resolution != null)
                                                  Text(
                                                    source.resolution!,
                                                    style: TextStyle(
                                                      color:
                                                          tokens.textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                if (source.videoCodec != null)
                                                  Text(
                                                    source.videoCodec!,
                                                    style: TextStyle(
                                                      color:
                                                          tokens.textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                if (source.audioChannels !=
                                                    null)
                                                  Text(
                                                    source.audioChannels!,
                                                    style: TextStyle(
                                                      color:
                                                          tokens.textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                Text(
                                                  isConnected
                                                      ? 'Connected'
                                                      : 'Disconnected',
                                                  style: TextStyle(
                                                    color: isConnected
                                                        ? tokens.accent
                                                        : tokens.textMuted,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
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
          );
        },
      ),
    );
  }
}
