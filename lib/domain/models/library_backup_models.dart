import 'dart:convert';

/// Supported export format versions.
const int kCurrentBackupFormatVersion = 1;

/// Supported application version.
const String kCurrentBackupAppVersion = '1.0.0';

/// Supported schema version (matching Drift database schema version).
const int kCurrentBackupSchemaVersion = 6;

/// Versioned, portable envelope containing exported REELHOUSE logical library data.
///
/// Pure logical representation: Contains zero physical filesystem paths, zero
/// MediaSource entries, zero credentials/API keys, and zero binary media bytes.
class LibraryBackupPayload {
  final int formatVersion;
  final String appVersion;
  final int schemaVersion;
  final DateTime exportedAt;
  final String application;
  final Map<String, dynamic>? metadata;

  final List<BackupMovie> movies;
  final List<BackupTvShow> tvShows;
  final List<BackupCollection> collections;
  final BackupSettings? settings;

  const LibraryBackupPayload({
    this.formatVersion = kCurrentBackupFormatVersion,
    this.appVersion = kCurrentBackupAppVersion,
    this.schemaVersion = kCurrentBackupSchemaVersion,
    required this.exportedAt,
    this.application = 'REELHOUSE',
    this.metadata,
    this.movies = const [],
    this.tvShows = const [],
    this.collections = const [],
    this.settings,
  });

  /// Computes a high-level summary of payload contents.
  BackupSummary toSummary() {
    var episodeCount = 0;
    var seasonCount = 0;
    for (final show in tvShows) {
      seasonCount += show.seasons.length;
      for (final season in show.seasons) {
        episodeCount += season.episodes.length;
      }
    }

    return BackupSummary(
      formatVersion: formatVersion,
      appVersion: appVersion,
      schemaVersion: schemaVersion,
      exportedAt: exportedAt,
      movieCount: movies.length,
      tvShowCount: tvShows.length,
      seasonCount: seasonCount,
      episodeCount: episodeCount,
      collectionCount: collections.length,
      hasSettings: settings != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formatVersion': formatVersion,
      'appVersion': appVersion,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'application': application,
      if (metadata != null) 'metadata': metadata,
      'summary': toSummary().toJson(),
      'library': {
        'movies': movies.map((m) => m.toJson()).toList(),
        'tvShows': tvShows.map((s) => s.toJson()).toList(),
        'collections': collections.map((c) => c.toJson()).toList(),
      },
      if (settings != null) 'settings': settings!.toJson(),
    };
  }

  factory LibraryBackupPayload.fromJson(Map<String, dynamic> json) {
    final formatVersion = json['formatVersion'] as int?;
    if (formatVersion == null) {
      throw const FormatException('Missing required field: formatVersion');
    }
    if (formatVersion > kCurrentBackupFormatVersion) {
      throw FormatException(
        'Unsupported backup format version: $formatVersion (maximum supported is $kCurrentBackupFormatVersion)',
      );
    }
    if (formatVersion < 1) {
      throw FormatException('Invalid backup format version: $formatVersion');
    }

    final exportedAtStr = json['exportedAt'] as String?;
    if (exportedAtStr == null) {
      throw const FormatException('Missing required field: exportedAt');
    }
    final exportedAt = DateTime.tryParse(exportedAtStr);
    if (exportedAt == null) {
      throw FormatException('Invalid exportedAt timestamp: $exportedAtStr');
    }

    final libraryMap = json['library'] as Map<String, dynamic>?;
    if (libraryMap == null) {
      throw const FormatException('Missing required section: library');
    }

    final moviesList = (libraryMap['movies'] as List<dynamic>? ?? [])
        .map((m) => BackupMovie.fromJson(m as Map<String, dynamic>))
        .toList();

    final tvShowsList = (libraryMap['tvShows'] as List<dynamic>? ?? [])
        .map((s) => BackupTvShow.fromJson(s as Map<String, dynamic>))
        .toList();

    final collectionsList = (libraryMap['collections'] as List<dynamic>? ?? [])
        .map((c) => BackupCollection.fromJson(c as Map<String, dynamic>))
        .toList();

    BackupSettings? settings;
    if (json['settings'] != null) {
      settings = BackupSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
      );
    }

