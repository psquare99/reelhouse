import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/library_backup_models.dart';
import '../../domain/services/library_backup_service.dart';
import '../../domain/services/settings_service.dart';
import '../database/database.dart';

/// Concrete implementation of [LibraryBackupService] backed by [AppDatabase] and [SettingsService].
class LibraryBackupServiceImpl implements LibraryBackupService {
  final AppDatabase database;
  final SettingsService? settingsService;
  final Uuid _uuid;

  LibraryBackupServiceImpl({
    required this.database,
    this.settingsService,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<LibraryBackupPayload> createBackupPayload() async {
    // 1. Fetch all movies
    final dbMovies = await (database.select(
      database.movies,
    )..orderBy([(m) => drift.OrderingTerm.asc(m.title)])).get();

    final backupMovies = dbMovies
        .map(
          (m) => BackupMovie(
            id: m.id,
            metadataId: m.metadataId,
            title: m.title,
            originalTitle: m.originalTitle,
            year: m.year,
            detectedTitle: m.detectedTitle,
            detectedYear: m.detectedYear,
            identificationStatus: m.identificationStatus,
            overview: m.overview,
            runtime: m.runtime,
            releaseDate: m.releaseDate,
            posterPath: m.posterPath,
            backdropPath: m.backdropPath,
            rating: m.rating,
            voteCount: m.voteCount,
            imdbId: m.imdbId,
            tmdbId: m.tmdbId,
            metadataProvider: m.metadataProvider,
            providerItemId: m.providerItemId,
            metadataUpdatedAt: m.metadataUpdatedAt,
            genres: m.genres,
            tmdbCollectionId: m.tmdbCollectionId,
            tmdbCollectionName: m.tmdbCollectionName,
            tmdbCollectionPosterPath: m.tmdbCollectionPosterPath,
            tmdbCollectionBackdropPath: m.tmdbCollectionBackdropPath,
            createdAt: m.createdAt,
            updatedAt: m.updatedAt,
            isFavorite: m.isFavorite,
            isWatchlist: m.isWatchlist,
            watchState: m.watchState,
            playbackPositionSeconds: m.playbackPositionSeconds,
            lastPlayedAt: m.lastPlayedAt,
          ),
        )
        .toList();

    // 2. Fetch all TV shows with their seasons and episodes
    final dbShows = await (database.select(
      database.tvShows,
    )..orderBy([(t) => drift.OrderingTerm.asc(t.title)])).get();

    final backupShows = <BackupTvShow>[];
    for (final s in dbShows) {
      final dbSeasons =
          await (database.select(database.seasons)
                ..where((season) => season.showId.equals(s.id))
                ..orderBy([
                  (season) => drift.OrderingTerm.asc(season.seasonNumber),
                ]))
              .get();

      final backupSeasons = <BackupSeason>[];
      for (final season in dbSeasons) {
        final dbEpisodes =
            await (database.select(database.episodes)
                  ..where((ep) => ep.seasonId.equals(season.id))
                  ..orderBy([(ep) => drift.OrderingTerm.asc(ep.episodeNumber)]))
                .get();

        final backupEpisodes = dbEpisodes
            .map(
              (e) => BackupEpisode(
                id: e.id,
                episodeNumber: e.episodeNumber,
                name: e.name,
                overview: e.overview,
                airDate: e.airDate,
                runtime: e.runtime,
                stillPath: e.stillPath,
                rating: e.rating,
                tmdbId: e.tmdbId,
                watchState: e.watchState,
                playbackPositionSeconds: e.playbackPositionSeconds,
                lastPlayedAt: e.lastPlayedAt,
              ),
            )
            .toList();

        backupSeasons.add(
          BackupSeason(
            id: season.id,
            seasonNumber: season.seasonNumber,
            name: season.name,
            overview: season.overview,
            posterPath: season.posterPath,
            airDate: season.airDate,
            tmdbId: season.tmdbId,
            episodes: backupEpisodes,
          ),
        );
      }

      backupShows.add(
        BackupTvShow(
          id: s.id,
          metadataId: s.metadataId,
          title: s.title,
          originalTitle: s.originalTitle,
          detectedTitle: s.detectedTitle,
          identificationStatus: s.identificationStatus,
          overview: s.overview,
          firstAirDate: s.firstAirDate,
          posterPath: s.posterPath,
          backdropPath: s.backdropPath,
          rating: s.rating,
          tmdbId: s.tmdbId,
          imdbId: s.imdbId,
          metadataProvider: s.metadataProvider,
          providerItemId: s.providerItemId,
          metadataUpdatedAt: s.metadataUpdatedAt,
          genres: s.genres,
          isFavorite: s.isFavorite,
          isWatchlist: s.isWatchlist,
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
          seasons: backupSeasons,
        ),
      );
    }

    // 3. Fetch all collections with their items
    final dbCollections = await (database.select(
      database.collections,
    )..orderBy([(c) => drift.OrderingTerm.asc(c.name)])).get();

    final backupCollections = <BackupCollection>[];
    for (final col in dbCollections) {
      final dbItems =
          await (database.select(database.collectionItems)
                ..where((ci) => ci.collectionId.equals(col.id))
                ..orderBy([(ci) => drift.OrderingTerm.asc(ci.displayOrder)]))
              .get();

      final backupItems = dbItems
          .map(
            (item) => BackupCollectionItem(
              id: item.id,
              movieId: item.movieId,
              tvShowId: item.tvShowId,
              displayOrder: item.displayOrder,
              addedAt: item.addedAt,
            ),
          )
          .toList();

      backupCollections.add(
        BackupCollection(
          id: col.id,
          name: col.name,
          overview: col.overview,
          posterPath: col.posterPath,
          createdAt: col.createdAt,
          updatedAt: col.updatedAt,
          items: backupItems,
        ),
      );
    }

    // 4. Extract non-sensitive settings (NEVER export TMDB API keys or secrets!)
    BackupSettings? backupSettings;
    if (settingsService != null) {
      backupSettings = BackupSettings(
        preferredPlayer: settingsService!.preferredPlayer,
        themeMode: settingsService!.themeMode.name,
        isNavRailCollapsed: settingsService!.isNavRailCollapsed,
        userDisplayName: settingsService!.userDisplayName.isNotEmpty
            ? settingsService!.userDisplayName
            : null,
        userProfilePicturePath: settingsService!.userProfilePicturePath,
      );
    }

    return LibraryBackupPayload(
      formatVersion: kCurrentBackupFormatVersion,
      appVersion: kCurrentBackupAppVersion,
      schemaVersion: database.schemaVersion,
      exportedAt: DateTime.now().toUtc(),
      application: 'REELHOUSE',
      movies: backupMovies,
      tvShows: backupShows,
      collections: backupCollections,
      settings: backupSettings,
    );
  }

  @override
  Future<String> exportBackupToFile(String targetFilePath) async {
    final payload = await createBackupPayload();
    final jsonString = payload.toPrettyJson();

    final file = File(targetFilePath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(jsonString);
    return file.path;
  }

  @override
  Future<BackupSummary> inspectBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Backup file not found', filePath);
    }
    final content = await file.readAsString();
    return inspectBackupJson(content);
  }

  @override
  Future<BackupSummary> inspectBackupJson(String jsonContent) async {
    try {
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root backup JSON must be an object');
      }
      final payload = LibraryBackupPayload.fromJson(decoded);
      return payload.toSummary();
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Malformed backup JSON: $e');
    }
  }

