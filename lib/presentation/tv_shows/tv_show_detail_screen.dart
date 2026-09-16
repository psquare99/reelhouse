import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/database.dart';
import '../../domain/models/playback_resolution.dart';
import '../../domain/services/availability_resolver.dart';
import '../../domain/services/playback_launcher_service.dart';
import '../../domain/services/playback_source_resolver.dart';
import '../widgets/availability_action_button.dart';
import '../widgets/cinema_poster_image.dart';

/// Cinematic TV show detail screen displaying show metadata, seasons,
/// episodes, source-aware episode availability, and single/batch offline download hooks.
class TvShowDetailScreen extends StatefulWidget {
  final String showId;
  final AppDatabase database;

  const TvShowDetailScreen({
    super.key,
    required this.showId,
    required this.database,
  });

  @override
  State<TvShowDetailScreen> createState() => _TvShowDetailScreenState();
}

class _TvShowDetailScreenState extends State<TvShowDetailScreen> {
  final PlaybackSourceResolver _resolver = const PlaybackSourceResolver();
  late final PlaybackLauncherService _playbackLauncher;
  String? _selectedSeasonId;
  late Stream<TvShow?> _showStream;
  late Stream<List<Storage>> _storageStream;
  late Stream<List<Season>> _seasonsStream;

  @override
  void initState() {
    super.initState();
    _playbackLauncher = PlaybackLauncherService(database: widget.database);
    _initStreams();
  }