    return LibraryBackupPayload(
      formatVersion: formatVersion,
      appVersion: json['appVersion'] as String? ?? 'unknown',
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      exportedAt: exportedAt,
      application: json['application'] as String? ?? 'REELHOUSE',
      metadata: json['metadata'] as Map<String, dynamic>?,
      movies: moviesList,
      tvShows: tvShowsList,
      collections: collectionsList,
      settings: settings,
    );
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Logical movie entity in export payload.
class BackupMovie {
  final String id;
  final String? metadataId;
  final String? title;
  final String? originalTitle;
  final int? year;
  final String detectedTitle;
  final int? detectedYear;
  final String identificationStatus;
  final String? overview;
  final int? runtime;
  final DateTime? releaseDate;
  final String? posterPath;
  final String? backdropPath;
  final double? rating;
  final int? voteCount;
  final String? imdbId;
  final int? tmdbId;
  final String? metadataProvider;
  final String? providerItemId;
  final DateTime? metadataUpdatedAt;
  final String? genres;
  final int? tmdbCollectionId;
  final String? tmdbCollectionName;
  final String? tmdbCollectionPosterPath;
  final String? tmdbCollectionBackdropPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isFavorite;
  final bool isWatchlist;
  final String watchState;
  final int playbackPositionSeconds;
  final DateTime? lastPlayedAt;

