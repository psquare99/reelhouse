import 'package:drift/drift.dart';

/// Registered storage locations (removable disks, local device storage, network shares).
class Storages extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get storageType =>
      text()(); // REMOVABLE_VOLUME | DEVICE_LOCAL_STORAGE | NETWORK_SHARE
  TextColumn get filesystemIdentifier => text()(); // Win32 Volume Serial / Android Volume UUID / "internal-app-storage"
  TextColumn get rootUri =>
      text()(); // Windows path or Android DocumentTree content URI
  DateTimeColumn get lastSeenAt => dateTime()();
  BoolColumn get available => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Logical movie entities in the cinema catalogue.
@DataClassName('Movie')
class Movies extends Table {
  TextColumn get id => text()();
  TextColumn get metadataId => text().nullable()();
  TextColumn get title => text().nullable()(); // Canonical/provider title
  TextColumn get originalTitle => text().nullable()();
  IntColumn get year => integer().nullable()(); // Canonical/provider year
  TextColumn get detectedTitle => text()(); // Discovered filesystem title
  IntColumn get detectedYear =>
      integer().nullable()(); // Discovered filesystem year
  TextColumn get identificationStatus => text().withDefault(
    const Constant('PENDING'),
  )(); // PENDING, IDENTIFIED, NEEDS_VERIFICATION
  TextColumn get overview => text().nullable()();
  IntColumn get runtime => integer().nullable()();
  DateTimeColumn get releaseDate => dateTime().nullable()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get backdropPath => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get voteCount => integer().nullable()();
  TextColumn get imdbId => text().nullable()();
  IntColumn get tmdbId => integer().nullable()();
  TextColumn get metadataProvider =>
      text().nullable()(); // 'TMDB' | 'OMDb' | 'TVmaze'
  TextColumn get providerItemId => text().nullable()();
  DateTimeColumn get metadataUpdatedAt => dateTime().nullable()();
  TextColumn get genres =>
      text().nullable()(); // Comma-separated canonical genres
  IntColumn get tmdbCollectionId => integer().nullable()();
  TextColumn get tmdbCollectionName => text().nullable()();
  TextColumn get tmdbCollectionPosterPath => text().nullable()();
  TextColumn get tmdbCollectionBackdropPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isWatchlist => boolean().withDefault(const Constant(false))();
  TextColumn get watchState => text().withDefault(
    const Constant('UNWATCHED'),
  )(); // UNWATCHED, IN_PROGRESS, WATCHED
  IntColumn get playbackPositionSeconds =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Logical TV show entities in the cinema catalogue.
class TvShows extends Table {
  TextColumn get id => text()();
  TextColumn get metadataId => text().nullable()();
  TextColumn get title => text().nullable()(); // Canonical/provider title
  TextColumn get originalTitle => text().nullable()();
  TextColumn get detectedTitle => text()(); // Discovered filesystem title
  TextColumn get identificationStatus => text().withDefault(
    const Constant('PENDING'),
  )(); // PENDING, IDENTIFIED, NEEDS_VERIFICATION
  TextColumn get overview => text().nullable()();
  DateTimeColumn get firstAirDate => dateTime().nullable()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get backdropPath => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get tmdbId => integer().nullable()();
  TextColumn get imdbId => text().nullable()();
  TextColumn get metadataProvider => text().nullable()(); // 'TMDB' | 'TVmaze'
  TextColumn get providerItemId => text().nullable()();
  DateTimeColumn get metadataUpdatedAt => dateTime().nullable()();
  TextColumn get genres =>
      text().nullable()(); // Comma-separated canonical genres
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isWatchlist => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// TV seasons belonging to a TV show.
class Seasons extends Table {
  TextColumn get id => text()();
  TextColumn get showId => text().references(TvShows, #id)();
  IntColumn get seasonNumber => integer()();
  TextColumn get name => text().nullable()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterPath => text().nullable()();
  DateTimeColumn get airDate => dateTime().nullable()();
  IntColumn get tmdbId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Individual TV episodes.
class Episodes extends Table {
  TextColumn get id => text()();
  TextColumn get seasonId => text().references(Seasons, #id)();
  IntColumn get episodeNumber => integer()();
  TextColumn get name => text().nullable()();
  TextColumn get overview => text().nullable()();
  DateTimeColumn get airDate => dateTime().nullable()();
  IntColumn get runtime => integer().nullable()();
  TextColumn get stillPath => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get tmdbId => integer().nullable()();
  TextColumn get watchState => text().withDefault(
    const Constant('UNWATCHED'),
  )(); // UNWATCHED, IN_PROGRESS, WATCHED
  IntColumn get playbackPositionSeconds =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Curated collections grouping related films, franchises, or custom lists.
class Collections extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Association between collections and logical media items.
class CollectionItems extends Table {
  TextColumn get id => text()();
  TextColumn get collectionId => text().references(Collections, #id)();
  TextColumn get movieId => text().nullable().references(Movies, #id)();
  TextColumn get tvShowId => text().nullable().references(TvShows, #id)();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Physical media files belonging to a movie or episode.
///
/// A single logical movie or episode can have multiple concurrent physical copies
/// across different storage devices (e.g. original HDD + local offline copy).
class MediaSources extends Table {
  TextColumn get id => text()();
  TextColumn get movieId => text().nullable().references(Movies, #id)();
  TextColumn get episodeId => text().nullable().references(Episodes, #id)();
  TextColumn get storageId => text().references(Storages, #id)();
  TextColumn get sourceType => text()(); // 'removableStorage' | 'localDevice'
  TextColumn get relativePath => text()();
  TextColumn get filename => text()();
  TextColumn get extension => text()();
  Int64Column get fileSize => int64()();
  IntColumn get duration => integer().nullable()();
  TextColumn get videoCodec => text().nullable()();
  TextColumn get audioCodec => text().nullable()();
  TextColumn get resolution => text().nullable()();
  TextColumn get audioChannels => text().nullable()();
  TextColumn get subtitleInformation => text().nullable()();
  TextColumn get fingerprint => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();
  BoolColumn get available => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Transient offline transfer operations.
///
/// Separated from [MediaSources]. Only when a [TransferJobs] record transitions
/// to COMPLETED is a corresponding local [MediaSources] record inserted.
class TransferJobs extends Table {
  TextColumn get id => text()();
  TextColumn get mediaType => text()(); // 'movie' | 'episode'
  TextColumn get mediaId => text()(); // movieId or episodeId
  TextColumn get sourceMediaSourceId => text().references(MediaSources, #id)();
  TextColumn get destinationStorageId => text().references(Storages, #id)();
  TextColumn get destinationRelativePath => text()();
  TextColumn get status =>
      text()(); // QUEUED, DOWNLOADING, PAUSED, COMPLETED, FAILED, CANCELLED
  Int64Column get bytesTransferred =>
      int64().withDefault(Constant(BigInt.zero))();
  Int64Column get totalBytes => int64()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
