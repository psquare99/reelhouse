import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/database.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../domain/models/availability_status.dart';
import '../../domain/models/playback_resolution.dart';
import '../../domain/models/watch_state.dart';
import '../../domain/query/episode_query.dart';
import '../../domain/query/library_result.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/query/season_query.dart';
import '../../domain/repository/library_repository.dart';
import '../../domain/services/availability_resolver.dart';
import '../../domain/services/playback_launcher_service.dart';
import '../../domain/services/playback_source_resolver.dart';
import '../widgets/availability_action_button.dart';
import '../widgets/cinema_poster_image.dart';

/// Cinematic TV show detail screen displaying show metadata, seasons,
/// episodes, source-aware episode availability, and single/batch offline download hooks.
class TvShowDetailScreen extends StatefulWidget {
  final String showId;
  final LibraryRepository repository;
  final AppDatabase? database;

  TvShowDetailScreen({
    super.key,
    required this.showId,
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
  State<TvShowDetailScreen> createState() => _TvShowDetailScreenState();
}

class _TvShowDetailScreenState extends State<TvShowDetailScreen> {
  final PlaybackSourceResolver _resolver = const PlaybackSourceResolver();
  PlaybackLauncherService? _playbackLauncher;
  String? _selectedSeasonId;
  late Stream<TvShowLibraryItem?> _showStream;
  late Stream<List<Storage>> _storageStream;
  late Stream<LibraryResult<SeasonLibraryItem>> _seasonsStream;

  @override
  void initState() {
    super.initState();
    if (widget.database != null) {
      _playbackLauncher = PlaybackLauncherService(database: widget.database!);
    }
    _initStreams();
  }

  @override
  void didUpdateWidget(covariant TvShowDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId ||
        oldWidget.repository != widget.repository ||
        oldWidget.database != widget.database) {
      _initStreams();
    }
  }

  void _initStreams() {
    _showStream = widget.repository.watchTvShowById(widget.showId);
    _storageStream = widget.database != null
        ? widget.database!.watchAllStorages()
        : Stream.value([]);
    _seasonsStream = widget.repository.watchSeasons(
      SeasonQuery.forShow(widget.showId),
    );
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
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Episodes for this show are stored on "${storageName ?? 'an external drive'}".\n\n'
          'Please connect the storage disk to this device. REELHOUSE will automatically recognize it.',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handlePlayEpisode(EpisodeLibraryItem episode) async {
    if (widget.database == null) return;
    final tokens = CinemaTheme.of(context);
    final sources = await widget.database!.getSourcesForEpisode(episode.id);
    final storages = await widget.database!.getAllStorages();
    final storageMap = {for (final s in storages) s.id: s};
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
    final sourceId = resolution.selectedSourceId;
    if (sourceId == null) {
      _showConnectDiskDialog(resolution.storageName);
      return;
    }

    final epTitle = episode.name ?? 'Episode ${episode.episodeNumber}';
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $epTitle in player...'),
        backgroundColor: tokens.surface1,
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
    final tokens = CinemaTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface2,
        title: Row(
          children: [
            Icon(Icons.error_outline, color: tokens.accent, size: 24),
            const SizedBox(width: 10),
            Text(
              'Playback Diagnostic',
              style: TextStyle(color: tokens.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.errorMessage ?? 'Unable to open media player.',
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

  void _showM5DownloadDialog(String title, String target) {
    final tokens = CinemaTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface2,
        title: Row(
          children: [
            Icon(Icons.download_rounded, color: tokens.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Download to Device',
                style: TextStyle(color: tokens.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copy "$target" to your local device storage?',
              style: TextStyle(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This allows offline playback without needing the external drive connected.',
              style: TextStyle(
                color: tokens.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
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
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Offline transfer scheduled for "$target".'),
                  backgroundColor: tokens.surface1,
                ),
              );
            },
            child: const Text('Start Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return StreamBuilder<TvShowLibraryItem?>(
      stream: _showStream,
      builder: (context, showSnapshot) {
        final show = showSnapshot.data;
        if (show == null) {
          return Scaffold(
            backgroundColor: tokens.background,
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: 0.0,
                  color: tokens.accent,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: tokens.background,
          body: StreamBuilder<List<Storage>>(
            stream: _storageStream,
            builder: (context, storageSnapshot) {
              final storages = storageSnapshot.data ?? [];
              final storageMap = {for (final s in storages) s.id: s};

              return StreamBuilder<LibraryResult<SeasonLibraryItem>>(
                stream: _seasonsStream,
                builder: (context, seasonsSnapshot) {
                  final seasons = seasonsSnapshot.data?.items ?? [];
                  if (_selectedSeasonId == null && seasons.isNotEmpty) {
                    final defaultSeason = seasons.firstWhere(
                      (s) => s.seasonNumber == 1,
                      orElse: () => seasons.first,
                    );
                    _selectedSeasonId = defaultSeason.id;
                  }

                  final selectedSeason = seasons
                      .cast<SeasonLibraryItem?>()
                      .firstWhere(
                        (s) => s?.id == _selectedSeasonId,
                        orElse: () => seasons.isNotEmpty ? seasons.first : null,
                      );

                  return CustomScrollView(
                    slivers: [
                      // Cinematic Hero Backdrop
                      SliverAppBar(
                        expandedHeight: 320,
                        pinned: true,
                        backgroundColor: tokens.background,
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
                                      tokens.background.withValues(alpha: 0.6),
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
                                style: CinemaTheme.displaySerif(
                                  context,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (show.originalTitle != null &&
                                  show.originalTitle !=
                                      (show.title ?? show.detectedTitle)) ...[
                                const SizedBox(height: 4),
                                Text(
                                  show.originalTitle!,
                                  style: TextStyle(
                                    color: tokens.textSecondary,
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
                                      color: tokens.surface1,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: tokens.border),
                                    ),
                                    child: Text(
                                      '${seasons.length} ${seasons.length == 1 ? 'Season' : 'Seasons'}',
                                      style: TextStyle(
                                        color: tokens.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (show.firstAirDate != null)
                                    Text(
                                      '${show.firstAirDate!.year}',
                                      style: TextStyle(
                                        color: tokens.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  if (show.rating != null && show.rating! > 0)
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
                                          show.rating!.toStringAsFixed(1),
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
                                          ? tokens.accent
                                          : tokens.textSecondary,
                                    ),
                                    tooltip: show.isWatchlist
                                        ? 'In Watchlist'
                                        : 'Add to Watchlist',
                                    onPressed: () =>
                                        widget.repository.toggleTvShowWatchlist(
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
                                          ? tokens.accent
                                          : tokens.textSecondary,
                                    ),
                                    tooltip: show.isFavorite
                                        ? 'Favorited'
                                        : 'Add to Favorites',
                                    onPressed: () =>
                                        widget.repository.toggleTvShowFavorite(
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
                                  style: TextStyle(
                                    color: tokens.textSecondary,
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
                                    Text(
                                      'SEASONS',
                                      style: CinemaTheme.eyebrow(
                                        context,
                                        fontSize: 13,
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
                                          foregroundColor: tokens.accent,
                                          side: BorderSide(
                                            color: tokens.borderStrong,
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
                                      final label = season.displayName;

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
                                        selectedColor: tokens.accent.withValues(
                                          alpha: 0.14,
                                        ),
                                        backgroundColor: tokens.surface1,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? tokens.accent
                                              : tokens.textSecondary,
                                          fontWeight: isSelected
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                          fontSize: 13,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? tokens.accent
                                                : tokens.border,
                                            width: 1,
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
                        StreamBuilder<LibraryResult<EpisodeLibraryItem>>(
                          stream: widget.repository.watchEpisodes(
                            EpisodeQuery.forSeason(selectedSeason.id),
                          ),
                          builder: (context, episodesSnapshot) {
                            final episodes = episodesSnapshot.data?.items ?? [];
                            if (episodes.isEmpty) {
                              return SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      'No episodes indexed for this season yet.',
                                      style: TextStyle(color: tokens.textMuted),
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
                                    repository: widget.repository,
                                    storageMap: storageMap,
                                    onConnectDisk: _showConnectDiskDialog,
                                    onPlay: () => _handlePlayEpisode(episode),
                                    onDownload: () => _showM5DownloadDialog(
                                      'Episode Download',
                                      episode.name ??
                                          'Episode ${episode.episodeNumber}',
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

class _EpisodeCard extends StatelessWidget {
  final EpisodeLibraryItem episode;
  final LibraryRepository repository;
  final Map<String, Storage> storageMap;
  final void Function(String?) onConnectDisk;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const _EpisodeCard({
    required this.episode,
    required this.repository,
    required this.storageMap,
    required this.onConnectDisk,
    required this.onPlay,
    required this.onDownload,
  });

  PlaybackResolution get _resolution {
    switch (episode.availability) {
      case AvailabilityStatus.availableLocally:
        return const PlaybackResolution(action: PlaybackAction.playOffline);
      case AvailabilityStatus.availableOnRemovableStorage:
      case AvailabilityStatus.availableOnMultipleSources:
        return const PlaybackResolution(action: PlaybackAction.play);
      case AvailabilityStatus.unavailable:
        return const PlaybackResolution(action: PlaybackAction.connectDisk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);
    final resolution = _resolution;
    final isLocal = episode.availability == AvailabilityStatus.availableLocally;
    final isExternal =
        episode.availability ==
            AvailabilityStatus.availableOnRemovableStorage ||
        episode.availability == AvailabilityStatus.availableOnMultipleSources;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Episode thumbnail / still image (16:9 ratio)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 124,
                  height: 70,
                  child: CinemaPosterImage(
                    imagePath: episode.stillPath,
                    fallbackWidget: Container(
                      width: 124,
                      height: 70,
                      decoration: BoxDecoration(
                        color: tokens.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.border),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.movie_outlined,
                            color: tokens.textMuted.withValues(alpha: 0.5),
                            size: 28,
                          ),
                          Positioned(
                            bottom: 4,
                            right: 6,
                            child: Text(
                              episode.isExtra
                                  ? 'EXTRA'
                                  : 'EP ${episode.episodeNumber}',
                              style: TextStyle(
                                color: tokens.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          episode.isExtra
                              ? 'EXTRA'
                              : 'Episode ${episode.episodeNumber}',
                          style: TextStyle(
                            color: tokens.accent,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (episode.runtime != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· ${Formatters.formatRuntime(episode.runtime)}',
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      episode.displayName,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              // Watched Toggle
              IconButton(
                icon: Icon(
                  episode.watchState == WatchState.watched
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: episode.watchState == WatchState.watched
                      ? tokens.accent
                      : tokens.textMuted,
                  size: 20,
                ),
                tooltip: episode.watchState == WatchState.watched
                    ? 'Mark Unwatched'
                    : 'Mark Watched',
                onPressed: () {
                  repository.setEpisodeWatchState(
                    episode.id,
                    episode.watchState == WatchState.watched
                        ? WatchState.unwatched
                        : WatchState.watched,
                  );
                },
              ),
            ],
          ),

          if (episode.overview != null && episode.overview!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              episode.overview!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.textSecondary,
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
                onPlay: onPlay,
                onConnectDisk: () => onConnectDisk(null),
              ),

              if (!isLocal && isExternal)
                OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('DOWNLOAD', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.accent,
                    side: BorderSide(color: tokens.borderStrong),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else if (isLocal)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.offline_pin,
                      color: tokens.stateOffline,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'OFFLINE',
                      style: TextStyle(
                        color: tokens.stateOffline,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