  const BackupMovie({
    required this.id,
    this.metadataId,
    this.title,
    this.originalTitle,
    this.year,
    required this.detectedTitle,
    this.detectedYear,
    this.identificationStatus = 'PENDING',
    this.overview,
    this.runtime,
    this.releaseDate,
    this.posterPath,
    this.backdropPath,
    this.rating,
    this.voteCount,
    this.imdbId,
    this.tmdbId,
    this.metadataProvider,
    this.providerItemId,
    this.metadataUpdatedAt,
    this.genres,
    this.tmdbCollectionId,
    this.tmdbCollectionName,
    this.tmdbCollectionPosterPath,
    this.tmdbCollectionBackdropPath,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.isWatchlist = false,
    this.watchState = 'UNWATCHED',
    this.playbackPositionSeconds = 0,
    this.lastPlayedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    if (metadataId != null) 'metadataId': metadataId,
    if (title != null) 'title': title,
    if (originalTitle != null) 'originalTitle': originalTitle,
    if (year != null) 'year': year,
    'detectedTitle': detectedTitle,
    if (detectedYear != null) 'detectedYear': detectedYear,
    'identificationStatus': identificationStatus,
    if (overview != null) 'overview': overview,
    if (runtime != null) 'runtime': runtime,
    if (releaseDate != null) 'releaseDate': releaseDate!.toIso8601String(),
    if (posterPath != null) 'posterPath': posterPath,
    if (backdropPath != null) 'backdropPath': backdropPath,
    if (rating != null) 'rating': rating,
    if (voteCount != null) 'voteCount': voteCount,
    if (imdbId != null) 'imdbId': imdbId,
    if (tmdbId != null) 'tmdbId': tmdbId,
    if (metadataProvider != null) 'metadataProvider': metadataProvider,
    if (providerItemId != null) 'providerItemId': providerItemId,
    if (metadataUpdatedAt != null)
      'metadataUpdatedAt': metadataUpdatedAt!.toIso8601String(),
    if (genres != null) 'genres': genres,
    if (tmdbCollectionId != null) 'tmdbCollectionId': tmdbCollectionId,
    if (tmdbCollectionName != null) 'tmdbCollectionName': tmdbCollectionName,
    if (tmdbCollectionPosterPath != null)
      'tmdbCollectionPosterPath': tmdbCollectionPosterPath,
    if (tmdbCollectionBackdropPath != null)
      'tmdbCollectionBackdropPath': tmdbCollectionBackdropPath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isFavorite': isFavorite,
    'isWatchlist': isWatchlist,
    'watchState': watchState,
    'playbackPositionSeconds': playbackPositionSeconds,
    if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt!.toIso8601String(),
  };

  factory BackupMovie.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final detectedTitle =
        json['detectedTitle'] as String? ?? json['title'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('Movie record missing id');
    }
    if (detectedTitle == null || detectedTitle.isEmpty) {
      throw const FormatException('Movie record missing detectedTitle/title');
    }

    return BackupMovie(
      id: id,
      metadataId: json['metadataId'] as String?,
      title: json['title'] as String?,
      originalTitle: json['originalTitle'] as String?,
      year: json['year'] as int?,
      detectedTitle: detectedTitle,
      detectedYear: json['detectedYear'] as int?,
      identificationStatus:
          json['identificationStatus'] as String? ?? 'PENDING',
      overview: json['overview'] as String?,
      runtime: json['runtime'] as int?,
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'] as String)
          : null,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      voteCount: json['voteCount'] as int?,
      imdbId: json['imdbId'] as String?,
      tmdbId: json['tmdbId'] as int?,
      metadataProvider: json['metadataProvider'] as String?,
      providerItemId: json['providerItemId'] as String?,
      metadataUpdatedAt: json['metadataUpdatedAt'] != null
          ? DateTime.tryParse(json['metadataUpdatedAt'] as String)
          : null,
      genres: json['genres'] as String?,
      tmdbCollectionId: json['tmdbCollectionId'] as int?,
      tmdbCollectionName: json['tmdbCollectionName'] as String?,
      tmdbCollectionPosterPath: json['tmdbCollectionPosterPath'] as String?,
      tmdbCollectionBackdropPath: json['tmdbCollectionBackdropPath'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isWatchlist: json['isWatchlist'] as bool? ?? false,
      watchState: json['watchState'] as String? ?? 'UNWATCHED',
      playbackPositionSeconds: json['playbackPositionSeconds'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt'] as String)
          : null,
    );
  }
}

/// Logical TV show entity in export payload.
class BackupTvShow {
  final String id;
  final String? metadataId;
  final String? title;
  final String? originalTitle;
  final String detectedTitle;
  final String identificationStatus;
  final String? overview;
  final DateTime? firstAirDate;
  final String? posterPath;
  final String? backdropPath;
  final double? rating;
  final int? tmdbId;
  final String? imdbId;
  final String? metadataProvider;
  final String? providerItemId;
  final DateTime? metadataUpdatedAt;
  final String? genres;
  final bool isFavorite;
  final bool isWatchlist;
  final DateTime createdAt;
  final DateTime updatedAt;

  final List<BackupSeason> seasons;

  const BackupTvShow({
    required this.id,
    this.metadataId,
    this.title,
    this.originalTitle,
    required this.detectedTitle,
    this.identificationStatus = 'PENDING',
    this.overview,
    this.firstAirDate,
    this.posterPath,
    this.backdropPath,
    this.rating,
    this.tmdbId,
    this.imdbId,
    this.metadataProvider,
    this.providerItemId,
    this.metadataUpdatedAt,
    this.genres,
    this.isFavorite = false,
    this.isWatchlist = false,
    required this.createdAt,
    required this.updatedAt,
    this.seasons = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    if (metadataId != null) 'metadataId': metadataId,
    if (title != null) 'title': title,
    if (originalTitle != null) 'originalTitle': originalTitle,
    'detectedTitle': detectedTitle,
    'identificationStatus': identificationStatus,
    if (overview != null) 'overview': overview,
    if (firstAirDate != null) 'firstAirDate': firstAirDate!.toIso8601String(),
    if (posterPath != null) 'posterPath': posterPath,
    if (backdropPath != null) 'backdropPath': backdropPath,
    if (rating != null) 'rating': rating,
    if (tmdbId != null) 'tmdbId': tmdbId,
    if (imdbId != null) 'imdbId': imdbId,
    if (metadataProvider != null) 'metadataProvider': metadataProvider,
    if (providerItemId != null) 'providerItemId': providerItemId,
    if (metadataUpdatedAt != null)
      'metadataUpdatedAt': metadataUpdatedAt!.toIso8601String(),
    if (genres != null) 'genres': genres,
    'isFavorite': isFavorite,
    'isWatchlist': isWatchlist,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'seasons': seasons.map((s) => s.toJson()).toList(),
  };

  factory BackupTvShow.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final detectedTitle =
        json['detectedTitle'] as String? ?? json['title'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('TV show record missing id');
    }
    if (detectedTitle == null || detectedTitle.isEmpty) {
      throw const FormatException('TV show record missing detectedTitle/title');
    }

    final seasonsList = (json['seasons'] as List<dynamic>? ?? [])
        .map((s) => BackupSeason.fromJson(s as Map<String, dynamic>))
        .toList();

    return BackupTvShow(
      id: id,
      metadataId: json['metadataId'] as String?,
      title: json['title'] as String?,
      originalTitle: json['originalTitle'] as String?,
      detectedTitle: detectedTitle,
      identificationStatus:
          json['identificationStatus'] as String? ?? 'PENDING',
      overview: json['overview'] as String?,
      firstAirDate: json['firstAirDate'] != null
          ? DateTime.tryParse(json['firstAirDate'] as String)
          : null,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      tmdbId: json['tmdbId'] as int?,
      imdbId: json['imdbId'] as String?,
      metadataProvider: json['metadataProvider'] as String?,
      providerItemId: json['providerItemId'] as String?,
      metadataUpdatedAt: json['metadataUpdatedAt'] != null
          ? DateTime.tryParse(json['metadataUpdatedAt'] as String)
          : null,
      genres: json['genres'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isWatchlist: json['isWatchlist'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      seasons: seasonsList,
    );
  }
}

/// Logical TV season entity in export payload.
class BackupSeason {
  final String id;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? posterPath;
  final DateTime? airDate;
  final int? tmdbId;
  final List<BackupEpisode> episodes;

  const BackupSeason({
    required this.id,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.posterPath,
    this.airDate,
    this.tmdbId,
    this.episodes = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'seasonNumber': seasonNumber,
    if (name != null) 'name': name,
    if (overview != null) 'overview': overview,
    if (posterPath != null) 'posterPath': posterPath,
    if (airDate != null) 'airDate': airDate!.toIso8601String(),
    if (tmdbId != null) 'tmdbId': tmdbId,
    'episodes': episodes.map((e) => e.toJson()).toList(),
  };

  factory BackupSeason.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final seasonNumber = json['seasonNumber'] as int?;
    if (id == null || id.isEmpty) {
      throw const FormatException('Season record missing id');
    }
    if (seasonNumber == null) {
      throw const FormatException('Season record missing seasonNumber');
    }

    final episodesList = (json['episodes'] as List<dynamic>? ?? [])
        .map((e) => BackupEpisode.fromJson(e as Map<String, dynamic>))
        .toList();

    return BackupSeason(
      id: id,
      seasonNumber: seasonNumber,
      name: json['name'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      airDate: json['airDate'] != null
          ? DateTime.tryParse(json['airDate'] as String)
          : null,
      tmdbId: json['tmdbId'] as int?,
      episodes: episodesList,
    );
  }
}

/// Logical TV episode entity in export payload.
class BackupEpisode {
  final String id;
  final int episodeNumber;
  final String? name;
  final String? overview;
  final DateTime? airDate;
  final int? runtime;
  final String? stillPath;
  final double? rating;
  final int? tmdbId;
  final String watchState;
  final int playbackPositionSeconds;
  final DateTime? lastPlayedAt;

  const BackupEpisode({
    required this.id,
    required this.episodeNumber,
    this.name,
    this.overview,
    this.airDate,
    this.runtime,
    this.stillPath,
    this.rating,
    this.tmdbId,
    this.watchState = 'UNWATCHED',
    this.playbackPositionSeconds = 0,
    this.lastPlayedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'episodeNumber': episodeNumber,
    if (name != null) 'name': name,
    if (overview != null) 'overview': overview,
    if (airDate != null) 'airDate': airDate!.toIso8601String(),
    if (runtime != null) 'runtime': runtime,
    if (stillPath != null) 'stillPath': stillPath,
    if (rating != null) 'rating': rating,
    if (tmdbId != null) 'tmdbId': tmdbId,
    'watchState': watchState,
    'playbackPositionSeconds': playbackPositionSeconds,
    if (lastPlayedAt != null) 'lastPlayedAt': lastPlayedAt!.toIso8601String(),
  };

  factory BackupEpisode.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final episodeNumber = json['episodeNumber'] as int?;
    if (id == null || id.isEmpty) {
      throw const FormatException('Episode record missing id');
    }
    if (episodeNumber == null) {
      throw const FormatException('Episode record missing episodeNumber');
    }

    return BackupEpisode(
      id: id,
      episodeNumber: episodeNumber,
      name: json['name'] as String?,
      overview: json['overview'] as String?,
      airDate: json['airDate'] != null
          ? DateTime.tryParse(json['airDate'] as String)
          : null,
      runtime: json['runtime'] as int?,
      stillPath: json['stillPath'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      tmdbId: json['tmdbId'] as int?,
      watchState: json['watchState'] as String? ?? 'UNWATCHED',
      playbackPositionSeconds: json['playbackPositionSeconds'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt'] as String)
          : null,
    );
  }
}

/// Curated collection in export payload.
class BackupCollection {
  final String id;
  final String name;
  final String? overview;
  final String? posterPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BackupCollectionItem> items;

  const BackupCollection({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (overview != null) 'overview': overview,
    if (posterPath != null) 'posterPath': posterPath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory BackupCollection.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('Collection record missing id');
    }
    if (name == null || name.isEmpty) {
      throw const FormatException('Collection record missing name');
    }

    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((i) => BackupCollectionItem.fromJson(i as Map<String, dynamic>))
        .toList();

    return BackupCollection(
      id: id,
      name: name,
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: itemsList,
    );
  }
}

/// Association between a collection and a logical movie or TV show.
class BackupCollectionItem {
  final String id;
  final String? movieId;
  final String? tvShowId;
  final int displayOrder;
  final DateTime addedAt;

  const BackupCollectionItem({
    required this.id,
    this.movieId,
    this.tvShowId,
    this.displayOrder = 0,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    if (movieId != null) 'movieId': movieId,
    if (tvShowId != null) 'tvShowId': tvShowId,
    'displayOrder': displayOrder,
    'addedAt': addedAt.toIso8601String(),
  };

  factory BackupCollectionItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('CollectionItem missing id');
    }

    return BackupCollectionItem(
      id: id,
      movieId: json['movieId'] as String?,
      tvShowId: json['tvShowId'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Non-sensitive user settings in export payload.
///
/// MUST NEVER CONTAIN API keys, tokens, or private credentials!
class BackupSettings {
  final String preferredPlayer;
  final String themeMode;
  final bool isNavRailCollapsed;
  final String? userDisplayName;
  final String? userProfilePicturePath;

  const BackupSettings({
    this.preferredPlayer = 'vlc',
    this.themeMode = 'dark',
    this.isNavRailCollapsed = false,
    this.userDisplayName,
    this.userProfilePicturePath,
  });

  Map<String, dynamic> toJson() => {
    'preferredPlayer': preferredPlayer,
    'themeMode': themeMode,
    'isNavRailCollapsed': isNavRailCollapsed,
    if (userDisplayName != null) 'userDisplayName': userDisplayName,
    if (userProfilePicturePath != null)
      'userProfilePicturePath': userProfilePicturePath,
  };

  factory BackupSettings.fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      preferredPlayer: json['preferredPlayer'] as String? ?? 'vlc',
      themeMode: json['themeMode'] as String? ?? 'dark',
      isNavRailCollapsed: json['isNavRailCollapsed'] as bool? ?? false,
      userDisplayName: json['userDisplayName'] as String?,
      userProfilePicturePath: json['userProfilePicturePath'] as String?,
    );
  }
}

/// High-level summary of an export payload for display/inspection prior to import.
class BackupSummary {
  final int formatVersion;
  final String appVersion;
  final int schemaVersion;
  final DateTime exportedAt;
  final int movieCount;
  final int tvShowCount;
  final int seasonCount;
  final int episodeCount;
  final int collectionCount;
  final bool hasSettings;

  const BackupSummary({
    required this.formatVersion,
    required this.appVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.movieCount,
    required this.tvShowCount,
    required this.seasonCount,
    required this.episodeCount,
    required this.collectionCount,
    required this.hasSettings,
  });

  Map<String, dynamic> toJson() => {
    'formatVersion': formatVersion,
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'movieCount': movieCount,
    'tvShowCount': tvShowCount,
    'seasonCount': seasonCount,
    'episodeCount': episodeCount,
    'collectionCount': collectionCount,
    'hasSettings': hasSettings,
  };

  factory BackupSummary.fromJson(Map<String, dynamic> json) {
    return BackupSummary(
      formatVersion: json['formatVersion'] as int? ?? 1,
      appVersion: json['appVersion'] as String? ?? 'unknown',
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      exportedAt: json['exportedAt'] != null
          ? DateTime.tryParse(json['exportedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      movieCount: json['movieCount'] as int? ?? 0,
      tvShowCount: json['tvShowCount'] as int? ?? 0,
      seasonCount: json['seasonCount'] as int? ?? 0,
      episodeCount: json['episodeCount'] as int? ?? 0,
      collectionCount: json['collectionCount'] as int? ?? 0,
      hasSettings: json['hasSettings'] as bool? ?? false,
    );
  }
}

/// Result returned after importing a backup payload into the database.
class BackupImportResult {
  final bool success;
  final int moviesImported;
  final int moviesUpdated;
  final int showsImported;
  final int showsUpdated;
  final int seasonsImported;
  final int episodesImported;
  final int episodesUpdated;
  final int collectionsImported;
  final int collectionsUpdated;
  final bool settingsImported;
  final List<String> warnings;
  final String? errorMessage;

  const BackupImportResult({
    required this.success,
    this.moviesImported = 0,
    this.moviesUpdated = 0,
    this.showsImported = 0,
    this.showsUpdated = 0,
    this.seasonsImported = 0,
    this.episodesImported = 0,
    this.episodesUpdated = 0,
    this.collectionsImported = 0,
    this.collectionsUpdated = 0,
    this.settingsImported = false,
    this.warnings = const [],
    this.errorMessage,
  });

  int get totalItemsRestored =>
      moviesImported +
      moviesUpdated +
      showsImported +
      showsUpdated +
      episodesImported +
      episodesUpdated +
      collectionsImported;
}