  @override
  void didUpdateWidget(covariant TvShowDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId ||
        oldWidget.database != widget.database) {
      _initStreams();
    }
  }

  void _initStreams() {
    _showStream = widget.database.watchTvShowById(widget.showId);
    _storageStream = widget.database.watchAllStorages();
    _seasonsStream = widget.database.watchSeasonsForShow(widget.showId);
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
          'Episodes for this show are stored on "${storageName ?? 'an external drive'}".\n\n'
          'Please connect the storage disk to this device. REELHOUSE will automatically recognize it.',
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

  void _handlePlayEpisode(
    PlaybackResolution resolution,
    Episode episode,
  ) async {
    final sourceId = resolution.selectedSourceId;
    if (sourceId == null) {
      _showConnectDiskDialog(resolution.storageName);
      return;
    }

    final epTitle = episode.name ?? 'Episode ${episode.episodeNumber}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $epTitle in player...'),
        backgroundColor: CinemaColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );

    final result = await _playbackLauncher.launchPlayback(
      mediaSourceId: sourceId,
    );
    if (!mounted) return;

    if (!result.isSuccess) {
      _showPlaybackDiagnosticDialog(result);
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

  void _showM5DownloadDialog(String title, String description) {
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
              'Copying $description to local device storage is scheduled for Milestone 5.',
              style: const TextStyle(
                color: CinemaColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'REELHOUSE maintains each episode\'s identity and physical source location in your library.\n\n'
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TvShow?>(
      stream: _showStream,
      builder: (context, showSnapshot) {
        final show = showSnapshot.data;
        if (show == null) {
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

              return StreamBuilder<List<Season>>(
                stream: _seasonsStream,
                builder: (context, seasonsSnapshot) {
                  final seasons = seasonsSnapshot.data ?? [];
                  if (_selectedSeasonId == null && seasons.isNotEmpty) {
                    _selectedSeasonId = seasons.first.id;
                  }

                  final selectedSeason = seasons.cast<Season?>().firstWhere(
                    (s) => s?.id == _selectedSeasonId,
                    orElse: () => seasons.isNotEmpty ? seasons.first : null,
                  );

                  return CustomScrollView(
                    slivers: [
                      // Cinematic Hero Backdrop
                      SliverAppBar(
                        expandedHeight: 320,
                        pinned: true,
                        backgroundColor: CinemaColors.canvas,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              CinemaPosterImage(
                                imagePath: show.backdropPath ?? show.posterPath,
                                fit: BoxFit.cover,
                                fallbackIcon: Icons.tv,
                              ),
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

                      // Show Header Info
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                show.title ?? show.detectedTitle,
                                style: const TextStyle(
                                  color: CinemaColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (show.originalTitle != null &&
                                  show.originalTitle != (show.title ?? show.detectedTitle)) ...[
                                const SizedBox(height: 4),
                                Text(
                                  show.originalTitle!,
                                  style: const TextStyle(
                                    color: CinemaColors.textSecondary,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),

                              // Badges: Seasons count · First air year · Rating
                              Wrap(
                                spacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CinemaColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: CinemaColors.borderSubtle,
                                      ),
                                    ),
                                    child: Text(
                                      '${seasons.length} ${seasons.length == 1 ? 'Season' : 'Seasons'}',
                                      style: const TextStyle(
                                        color: CinemaColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (show.firstAirDate != null)
                                    Text(
                                      '${show.firstAirDate!.year}',
                                      style: const TextStyle(
                                        color: CinemaColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  if (show.rating != null && show.rating! > 0)
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
                                          show.rating!.toStringAsFixed(1),
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
                              const SizedBox(height: 18),

                              // Action buttons (Watchlist & Favorite toggles)
                              Row(
                                children: [
                                  IconButton.outlined(
                                    icon: Icon(
                                      show.isWatchlist
                                          ? Icons.bookmark_added
                                          : Icons.bookmark_add_outlined,
                                      color: show.isWatchlist
                                          ? CinemaColors.amber
                                          : CinemaColors.textSecondary,
                                    ),
                                    tooltip: show.isWatchlist
                                        ? 'In Watchlist'
                                        : 'Add to Watchlist',
                                    onPressed: () =>
                                        widget.database.toggleTvShowWatchlist(
                                          show.id,
                                          !show.isWatchlist,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.outlined(
                                    icon: Icon(
                                      show.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: show.isFavorite
                                          ? CinemaColors.amber
                                          : CinemaColors.textSecondary,
                                    ),
                                    tooltip: show.isFavorite
                                        ? 'Favorited'
                                        : 'Add to Favorites',
                                    onPressed: () =>
                                        widget.database.toggleTvShowFavorite(
                                          show.id,
                                          !show.isFavorite,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Synopsis
                              if (show.overview != null &&
                                  show.overview!.isNotEmpty) ...[
                                Text(
                                  show.overview!,
                                  style: const TextStyle(
                                    color: CinemaColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Season Tabs / Selector
                              if (seasons.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'SEASONS',
                                      style: TextStyle(
                                        color: CinemaColors.amber,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    if (selectedSeason != null)
                                      OutlinedButton.icon(
                                        onPressed: () => _showM5DownloadDialog(
                                          'Season Download',
                                          'all episodes in this season',
                                        ),
                                        icon: const Icon(
                                          Icons.download_rounded,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'DOWNLOAD SEASON',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: CinemaColors.amber,
                                          side: const BorderSide(
                                            color: CinemaColors.amberSubtle,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 40,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: seasons.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final season = seasons[index];
                                      final isSelected =
                                          season.id == _selectedSeasonId;
                                      final label =
                                          season.name?.isNotEmpty == true
                                          ? season.name!
                                          : 'Season ${season.seasonNumber}';

                                      return ChoiceChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() {
                                              _selectedSeasonId = season.id;
                                            });
                                          }
                                        },
                                        selectedColor: CinemaColors.amber,
                                        backgroundColor: CinemaColors.surface,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? CinemaColors.canvas
                                              : CinemaColors.textSecondary,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? CinemaColors.amber
                                                : CinemaColors.borderSubtle,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Episode List for Selected Season
                      if (selectedSeason != null)
                        StreamBuilder<List<Episode>>(
                          stream: widget.database.watchEpisodesForSeason(
                            selectedSeason.id,
                          ),
                          builder: (context, episodesSnapshot) {
                            final episodes = episodesSnapshot.data ?? [];
                            if (episodes.isEmpty) {
                              return SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      'No episodes indexed for this season yet.',
                                      style: TextStyle(
                                        color: CinemaColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final episode = episodes[index];
                                  return _EpisodeCard(
                                    episode: episode,
                                    database: widget.database,
                                    storageMap: storageMap,
                                    resolver: _resolver,
                                    onConnectDisk: _showConnectDiskDialog,
                                    onPlay: (res) =>
                                        _handlePlayEpisode(res, episode),
                                    onDownload: (source) =>
                                        _showM5DownloadDialog(
                                          'Episode Download',
                                          source.filename,
                                        ),
                                  );
                                }, childCount: episodes.length),
                              ),
                            );
                          },
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 48)),
                    ],
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

class _EpisodeCard extends StatefulWidget {
  final Episode episode;
  final AppDatabase database;
  final Map<String, Storage> storageMap;
  final PlaybackSourceResolver resolver;
  final void Function(String?) onConnectDisk;
  final void Function(PlaybackResolution) onPlay;
  final void Function(MediaSource) onDownload;

  const _EpisodeCard({
    required this.episode,
    required this.database,
    required this.storageMap,
    required this.resolver,
    required this.onConnectDisk,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard> {
  late Stream<List<MediaSource>> _sourcesStream;

  @override
  void initState() {
    super.initState();
    _sourcesStream = widget.database.watchSourcesForEpisode(widget.episode.id);
  }

  @override
  void didUpdateWidget(covariant _EpisodeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episode.id != widget.episode.id ||
        oldWidget.database != widget.database) {
      _sourcesStream = widget.database.watchSourcesForEpisode(
        widget.episode.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MediaSource>>(
      stream: _sourcesStream,
      builder: (context, sourcesSnapshot) {
        final sources = sourcesSnapshot.data ?? [];

        final checkSources = sources.map((s) {
          final storage = widget.storageMap[s.storageId];
          return SourceCheckInfo(
            sourceId: s.id,
            sourceType: s.sourceType,
            storageId: s.storageId,
            storageName: storage?.name ?? 'Storage',
            isSourceAvailable: s.available,
            isStorageConnected: storage?.available ?? true,
          );
        }).toList();

        final resolution = widget.resolver.resolve(checkSources);
        final hasLocalCopy = sources.any((s) => s.sourceType == 'localDevice');
        final primaryRemovable = sources.cast<MediaSource?>().firstWhere(
          (s) => s?.sourceType == 'removableStorage' && s!.available,
          orElse: () => null,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CinemaColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CinemaColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode thumbnail / still image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 100,
                      height: 60,
                      child: CinemaPosterImage(
                        imagePath: widget.episode.stillPath,
                        fallbackIcon: Icons.tv,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Episode Title & Number
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Episode ${widget.episode.episodeNumber}',
                              style: const TextStyle(
                                color: CinemaColors.amber,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (widget.episode.runtime != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '· ${Formatters.formatRuntime(widget.episode.runtime)}',
                                style: const TextStyle(
                                  color: CinemaColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.episode.name ??
                              'Episode ${widget.episode.episodeNumber}',
                          style: const TextStyle(
                            color: CinemaColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Watched Toggle
                  IconButton(
                    icon: Icon(
                      widget.episode.watchState == 'WATCHED'
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: widget.episode.watchState == 'WATCHED'
                          ? CinemaColors.amber
                          : CinemaColors.textMuted,
                      size: 20,
                    ),
                    tooltip: widget.episode.watchState == 'WATCHED'
                        ? 'Mark Unwatched'
                        : 'Mark Watched',
                    onPressed: () {
                      widget.database.setEpisodeWatchState(
                        widget.episode.id,
                        widget.episode.watchState == 'WATCHED'
                            ? 'UNWATCHED'
                            : 'WATCHED',
                      );
                    },
                  ),
                ],
              ),

              if (widget.episode.overview != null &&
                  widget.episode.overview!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.episode.overview!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CinemaColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Bottom Actions Row: Play/Connect + Download button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AvailabilityActionButton(
                    resolution: resolution,
                    isCompact: true,
                    onPlay: () => widget.onPlay(resolution),
                    onConnectDisk: () =>
                        widget.onConnectDisk(resolution.storageName),
                  ),

                  if (!hasLocalCopy && primaryRemovable != null)
                    OutlinedButton.icon(
                      onPressed: () => widget.onDownload(primaryRemovable),
                      icon: const Icon(Icons.download_rounded, size: 14),
                      label: const Text(
                        'DOWNLOAD',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CinemaColors.amber,
                        side: const BorderSide(color: CinemaColors.amberSubtle),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  else if (hasLocalCopy)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.offline_pin,
                          color: CinemaColors.amber,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'OFFLINE',
                          style: TextStyle(
                            color: CinemaColors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