  @override
  Future<BackupImportResult> importBackupFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return BackupImportResult(
          success: false,
          errorMessage: 'Backup file not found at $filePath',
        );
      }
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return const BackupImportResult(
          success: false,
          errorMessage: 'Root backup JSON must be an object',
        );
      }
      final payload = LibraryBackupPayload.fromJson(decoded);
      return await importBackupPayload(payload);
    } catch (e) {
      return BackupImportResult(
        success: false,
        errorMessage: 'Failed to read or parse backup file: $e',
      );
    }
  }

  @override
  Future<BackupImportResult> importBackupPayload(
    LibraryBackupPayload payload,
  ) async {
    if (payload.formatVersion > kCurrentBackupFormatVersion) {
      return BackupImportResult(
        success: false,
        errorMessage:
            'Unsupported backup format version ${payload.formatVersion}. Maximum supported version is $kCurrentBackupFormatVersion.',
      );
    }

    final warnings = <String>[];
    int moviesImported = 0;
    int moviesUpdated = 0;
    int showsImported = 0;
    int showsUpdated = 0;
    int seasonsImported = 0;
    int episodesImported = 0;
    int episodesUpdated = 0;
    int collectionsImported = 0;
    int collectionsUpdated = 0;
    bool settingsImported = false;

    // ID Remapping Table for collections: maps imported logical ID -> local database ID
    final movieIdMap = <String, String>{};
    final tvShowIdMap = <String, String>{};

    try {
      await database.transaction(() async {
        // --- 1. Reconcile Movies ---
        for (final m in payload.movies) {
          Movie? existing;
          if (m.tmdbId != null) {
            existing = await (database.select(
              database.movies,
            )..where((row) => row.tmdbId.equals(m.tmdbId!))).getSingleOrNull();
          }
          existing ??= await (database.select(
            database.movies,
          )..where((row) => row.id.equals(m.id))).getSingleOrNull();

          if (existing == null && m.title != null && m.year != null) {
            existing =
                await (database.select(database.movies)..where(
                      (row) =>
                          row.title.equals(m.title!) & row.year.equals(m.year!),
                    ))
                    .getSingleOrNull();
          }

          if (existing != null) {
            // Existing movie found: Reconcile watch state, flags, and metadata
            movieIdMap[m.id] = existing.id;

            final mergedFavorite = existing.isFavorite || m.isFavorite;
            final mergedWatchlist = existing.isWatchlist || m.isWatchlist;
            final mergedWatchState = _mergeWatchStates(
              existing.watchState,
              m.watchState,
            );
            final mergedPosition = _mergePlaybackPosition(
              existing.watchState,
              existing.playbackPositionSeconds,
              m.watchState,
              m.playbackPositionSeconds,
            );
            final mergedLastPlayed = _mergeLastPlayed(
              existing.lastPlayedAt,
              m.lastPlayedAt,
            );

            // Update metadata if existing was pending or imported has richer TMDB fields
            final shouldUpdateMetadata =
                existing.identificationStatus == 'PENDING' &&
                m.identificationStatus == 'IDENTIFIED';

            await (database.update(
              database.movies,
            )..where((row) => row.id.equals(existing!.id))).write(
              MoviesCompanion(
                isFavorite: drift.Value(mergedFavorite),
                isWatchlist: drift.Value(mergedWatchlist),
                watchState: drift.Value(mergedWatchState),
                playbackPositionSeconds: drift.Value(mergedPosition),
                lastPlayedAt: drift.Value(mergedLastPlayed),
                updatedAt: drift.Value(DateTime.now()),
                title: shouldUpdateMetadata
                    ? drift.Value(m.title ?? existing.title)
                    : const drift.Value.absent(),
                year: shouldUpdateMetadata
                    ? drift.Value(m.year ?? existing.year)
                    : const drift.Value.absent(),
                identificationStatus: shouldUpdateMetadata
                    ? const drift.Value('IDENTIFIED')
                    : const drift.Value.absent(),
                tmdbId: shouldUpdateMetadata
                    ? drift.Value(m.tmdbId ?? existing.tmdbId)
                    : const drift.Value.absent(),
                overview: shouldUpdateMetadata
                    ? drift.Value(m.overview ?? existing.overview)
                    : const drift.Value.absent(),
                posterPath: shouldUpdateMetadata
                    ? drift.Value(m.posterPath ?? existing.posterPath)
                    : const drift.Value.absent(),
                backdropPath: shouldUpdateMetadata
                    ? drift.Value(m.backdropPath ?? existing.backdropPath)
                    : const drift.Value.absent(),
                rating: shouldUpdateMetadata
                    ? drift.Value(m.rating ?? existing.rating)
                    : const drift.Value.absent(),
                genres: shouldUpdateMetadata
                    ? drift.Value(m.genres ?? existing.genres)
                    : const drift.Value.absent(),
              ),
            );
            moviesUpdated++;
          } else {
            // Insert brand-new movie record (with ZERO fake MediaSources)
            final newId = m.id.isNotEmpty ? m.id : 'm-${_uuid.v4()}';
            movieIdMap[m.id] = newId;

            await database
                .into(database.movies)
                .insert(
                  MoviesCompanion.insert(
                    id: newId,
                    metadataId: drift.Value(m.metadataId),
                    title: drift.Value(m.title),
                    originalTitle: drift.Value(m.originalTitle),
                    year: drift.Value(m.year),
                    detectedTitle: m.detectedTitle,
                    detectedYear: drift.Value(m.detectedYear),
                    identificationStatus: drift.Value(m.identificationStatus),
                    overview: drift.Value(m.overview),
                    runtime: drift.Value(m.runtime),
                    releaseDate: drift.Value(m.releaseDate),
                    posterPath: drift.Value(m.posterPath),
                    backdropPath: drift.Value(m.backdropPath),
                    rating: drift.Value(m.rating),
                    voteCount: drift.Value(m.voteCount),
                    imdbId: drift.Value(m.imdbId),
                    tmdbId: drift.Value(m.tmdbId),
                    metadataProvider: drift.Value(m.metadataProvider),
                    providerItemId: drift.Value(m.providerItemId),
                    metadataUpdatedAt: drift.Value(m.metadataUpdatedAt),
                    genres: drift.Value(m.genres),
                    tmdbCollectionId: drift.Value(m.tmdbCollectionId),
                    tmdbCollectionName: drift.Value(m.tmdbCollectionName),
                    tmdbCollectionPosterPath: drift.Value(
                      m.tmdbCollectionPosterPath,
                    ),
                    tmdbCollectionBackdropPath: drift.Value(
                      m.tmdbCollectionBackdropPath,
                    ),
                    createdAt: m.createdAt,
                    updatedAt: m.updatedAt,
                    isFavorite: drift.Value(m.isFavorite),
                    isWatchlist: drift.Value(m.isWatchlist),
                    watchState: drift.Value(m.watchState),
                    playbackPositionSeconds: drift.Value(
                      m.playbackPositionSeconds,
                    ),
                    lastPlayedAt: drift.Value(m.lastPlayedAt),
                  ),
                );
            moviesImported++;
          }
        }

        // --- 2. Reconcile TV Shows, Seasons, & Episodes ---
        for (final show in payload.tvShows) {
          TvShow? existingShow;
          if (show.tmdbId != null) {
            existingShow =
                await (database.select(database.tvShows)
                      ..where((row) => row.tmdbId.equals(show.tmdbId!)))
                    .getSingleOrNull();
          }
          existingShow ??= await (database.select(
            database.tvShows,
          )..where((row) => row.id.equals(show.id))).getSingleOrNull();

          if (existingShow == null && show.title != null) {
            existingShow = await (database.select(
              database.tvShows,
            )..where((row) => row.title.equals(show.title!))).getSingleOrNull();
          }

          late final String targetShowId;
          if (existingShow != null) {
            targetShowId = existingShow.id;
            tvShowIdMap[show.id] = targetShowId;

            final mergedFavorite = existingShow.isFavorite || show.isFavorite;
            final mergedWatchlist =
                existingShow.isWatchlist || show.isWatchlist;

            final shouldUpdateMetadata =
                existingShow.identificationStatus == 'PENDING' &&
                show.identificationStatus == 'IDENTIFIED';

            await (database.update(
              database.tvShows,
            )..where((row) => row.id.equals(targetShowId))).write(
              TvShowsCompanion(
                isFavorite: drift.Value(mergedFavorite),
                isWatchlist: drift.Value(mergedWatchlist),
                updatedAt: drift.Value(DateTime.now()),
                title: shouldUpdateMetadata
                    ? drift.Value(show.title ?? existingShow.title)
                    : const drift.Value.absent(),
                identificationStatus: shouldUpdateMetadata
                    ? const drift.Value('IDENTIFIED')
                    : const drift.Value.absent(),
                tmdbId: shouldUpdateMetadata
                    ? drift.Value(show.tmdbId ?? existingShow.tmdbId)
                    : const drift.Value.absent(),
                overview: shouldUpdateMetadata
                    ? drift.Value(show.overview ?? existingShow.overview)
                    : const drift.Value.absent(),
                posterPath: shouldUpdateMetadata
                    ? drift.Value(show.posterPath ?? existingShow.posterPath)
                    : const drift.Value.absent(),
                backdropPath: shouldUpdateMetadata
                    ? drift.Value(
                        show.backdropPath ?? existingShow.backdropPath,
                      )
                    : const drift.Value.absent(),
                rating: shouldUpdateMetadata
                    ? drift.Value(show.rating ?? existingShow.rating)
                    : const drift.Value.absent(),
                genres: shouldUpdateMetadata
                    ? drift.Value(show.genres ?? existingShow.genres)
                    : const drift.Value.absent(),
              ),
            );
            showsUpdated++;
          } else {
            targetShowId = show.id.isNotEmpty ? show.id : 'tv-${_uuid.v4()}';
            tvShowIdMap[show.id] = targetShowId;

            await database
                .into(database.tvShows)
                .insert(
                  TvShowsCompanion.insert(
                    id: targetShowId,
                    metadataId: drift.Value(show.metadataId),
                    title: drift.Value(show.title),
                    originalTitle: drift.Value(show.originalTitle),
                    detectedTitle: show.detectedTitle,
                    identificationStatus: drift.Value(
                      show.identificationStatus,
                    ),
                    overview: drift.Value(show.overview),
                    firstAirDate: drift.Value(show.firstAirDate),
                    posterPath: drift.Value(show.posterPath),
                    backdropPath: drift.Value(show.backdropPath),
                    rating: drift.Value(show.rating),
                    tmdbId: drift.Value(show.tmdbId),
                    imdbId: drift.Value(show.imdbId),
                    metadataProvider: drift.Value(show.metadataProvider),
                    providerItemId: drift.Value(show.providerItemId),
                    metadataUpdatedAt: drift.Value(show.metadataUpdatedAt),
                    genres: drift.Value(show.genres),
                    isFavorite: drift.Value(show.isFavorite),
                    isWatchlist: drift.Value(show.isWatchlist),
                    createdAt: show.createdAt,
                    updatedAt: show.updatedAt,
                  ),
                );
            showsImported++;
          }

          // Reconcile seasons
          for (final season in show.seasons) {
            final existingSeason =
                await (database.select(database.seasons)..where(
                      (row) =>
                          row.showId.equals(targetShowId) &
                          row.seasonNumber.equals(season.seasonNumber),
                    ))
                    .getSingleOrNull();

            late final String targetSeasonId;
            if (existingSeason != null) {
              targetSeasonId = existingSeason.id;
            } else {
              targetSeasonId = season.id.isNotEmpty
                  ? season.id
                  : 's-${_uuid.v4()}';
              await database
                  .into(database.seasons)
                  .insert(
                    SeasonsCompanion.insert(
                      id: targetSeasonId,
                      showId: targetShowId,
                      seasonNumber: season.seasonNumber,
                      name: drift.Value(season.name),
                      overview: drift.Value(season.overview),
                      posterPath: drift.Value(season.posterPath),
                      airDate: drift.Value(season.airDate),
                      tmdbId: drift.Value(season.tmdbId),
                    ),
                  );
              seasonsImported++;
            }

            // Reconcile episodes
            for (final ep in season.episodes) {
              final existingEp =
                  await (database.select(database.episodes)..where(
                        (row) =>
                            row.seasonId.equals(targetSeasonId) &
                            row.episodeNumber.equals(ep.episodeNumber),
                      ))
                      .getSingleOrNull();

              if (existingEp != null) {
                final mergedWatchState = _mergeWatchStates(
                  existingEp.watchState,
                  ep.watchState,
                );
                final mergedPosition = _mergePlaybackPosition(
                  existingEp.watchState,
                  existingEp.playbackPositionSeconds,
                  ep.watchState,
                  ep.playbackPositionSeconds,
                );
                final mergedLastPlayed = _mergeLastPlayed(
                  existingEp.lastPlayedAt,
                  ep.lastPlayedAt,
                );

                await (database.update(
                  database.episodes,
                )..where((row) => row.id.equals(existingEp.id))).write(
                  EpisodesCompanion(
                    watchState: drift.Value(mergedWatchState),
                    playbackPositionSeconds: drift.Value(mergedPosition),
                    lastPlayedAt: drift.Value(mergedLastPlayed),
                  ),
                );
                episodesUpdated++;
              } else {
                final targetEpId = ep.id.isNotEmpty
                    ? ep.id
                    : 'ep-${_uuid.v4()}';
                await database
                    .into(database.episodes)
                    .insert(
                      EpisodesCompanion.insert(
                        id: targetEpId,
                        seasonId: targetSeasonId,
                        episodeNumber: ep.episodeNumber,
                        name: drift.Value(ep.name),
                        overview: drift.Value(ep.overview),
                        airDate: drift.Value(ep.airDate),
                        runtime: drift.Value(ep.runtime),
                        stillPath: drift.Value(ep.stillPath),
                        rating: drift.Value(ep.rating),
                        tmdbId: drift.Value(ep.tmdbId),
                        watchState: drift.Value(ep.watchState),
                        playbackPositionSeconds: drift.Value(
                          ep.playbackPositionSeconds,
                        ),
                        lastPlayedAt: drift.Value(ep.lastPlayedAt),
                      ),
                    );
                episodesImported++;
              }
            }
          }
        }

        // --- 3. Reconcile Curated Collections & Items ---
        for (final col in payload.collections) {
          Collection? existingCol = await (database.select(
            database.collections,
          )..where((row) => row.id.equals(col.id))).getSingleOrNull();

          existingCol ??= await (database.select(
            database.collections,
          )..where((row) => row.name.equals(col.name))).getSingleOrNull();

          late final String targetColId;
          if (existingCol != null) {
            targetColId = existingCol.id;
            collectionsUpdated++;
          } else {
            targetColId = col.id.isNotEmpty ? col.id : 'col-${_uuid.v4()}';
            await database
                .into(database.collections)
                .insert(
                  CollectionsCompanion.insert(
                    id: targetColId,
                    name: col.name,
                    overview: drift.Value(col.overview),
                    posterPath: drift.Value(col.posterPath),
                    createdAt: col.createdAt,
                    updatedAt: col.updatedAt,
                  ),
                );
            collectionsImported++;
          }

          // Reconcile items
          for (final item in col.items) {
            final remappedMovieId = item.movieId != null
                ? (movieIdMap[item.movieId] ?? item.movieId)
                : null;
            final remappedTvShowId = item.tvShowId != null
                ? (tvShowIdMap[item.tvShowId] ?? item.tvShowId)
                : null;

            // Verify that referenced media item exists in local database
            if (remappedMovieId != null) {
              final movieExists =
                  await (database.select(database.movies)
                        ..where((row) => row.id.equals(remappedMovieId)))
                      .getSingleOrNull();
              if (movieExists == null) {
                warnings.add(
                  'Skipped collection item for movie $remappedMovieId: movie not in library.',
                );
                continue;
              }
            } else if (remappedTvShowId != null) {
              final showExists =
                  await (database.select(database.tvShows)
                        ..where((row) => row.id.equals(remappedTvShowId)))
                      .getSingleOrNull();
              if (showExists == null) {
                warnings.add(
                  'Skipped collection item for show $remappedTvShowId: show not in library.',
                );
                continue;
              }
            } else {
              continue;
            }

            // Check if already in collection
            final query = database.select(database.collectionItems)
              ..where((row) => row.collectionId.equals(targetColId));
            if (remappedMovieId != null) {
              query.where((row) => row.movieId.equals(remappedMovieId));
            } else if (remappedTvShowId != null) {
              query.where((row) => row.tvShowId.equals(remappedTvShowId));
            }
            final existingItem = await query.getSingleOrNull();

            if (existingItem == null) {
              await database
                  .into(database.collectionItems)
                  .insert(
                    CollectionItemsCompanion.insert(
                      id: 'ci-${_uuid.v4()}',
                      collectionId: targetColId,
                      movieId: drift.Value(remappedMovieId),
                      tvShowId: drift.Value(remappedTvShowId),
                      displayOrder: drift.Value(item.displayOrder),
                      addedAt: item.addedAt,
                    ),
                  );
            }
          }
        }
      });

      // --- 4. Reconcile Non-Sensitive Settings ---
      if (payload.settings != null && settingsService != null) {
        if (payload.settings!.preferredPlayer.isNotEmpty) {
          await settingsService!.setPreferredPlayer(
            payload.settings!.preferredPlayer,
          );
        }
        final themeStr = payload.settings!.themeMode;
        if (themeStr == 'light') {
          await settingsService!.setThemeMode(ThemeMode.light);
        } else if (themeStr == 'system') {
          await settingsService!.setThemeMode(ThemeMode.system);
        } else {
          await settingsService!.setThemeMode(ThemeMode.dark);
        }
        await settingsService!.setNavRailCollapsed(
          payload.settings!.isNavRailCollapsed,
        );
        if (payload.settings!.userDisplayName != null &&
            payload.settings!.userDisplayName!.isNotEmpty) {
          await settingsService!.setUserDisplayName(
            payload.settings!.userDisplayName!,
          );
        }
        if (payload.settings!.userProfilePicturePath != null) {
          await settingsService!.setUserProfilePicturePath(
            payload.settings!.userProfilePicturePath,
          );
        }
        settingsImported = true;
      }

      return BackupImportResult(
        success: true,
        moviesImported: moviesImported,
        moviesUpdated: moviesUpdated,
        showsImported: showsImported,
        showsUpdated: showsUpdated,
        seasonsImported: seasonsImported,
        episodesImported: episodesImported,
        episodesUpdated: episodesUpdated,
        collectionsImported: collectionsImported,
        collectionsUpdated: collectionsUpdated,
        settingsImported: settingsImported,
        warnings: warnings,
      );
    } catch (e) {
      return BackupImportResult(
        success: false,
        errorMessage: 'Import failed and was rolled back: $e',
        warnings: warnings,
      );
    }
  }

  /// Merges watch states with priority: WATCHED > IN_PROGRESS > UNWATCHED.
  static String _mergeWatchStates(String stateA, String stateB) {
    if (stateA == 'WATCHED' || stateB == 'WATCHED') return 'WATCHED';
    if (stateA == 'IN_PROGRESS' || stateB == 'IN_PROGRESS') {
      return 'IN_PROGRESS';
    }
    return 'UNWATCHED';
  }

  /// Merges playback position seconds.
  static int _mergePlaybackPosition(
    String stateA,
    int posA,
    String stateB,
    int posB,
  ) {
    final mergedState = _mergeWatchStates(stateA, stateB);
    if (mergedState == 'WATCHED') return 0;
    if (mergedState == 'UNWATCHED') return 0;
    return posA > posB ? posA : posB;
  }

  /// Merges lastPlayed timestamps, selecting the most recent.
  static DateTime? _mergeLastPlayed(DateTime? dateA, DateTime? dateB) {
    if (dateA == null) return dateB;
    if (dateB == null) return dateA;
    return dateA.isAfter(dateB) ? dateA : dateB;
  }
}
