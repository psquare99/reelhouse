// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $StoragesTable extends Storages with TableInfo<$StoragesTable, Storage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoragesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageTypeMeta = const VerificationMeta(
    'storageType',
  );
  @override
  late final GeneratedColumn<String> storageType = GeneratedColumn<String>(
    'storage_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filesystemIdentifierMeta =
      const VerificationMeta('filesystemIdentifier');
  @override
  late final GeneratedColumn<String> filesystemIdentifier =
      GeneratedColumn<String>(
        'filesystem_identifier',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _rootUriMeta = const VerificationMeta(
    'rootUri',
  );
  @override
  late final GeneratedColumn<String> rootUri = GeneratedColumn<String>(
    'root_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availableMeta = const VerificationMeta(
    'available',
  );
  @override
  late final GeneratedColumn<bool> available = GeneratedColumn<bool>(
    'available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    storageType,
    filesystemIdentifier,
    rootUri,
    lastSeenAt,
    available,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Storage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('storage_type')) {
      context.handle(
        _storageTypeMeta,
        storageType.isAcceptableOrUnknown(
          data['storage_type']!,
          _storageTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storageTypeMeta);
    }
    if (data.containsKey('filesystem_identifier')) {
      context.handle(
        _filesystemIdentifierMeta,
        filesystemIdentifier.isAcceptableOrUnknown(
          data['filesystem_identifier']!,
          _filesystemIdentifierMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_filesystemIdentifierMeta);
    }
    if (data.containsKey('root_uri')) {
      context.handle(
        _rootUriMeta,
        rootUri.isAcceptableOrUnknown(data['root_uri']!, _rootUriMeta),
      );
    } else if (isInserting) {
      context.missing(_rootUriMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('available')) {
      context.handle(
        _availableMeta,
        available.isAcceptableOrUnknown(data['available']!, _availableMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Storage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Storage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      storageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_type'],
      )!,
      filesystemIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filesystem_identifier'],
      )!,
      rootUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_uri'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
      available: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}available'],
      )!,
    );
  }

  @override
  $StoragesTable createAlias(String alias) {
    return $StoragesTable(attachedDatabase, alias);
  }
}

class Storage extends DataClass implements Insertable<Storage> {
  final String id;
  final String name;
  final String storageType;
  final String filesystemIdentifier;
  final String rootUri;
  final DateTime lastSeenAt;
  final bool available;
  const Storage({
    required this.id,
    required this.name,
    required this.storageType,
    required this.filesystemIdentifier,
    required this.rootUri,
    required this.lastSeenAt,
    required this.available,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['storage_type'] = Variable<String>(storageType);
    map['filesystem_identifier'] = Variable<String>(filesystemIdentifier);
    map['root_uri'] = Variable<String>(rootUri);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    map['available'] = Variable<bool>(available);
    return map;
  }

  StoragesCompanion toCompanion(bool nullToAbsent) {
    return StoragesCompanion(
      id: Value(id),
      name: Value(name),
      storageType: Value(storageType),
      filesystemIdentifier: Value(filesystemIdentifier),
      rootUri: Value(rootUri),
      lastSeenAt: Value(lastSeenAt),
      available: Value(available),
    );
  }

  factory Storage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Storage(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      storageType: serializer.fromJson<String>(json['storageType']),
      filesystemIdentifier: serializer.fromJson<String>(
        json['filesystemIdentifier'],
      ),
      rootUri: serializer.fromJson<String>(json['rootUri']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      available: serializer.fromJson<bool>(json['available']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'storageType': serializer.toJson<String>(storageType),
      'filesystemIdentifier': serializer.toJson<String>(filesystemIdentifier),
      'rootUri': serializer.toJson<String>(rootUri),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'available': serializer.toJson<bool>(available),
    };
  }

  Storage copyWith({
    String? id,
    String? name,
    String? storageType,
    String? filesystemIdentifier,
    String? rootUri,
    DateTime? lastSeenAt,
    bool? available,
  }) => Storage(
    id: id ?? this.id,
    name: name ?? this.name,
    storageType: storageType ?? this.storageType,
    filesystemIdentifier: filesystemIdentifier ?? this.filesystemIdentifier,
    rootUri: rootUri ?? this.rootUri,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    available: available ?? this.available,
  );
  Storage copyWithCompanion(StoragesCompanion data) {
    return Storage(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      storageType: data.storageType.present
          ? data.storageType.value
          : this.storageType,
      filesystemIdentifier: data.filesystemIdentifier.present
          ? data.filesystemIdentifier.value
          : this.filesystemIdentifier,
      rootUri: data.rootUri.present ? data.rootUri.value : this.rootUri,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      available: data.available.present ? data.available.value : this.available,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Storage(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('storageType: $storageType, ')
          ..write('filesystemIdentifier: $filesystemIdentifier, ')
          ..write('rootUri: $rootUri, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('available: $available')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    storageType,
    filesystemIdentifier,
    rootUri,
    lastSeenAt,
    available,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Storage &&
          other.id == this.id &&
          other.name == this.name &&
          other.storageType == this.storageType &&
          other.filesystemIdentifier == this.filesystemIdentifier &&
          other.rootUri == this.rootUri &&
          other.lastSeenAt == this.lastSeenAt &&
          other.available == this.available);
}

class StoragesCompanion extends UpdateCompanion<Storage> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> storageType;
  final Value<String> filesystemIdentifier;
  final Value<String> rootUri;
  final Value<DateTime> lastSeenAt;
  final Value<bool> available;
  final Value<int> rowid;
  const StoragesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.storageType = const Value.absent(),
    this.filesystemIdentifier = const Value.absent(),
    this.rootUri = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.available = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoragesCompanion.insert({
    required String id,
    required String name,
    required String storageType,
    required String filesystemIdentifier,
    required String rootUri,
    required DateTime lastSeenAt,
    this.available = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       storageType = Value(storageType),
       filesystemIdentifier = Value(filesystemIdentifier),
       rootUri = Value(rootUri),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<Storage> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? storageType,
    Expression<String>? filesystemIdentifier,
    Expression<String>? rootUri,
    Expression<DateTime>? lastSeenAt,
    Expression<bool>? available,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (storageType != null) 'storage_type': storageType,
      if (filesystemIdentifier != null)
        'filesystem_identifier': filesystemIdentifier,
      if (rootUri != null) 'root_uri': rootUri,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (available != null) 'available': available,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoragesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? storageType,
    Value<String>? filesystemIdentifier,
    Value<String>? rootUri,
    Value<DateTime>? lastSeenAt,
    Value<bool>? available,
    Value<int>? rowid,
  }) {
    return StoragesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      storageType: storageType ?? this.storageType,
      filesystemIdentifier: filesystemIdentifier ?? this.filesystemIdentifier,
      rootUri: rootUri ?? this.rootUri,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      available: available ?? this.available,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (storageType.present) {
      map['storage_type'] = Variable<String>(storageType.value);
    }
    if (filesystemIdentifier.present) {
      map['filesystem_identifier'] = Variable<String>(
        filesystemIdentifier.value,
      );
    }
    if (rootUri.present) {
      map['root_uri'] = Variable<String>(rootUri.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (available.present) {
      map['available'] = Variable<bool>(available.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoragesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('storageType: $storageType, ')
          ..write('filesystemIdentifier: $filesystemIdentifier, ')
          ..write('rootUri: $rootUri, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('available: $available, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MoviesTable extends Movies with TableInfo<$MoviesTable, Movie> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataIdMeta = const VerificationMeta(
    'metadataId',
  );
  @override
  late final GeneratedColumn<String> metadataId = GeneratedColumn<String>(
    'metadata_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta(
    'originalTitle',
  );
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runtimeMeta = const VerificationMeta(
    'runtime',
  );
  @override
  late final GeneratedColumn<int> runtime = GeneratedColumn<int>(
    'runtime',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> releaseDate = GeneratedColumn<DateTime>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropPathMeta = const VerificationMeta(
    'backdropPath',
  );
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
    'backdrop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voteCountMeta = const VerificationMeta(
    'voteCount',
  );
  @override
  late final GeneratedColumn<int> voteCount = GeneratedColumn<int>(
    'vote_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imdbIdMeta = const VerificationMeta('imdbId');
  @override
  late final GeneratedColumn<String> imdbId = GeneratedColumn<String>(
    'imdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isWatchlistMeta = const VerificationMeta(
    'isWatchlist',
  );
  @override
  late final GeneratedColumn<bool> isWatchlist = GeneratedColumn<bool>(
    'is_watchlist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_watchlist" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _watchStateMeta = const VerificationMeta(
    'watchState',
  );
  @override
  late final GeneratedColumn<String> watchState = GeneratedColumn<String>(
    'watch_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UNWATCHED'),
  );
  static const VerificationMeta _playbackPositionSecondsMeta =
      const VerificationMeta('playbackPositionSeconds');
  @override
  late final GeneratedColumn<int> playbackPositionSeconds =
      GeneratedColumn<int>(
        'playback_position_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    metadataId,
    title,
    originalTitle,
    year,
    overview,
    runtime,
    releaseDate,
    posterPath,
    backdropPath,
    rating,
    voteCount,
    imdbId,
    tmdbId,
    createdAt,
    updatedAt,
    isFavorite,
    isWatchlist,
    watchState,
    playbackPositionSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movie> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('metadata_id')) {
      context.handle(
        _metadataIdMeta,
        metadataId.isAcceptableOrUnknown(data['metadata_id']!, _metadataIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(
          data['original_title']!,
          _originalTitleMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('runtime')) {
      context.handle(
        _runtimeMeta,
        runtime.isAcceptableOrUnknown(data['runtime']!, _runtimeMeta),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
        _backdropPathMeta,
        backdropPath.isAcceptableOrUnknown(
          data['backdrop_path']!,
          _backdropPathMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('vote_count')) {
      context.handle(
        _voteCountMeta,
        voteCount.isAcceptableOrUnknown(data['vote_count']!, _voteCountMeta),
      );
    }
    if (data.containsKey('imdb_id')) {
      context.handle(
        _imdbIdMeta,
        imdbId.isAcceptableOrUnknown(data['imdb_id']!, _imdbIdMeta),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_watchlist')) {
      context.handle(
        _isWatchlistMeta,
        isWatchlist.isAcceptableOrUnknown(
          data['is_watchlist']!,
          _isWatchlistMeta,
        ),
      );
    }
    if (data.containsKey('watch_state')) {
      context.handle(
        _watchStateMeta,
        watchState.isAcceptableOrUnknown(data['watch_state']!, _watchStateMeta),
      );
    }
    if (data.containsKey('playback_position_seconds')) {
      context.handle(
        _playbackPositionSecondsMeta,
        playbackPositionSeconds.isAcceptableOrUnknown(
          data['playback_position_seconds']!,
          _playbackPositionSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Movie map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movie(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      metadataId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_title'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      runtime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}release_date'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      backdropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_path'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      voteCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vote_count'],
      ),
      imdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imdb_id'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isWatchlist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_watchlist'],
      )!,
      watchState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}watch_state'],
      )!,
      playbackPositionSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playback_position_seconds'],
      )!,
    );
  }

  @override
  $MoviesTable createAlias(String alias) {
    return $MoviesTable(attachedDatabase, alias);
  }
}

class Movie extends DataClass implements Insertable<Movie> {
  final String id;
  final String? metadataId;
  final String title;
  final String? originalTitle;
  final int? year;
  final String? overview;
  final int? runtime;
  final DateTime? releaseDate;
  final String? posterPath;
  final String? backdropPath;
  final double? rating;
  final int? voteCount;
  final String? imdbId;
  final int? tmdbId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final bool isWatchlist;
  final String watchState;
  final int playbackPositionSeconds;
  const Movie({
    required this.id,
    this.metadataId,
    required this.title,
    this.originalTitle,
    this.year,
    this.overview,
    this.runtime,
    this.releaseDate,
    this.posterPath,
    this.backdropPath,
    this.rating,
    this.voteCount,
    this.imdbId,
    this.tmdbId,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
    required this.isWatchlist,
    required this.watchState,
    required this.playbackPositionSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || metadataId != null) {
      map['metadata_id'] = Variable<String>(metadataId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || originalTitle != null) {
      map['original_title'] = Variable<String>(originalTitle);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || runtime != null) {
      map['runtime'] = Variable<int>(runtime);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<DateTime>(releaseDate);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || voteCount != null) {
      map['vote_count'] = Variable<int>(voteCount);
    }
    if (!nullToAbsent || imdbId != null) {
      map['imdb_id'] = Variable<String>(imdbId);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_watchlist'] = Variable<bool>(isWatchlist);
    map['watch_state'] = Variable<String>(watchState);
    map['playback_position_seconds'] = Variable<int>(playbackPositionSeconds);
    return map;
  }

  MoviesCompanion toCompanion(bool nullToAbsent) {
    return MoviesCompanion(
      id: Value(id),
      metadataId: metadataId == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataId),
      title: Value(title),
      originalTitle: originalTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTitle),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      runtime: runtime == null && nullToAbsent
          ? const Value.absent()
          : Value(runtime),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      voteCount: voteCount == null && nullToAbsent
          ? const Value.absent()
          : Value(voteCount),
      imdbId: imdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(imdbId),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isFavorite: Value(isFavorite),
      isWatchlist: Value(isWatchlist),
      watchState: Value(watchState),
      playbackPositionSeconds: Value(playbackPositionSeconds),
    );
  }

  factory Movie.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movie(
      id: serializer.fromJson<String>(json['id']),
      metadataId: serializer.fromJson<String?>(json['metadataId']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String?>(json['originalTitle']),
      year: serializer.fromJson<int?>(json['year']),
      overview: serializer.fromJson<String?>(json['overview']),
      runtime: serializer.fromJson<int?>(json['runtime']),
      releaseDate: serializer.fromJson<DateTime?>(json['releaseDate']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
      rating: serializer.fromJson<double?>(json['rating']),
      voteCount: serializer.fromJson<int?>(json['voteCount']),
      imdbId: serializer.fromJson<String?>(json['imdbId']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isWatchlist: serializer.fromJson<bool>(json['isWatchlist']),
      watchState: serializer.fromJson<String>(json['watchState']),
      playbackPositionSeconds: serializer.fromJson<int>(
        json['playbackPositionSeconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'metadataId': serializer.toJson<String?>(metadataId),
      'title': serializer.toJson<String>(title),
      'originalTitle': serializer.toJson<String?>(originalTitle),
      'year': serializer.toJson<int?>(year),
      'overview': serializer.toJson<String?>(overview),
      'runtime': serializer.toJson<int?>(runtime),
      'releaseDate': serializer.toJson<DateTime?>(releaseDate),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
      'rating': serializer.toJson<double?>(rating),
      'voteCount': serializer.toJson<int?>(voteCount),
      'imdbId': serializer.toJson<String?>(imdbId),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isWatchlist': serializer.toJson<bool>(isWatchlist),
      'watchState': serializer.toJson<String>(watchState),
      'playbackPositionSeconds': serializer.toJson<int>(
        playbackPositionSeconds,
      ),
    };
  }

  Movie copyWith({
    String? id,
    Value<String?> metadataId = const Value.absent(),
    String? title,
    Value<String?> originalTitle = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<int?> runtime = const Value.absent(),
    Value<DateTime?> releaseDate = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    Value<String?> backdropPath = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<int?> voteCount = const Value.absent(),
    Value<String?> imdbId = const Value.absent(),
    Value<int?> tmdbId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isWatchlist,
    String? watchState,
    int? playbackPositionSeconds,
  }) => Movie(
    id: id ?? this.id,
    metadataId: metadataId.present ? metadataId.value : this.metadataId,
    title: title ?? this.title,
    originalTitle: originalTitle.present
        ? originalTitle.value
        : this.originalTitle,
    year: year.present ? year.value : this.year,
    overview: overview.present ? overview.value : this.overview,
    runtime: runtime.present ? runtime.value : this.runtime,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    backdropPath: backdropPath.present ? backdropPath.value : this.backdropPath,
    rating: rating.present ? rating.value : this.rating,
    voteCount: voteCount.present ? voteCount.value : this.voteCount,
    imdbId: imdbId.present ? imdbId.value : this.imdbId,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    isWatchlist: isWatchlist ?? this.isWatchlist,
    watchState: watchState ?? this.watchState,
    playbackPositionSeconds:
        playbackPositionSeconds ?? this.playbackPositionSeconds,
  );
  Movie copyWithCompanion(MoviesCompanion data) {
    return Movie(
      id: data.id.present ? data.id.value : this.id,
      metadataId: data.metadataId.present
          ? data.metadataId.value
          : this.metadataId,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      year: data.year.present ? data.year.value : this.year,
      overview: data.overview.present ? data.overview.value : this.overview,
      runtime: data.runtime.present ? data.runtime.value : this.runtime,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
      rating: data.rating.present ? data.rating.value : this.rating,
      voteCount: data.voteCount.present ? data.voteCount.value : this.voteCount,
      imdbId: data.imdbId.present ? data.imdbId.value : this.imdbId,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isWatchlist: data.isWatchlist.present
          ? data.isWatchlist.value
          : this.isWatchlist,
      watchState: data.watchState.present
          ? data.watchState.value
          : this.watchState,
      playbackPositionSeconds: data.playbackPositionSeconds.present
          ? data.playbackPositionSeconds.value
          : this.playbackPositionSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movie(')
          ..write('id: $id, ')
          ..write('metadataId: $metadataId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('year: $year, ')
          ..write('overview: $overview, ')
          ..write('runtime: $runtime, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('rating: $rating, ')
          ..write('voteCount: $voteCount, ')
          ..write('imdbId: $imdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isWatchlist: $isWatchlist, ')
          ..write('watchState: $watchState, ')
          ..write('playbackPositionSeconds: $playbackPositionSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    metadataId,
    title,
    originalTitle,
    year,
    overview,
    runtime,
    releaseDate,
    posterPath,
    backdropPath,
    rating,
    voteCount,
    imdbId,
    tmdbId,
    createdAt,
    updatedAt,
    isFavorite,
    isWatchlist,
    watchState,
    playbackPositionSeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movie &&
          other.id == this.id &&
          other.metadataId == this.metadataId &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.year == this.year &&
          other.overview == this.overview &&
          other.runtime == this.runtime &&
          other.releaseDate == this.releaseDate &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath &&
          other.rating == this.rating &&
          other.voteCount == this.voteCount &&
          other.imdbId == this.imdbId &&
          other.tmdbId == this.tmdbId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isFavorite == this.isFavorite &&
          other.isWatchlist == this.isWatchlist &&
          other.watchState == this.watchState &&
          other.playbackPositionSeconds == this.playbackPositionSeconds);
}

class MoviesCompanion extends UpdateCompanion<Movie> {
  final Value<String> id;
  final Value<String?> metadataId;
  final Value<String> title;
  final Value<String?> originalTitle;
  final Value<int?> year;
  final Value<String?> overview;
  final Value<int?> runtime;
  final Value<DateTime?> releaseDate;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<double?> rating;
  final Value<int?> voteCount;
  final Value<String?> imdbId;
  final Value<int?> tmdbId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isFavorite;
  final Value<bool> isWatchlist;
  final Value<String> watchState;
  final Value<int> playbackPositionSeconds;
  final Value<int> rowid;
  const MoviesCompanion({
    this.id = const Value.absent(),
    this.metadataId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.year = const Value.absent(),
    this.overview = const Value.absent(),
    this.runtime = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.rating = const Value.absent(),
    this.voteCount = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isWatchlist = const Value.absent(),
    this.watchState = const Value.absent(),
    this.playbackPositionSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoviesCompanion.insert({
    required String id,
    this.metadataId = const Value.absent(),
    required String title,
    this.originalTitle = const Value.absent(),
    this.year = const Value.absent(),
    this.overview = const Value.absent(),
    this.runtime = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.rating = const Value.absent(),
    this.voteCount = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isFavorite = const Value.absent(),
    this.isWatchlist = const Value.absent(),
    this.watchState = const Value.absent(),
    this.playbackPositionSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Movie> custom({
    Expression<String>? id,
    Expression<String>? metadataId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<int>? year,
    Expression<String>? overview,
    Expression<int>? runtime,
    Expression<DateTime>? releaseDate,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<double>? rating,
    Expression<int>? voteCount,
    Expression<String>? imdbId,
    Expression<int>? tmdbId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isFavorite,
    Expression<bool>? isWatchlist,
    Expression<String>? watchState,
    Expression<int>? playbackPositionSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (metadataId != null) 'metadata_id': metadataId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (year != null) 'year': year,
      if (overview != null) 'overview': overview,
      if (runtime != null) 'runtime': runtime,
      if (releaseDate != null) 'release_date': releaseDate,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (rating != null) 'rating': rating,
      if (voteCount != null) 'vote_count': voteCount,
      if (imdbId != null) 'imdb_id': imdbId,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isWatchlist != null) 'is_watchlist': isWatchlist,
      if (watchState != null) 'watch_state': watchState,
      if (playbackPositionSeconds != null)
        'playback_position_seconds': playbackPositionSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoviesCompanion copyWith({
    Value<String>? id,
    Value<String?>? metadataId,
    Value<String>? title,
    Value<String?>? originalTitle,
    Value<int?>? year,
    Value<String?>? overview,
    Value<int?>? runtime,
    Value<DateTime?>? releaseDate,
    Value<String?>? posterPath,
    Value<String?>? backdropPath,
    Value<double?>? rating,
    Value<int?>? voteCount,
    Value<String?>? imdbId,
    Value<int?>? tmdbId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isFavorite,
    Value<bool>? isWatchlist,
    Value<String>? watchState,
    Value<int>? playbackPositionSeconds,
    Value<int>? rowid,
  }) {
    return MoviesCompanion(
      id: id ?? this.id,
      metadataId: metadataId ?? this.metadataId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      year: year ?? this.year,
      overview: overview ?? this.overview,
      runtime: runtime ?? this.runtime,
      releaseDate: releaseDate ?? this.releaseDate,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      rating: rating ?? this.rating,
      voteCount: voteCount ?? this.voteCount,
      imdbId: imdbId ?? this.imdbId,
      tmdbId: tmdbId ?? this.tmdbId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isWatchlist: isWatchlist ?? this.isWatchlist,
      watchState: watchState ?? this.watchState,
      playbackPositionSeconds:
          playbackPositionSeconds ?? this.playbackPositionSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (metadataId.present) {
      map['metadata_id'] = Variable<String>(metadataId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (runtime.present) {
      map['runtime'] = Variable<int>(runtime.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<DateTime>(releaseDate.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (voteCount.present) {
      map['vote_count'] = Variable<int>(voteCount.value);
    }
    if (imdbId.present) {
      map['imdb_id'] = Variable<String>(imdbId.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isWatchlist.present) {
      map['is_watchlist'] = Variable<bool>(isWatchlist.value);
    }
    if (watchState.present) {
      map['watch_state'] = Variable<String>(watchState.value);
    }
    if (playbackPositionSeconds.present) {
      map['playback_position_seconds'] = Variable<int>(
        playbackPositionSeconds.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoviesCompanion(')
          ..write('id: $id, ')
          ..write('metadataId: $metadataId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('year: $year, ')
          ..write('overview: $overview, ')
          ..write('runtime: $runtime, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('rating: $rating, ')
          ..write('voteCount: $voteCount, ')
          ..write('imdbId: $imdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isWatchlist: $isWatchlist, ')
          ..write('watchState: $watchState, ')
          ..write('playbackPositionSeconds: $playbackPositionSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TvShowsTable extends TvShows with TableInfo<$TvShowsTable, TvShow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TvShowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataIdMeta = const VerificationMeta(
    'metadataId',
  );
  @override
  late final GeneratedColumn<String> metadataId = GeneratedColumn<String>(
    'metadata_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta(
    'originalTitle',
  );
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstAirDateMeta = const VerificationMeta(
    'firstAirDate',
  );
  @override
  late final GeneratedColumn<DateTime> firstAirDate = GeneratedColumn<DateTime>(
    'first_air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropPathMeta = const VerificationMeta(
    'backdropPath',
  );
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
    'backdrop_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imdbIdMeta = const VerificationMeta('imdbId');
  @override
  late final GeneratedColumn<String> imdbId = GeneratedColumn<String>(
    'imdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isWatchlistMeta = const VerificationMeta(
    'isWatchlist',
  );
  @override
  late final GeneratedColumn<bool> isWatchlist = GeneratedColumn<bool>(
    'is_watchlist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_watchlist" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    metadataId,
    title,
    originalTitle,
    overview,
    firstAirDate,
    posterPath,
    backdropPath,
    rating,
    tmdbId,
    imdbId,
    isFavorite,
    isWatchlist,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tv_shows';
  @override
  VerificationContext validateIntegrity(
    Insertable<TvShow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('metadata_id')) {
      context.handle(
        _metadataIdMeta,
        metadataId.isAcceptableOrUnknown(data['metadata_id']!, _metadataIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(
          data['original_title']!,
          _originalTitleMeta,
        ),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('first_air_date')) {
      context.handle(
        _firstAirDateMeta,
        firstAirDate.isAcceptableOrUnknown(
          data['first_air_date']!,
          _firstAirDateMeta,
        ),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
        _backdropPathMeta,
        backdropPath.isAcceptableOrUnknown(
          data['backdrop_path']!,
          _backdropPathMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('imdb_id')) {
      context.handle(
        _imdbIdMeta,
        imdbId.isAcceptableOrUnknown(data['imdb_id']!, _imdbIdMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_watchlist')) {
      context.handle(
        _isWatchlistMeta,
        isWatchlist.isAcceptableOrUnknown(
          data['is_watchlist']!,
          _isWatchlistMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TvShow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TvShow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      metadataId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_title'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      firstAirDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_air_date'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      backdropPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_path'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
      imdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imdb_id'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isWatchlist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_watchlist'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TvShowsTable createAlias(String alias) {
    return $TvShowsTable(attachedDatabase, alias);
  }
}

class TvShow extends DataClass implements Insertable<TvShow> {
  final String id;
  final String? metadataId;
  final String title;
  final String? originalTitle;
  final String? overview;
  final DateTime? firstAirDate;
  final String? posterPath;
  final String? backdropPath;
  final double? rating;
  final int? tmdbId;
  final String? imdbId;
  final bool isFavorite;
  final bool isWatchlist;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TvShow({
    required this.id,
    this.metadataId,
    required this.title,
    this.originalTitle,
    this.overview,
    this.firstAirDate,
    this.posterPath,
    this.backdropPath,
    this.rating,
    this.tmdbId,
    this.imdbId,
    required this.isFavorite,
    required this.isWatchlist,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || metadataId != null) {
      map['metadata_id'] = Variable<String>(metadataId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || originalTitle != null) {
      map['original_title'] = Variable<String>(originalTitle);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || firstAirDate != null) {
      map['first_air_date'] = Variable<DateTime>(firstAirDate);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    if (!nullToAbsent || imdbId != null) {
      map['imdb_id'] = Variable<String>(imdbId);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_watchlist'] = Variable<bool>(isWatchlist);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TvShowsCompanion toCompanion(bool nullToAbsent) {
    return TvShowsCompanion(
      id: Value(id),
      metadataId: metadataId == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataId),
      title: Value(title),
      originalTitle: originalTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTitle),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      firstAirDate: firstAirDate == null && nullToAbsent
          ? const Value.absent()
          : Value(firstAirDate),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      imdbId: imdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(imdbId),
      isFavorite: Value(isFavorite),
      isWatchlist: Value(isWatchlist),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TvShow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TvShow(
      id: serializer.fromJson<String>(json['id']),
      metadataId: serializer.fromJson<String?>(json['metadataId']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String?>(json['originalTitle']),
      overview: serializer.fromJson<String?>(json['overview']),
      firstAirDate: serializer.fromJson<DateTime?>(json['firstAirDate']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
      rating: serializer.fromJson<double?>(json['rating']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      imdbId: serializer.fromJson<String?>(json['imdbId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isWatchlist: serializer.fromJson<bool>(json['isWatchlist']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'metadataId': serializer.toJson<String?>(metadataId),
      'title': serializer.toJson<String>(title),
      'originalTitle': serializer.toJson<String?>(originalTitle),
      'overview': serializer.toJson<String?>(overview),
      'firstAirDate': serializer.toJson<DateTime?>(firstAirDate),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
      'rating': serializer.toJson<double?>(rating),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'imdbId': serializer.toJson<String?>(imdbId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isWatchlist': serializer.toJson<bool>(isWatchlist),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TvShow copyWith({
    String? id,
    Value<String?> metadataId = const Value.absent(),
    String? title,
    Value<String?> originalTitle = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<DateTime?> firstAirDate = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    Value<String?> backdropPath = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<int?> tmdbId = const Value.absent(),
    Value<String?> imdbId = const Value.absent(),
    bool? isFavorite,
    bool? isWatchlist,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TvShow(
    id: id ?? this.id,
    metadataId: metadataId.present ? metadataId.value : this.metadataId,
    title: title ?? this.title,
    originalTitle: originalTitle.present
        ? originalTitle.value
        : this.originalTitle,
    overview: overview.present ? overview.value : this.overview,
    firstAirDate: firstAirDate.present ? firstAirDate.value : this.firstAirDate,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    backdropPath: backdropPath.present ? backdropPath.value : this.backdropPath,
    rating: rating.present ? rating.value : this.rating,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    imdbId: imdbId.present ? imdbId.value : this.imdbId,
    isFavorite: isFavorite ?? this.isFavorite,
    isWatchlist: isWatchlist ?? this.isWatchlist,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TvShow copyWithCompanion(TvShowsCompanion data) {
    return TvShow(
      id: data.id.present ? data.id.value : this.id,
      metadataId: data.metadataId.present
          ? data.metadataId.value
          : this.metadataId,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      overview: data.overview.present ? data.overview.value : this.overview,
      firstAirDate: data.firstAirDate.present
          ? data.firstAirDate.value
          : this.firstAirDate,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
      rating: data.rating.present ? data.rating.value : this.rating,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      imdbId: data.imdbId.present ? data.imdbId.value : this.imdbId,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isWatchlist: data.isWatchlist.present
          ? data.isWatchlist.value
          : this.isWatchlist,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TvShow(')
          ..write('id: $id, ')
          ..write('metadataId: $metadataId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('overview: $overview, ')
          ..write('firstAirDate: $firstAirDate, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('rating: $rating, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('imdbId: $imdbId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isWatchlist: $isWatchlist, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    metadataId,
    title,
    originalTitle,
    overview,
    firstAirDate,
    posterPath,
    backdropPath,
    rating,
    tmdbId,
    imdbId,
    isFavorite,
    isWatchlist,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TvShow &&
          other.id == this.id &&
          other.metadataId == this.metadataId &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.overview == this.overview &&
          other.firstAirDate == this.firstAirDate &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath &&
          other.rating == this.rating &&
          other.tmdbId == this.tmdbId &&
          other.imdbId == this.imdbId &&
          other.isFavorite == this.isFavorite &&
          other.isWatchlist == this.isWatchlist &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TvShowsCompanion extends UpdateCompanion<TvShow> {
  final Value<String> id;
  final Value<String?> metadataId;
  final Value<String> title;
  final Value<String?> originalTitle;
  final Value<String?> overview;
  final Value<DateTime?> firstAirDate;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<double?> rating;
  final Value<int?> tmdbId;
  final Value<String?> imdbId;
  final Value<bool> isFavorite;
  final Value<bool> isWatchlist;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TvShowsCompanion({
    this.id = const Value.absent(),
    this.metadataId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.overview = const Value.absent(),
    this.firstAirDate = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.rating = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isWatchlist = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TvShowsCompanion.insert({
    required String id,
    this.metadataId = const Value.absent(),
    required String title,
    this.originalTitle = const Value.absent(),
    this.overview = const Value.absent(),
    this.firstAirDate = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.rating = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isWatchlist = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TvShow> custom({
    Expression<String>? id,
    Expression<String>? metadataId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<String>? overview,
    Expression<DateTime>? firstAirDate,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<double>? rating,
    Expression<int>? tmdbId,
    Expression<String>? imdbId,
    Expression<bool>? isFavorite,
    Expression<bool>? isWatchlist,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (metadataId != null) 'metadata_id': metadataId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (overview != null) 'overview': overview,
      if (firstAirDate != null) 'first_air_date': firstAirDate,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (rating != null) 'rating': rating,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (imdbId != null) 'imdb_id': imdbId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isWatchlist != null) 'is_watchlist': isWatchlist,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TvShowsCompanion copyWith({
    Value<String>? id,
    Value<String?>? metadataId,
    Value<String>? title,
    Value<String?>? originalTitle,
    Value<String?>? overview,
    Value<DateTime?>? firstAirDate,
    Value<String?>? posterPath,
    Value<String?>? backdropPath,
    Value<double?>? rating,
    Value<int?>? tmdbId,
    Value<String?>? imdbId,
    Value<bool>? isFavorite,
    Value<bool>? isWatchlist,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TvShowsCompanion(
      id: id ?? this.id,
      metadataId: metadataId ?? this.metadataId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      overview: overview ?? this.overview,
      firstAirDate: firstAirDate ?? this.firstAirDate,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      rating: rating ?? this.rating,
      tmdbId: tmdbId ?? this.tmdbId,
      imdbId: imdbId ?? this.imdbId,
      isFavorite: isFavorite ?? this.isFavorite,
      isWatchlist: isWatchlist ?? this.isWatchlist,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (metadataId.present) {
      map['metadata_id'] = Variable<String>(metadataId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (firstAirDate.present) {
      map['first_air_date'] = Variable<DateTime>(firstAirDate.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (imdbId.present) {
      map['imdb_id'] = Variable<String>(imdbId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isWatchlist.present) {
      map['is_watchlist'] = Variable<bool>(isWatchlist.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TvShowsCompanion(')
          ..write('id: $id, ')
          ..write('metadataId: $metadataId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('overview: $overview, ')
          ..write('firstAirDate: $firstAirDate, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('rating: $rating, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('imdbId: $imdbId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isWatchlist: $isWatchlist, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeasonsTable extends Seasons with TableInfo<$SeasonsTable, Season> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _showIdMeta = const VerificationMeta('showId');
  @override
  late final GeneratedColumn<String> showId = GeneratedColumn<String>(
    'show_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tv_shows (id)',
    ),
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _airDateMeta = const VerificationMeta(
    'airDate',
  );
  @override
  late final GeneratedColumn<DateTime> airDate = GeneratedColumn<DateTime>(
    'air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    showId,
    seasonNumber,
    name,
    overview,
    posterPath,
    airDate,
    tmdbId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Season> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('show_id')) {
      context.handle(
        _showIdMeta,
        showId.isAcceptableOrUnknown(data['show_id']!, _showIdMeta),
      );
    } else if (isInserting) {
      context.missing(_showIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('air_date')) {
      context.handle(
        _airDateMeta,
        airDate.isAcceptableOrUnknown(data['air_date']!, _airDateMeta),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Season map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Season(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      showId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}show_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      airDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}air_date'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
    );
  }

  @override
  $SeasonsTable createAlias(String alias) {
    return $SeasonsTable(attachedDatabase, alias);
  }
}

class Season extends DataClass implements Insertable<Season> {
  final String id;
  final String showId;
  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? posterPath;
  final DateTime? airDate;
  final int? tmdbId;
  const Season({
    required this.id,
    required this.showId,
    required this.seasonNumber,
    this.name,
    this.overview,
    this.posterPath,
    this.airDate,
    this.tmdbId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['show_id'] = Variable<String>(showId);
    map['season_number'] = Variable<int>(seasonNumber);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || airDate != null) {
      map['air_date'] = Variable<DateTime>(airDate);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    return map;
  }

  SeasonsCompanion toCompanion(bool nullToAbsent) {
    return SeasonsCompanion(
      id: Value(id),
      showId: Value(showId),
      seasonNumber: Value(seasonNumber),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      airDate: airDate == null && nullToAbsent
          ? const Value.absent()
          : Value(airDate),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
    );
  }

  factory Season.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Season(
      id: serializer.fromJson<String>(json['id']),
      showId: serializer.fromJson<String>(json['showId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      name: serializer.fromJson<String?>(json['name']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      airDate: serializer.fromJson<DateTime?>(json['airDate']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'showId': serializer.toJson<String>(showId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'name': serializer.toJson<String?>(name),
      'overview': serializer.toJson<String?>(overview),
      'posterPath': serializer.toJson<String?>(posterPath),
      'airDate': serializer.toJson<DateTime?>(airDate),
      'tmdbId': serializer.toJson<int?>(tmdbId),
    };
  }

  Season copyWith({
    String? id,
    String? showId,
    int? seasonNumber,
    Value<String?> name = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    Value<DateTime?> airDate = const Value.absent(),
    Value<int?> tmdbId = const Value.absent(),
  }) => Season(
    id: id ?? this.id,
    showId: showId ?? this.showId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    name: name.present ? name.value : this.name,
    overview: overview.present ? overview.value : this.overview,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    airDate: airDate.present ? airDate.value : this.airDate,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
  );
  Season copyWithCompanion(SeasonsCompanion data) {
    return Season(
      id: data.id.present ? data.id.value : this.id,
      showId: data.showId.present ? data.showId.value : this.showId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      name: data.name.present ? data.name.value : this.name,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      airDate: data.airDate.present ? data.airDate.value : this.airDate,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Season(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('airDate: $airDate, ')
          ..write('tmdbId: $tmdbId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    showId,
    seasonNumber,
    name,
    overview,
    posterPath,
    airDate,
    tmdbId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Season &&
          other.id == this.id &&
          other.showId == this.showId &&
          other.seasonNumber == this.seasonNumber &&
          other.name == this.name &&
          other.overview == this.overview &&
          other.posterPath == this.posterPath &&
          other.airDate == this.airDate &&
          other.tmdbId == this.tmdbId);
}

class SeasonsCompanion extends UpdateCompanion<Season> {
  final Value<String> id;
  final Value<String> showId;
  final Value<int> seasonNumber;
  final Value<String?> name;
  final Value<String?> overview;
  final Value<String?> posterPath;
  final Value<DateTime?> airDate;
  final Value<int?> tmdbId;
  final Value<int> rowid;
  const SeasonsCompanion({
    this.id = const Value.absent(),
    this.showId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.airDate = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeasonsCompanion.insert({
    required String id,
    required String showId,
    required int seasonNumber,
    this.name = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.airDate = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       showId = Value(showId),
       seasonNumber = Value(seasonNumber);
  static Insertable<Season> custom({
    Expression<String>? id,
    Expression<String>? showId,
    Expression<int>? seasonNumber,
    Expression<String>? name,
    Expression<String>? overview,
    Expression<String>? posterPath,
    Expression<DateTime>? airDate,
    Expression<int>? tmdbId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (showId != null) 'show_id': showId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (name != null) 'name': name,
      if (overview != null) 'overview': overview,
      if (posterPath != null) 'poster_path': posterPath,
      if (airDate != null) 'air_date': airDate,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeasonsCompanion copyWith({
    Value<String>? id,
    Value<String>? showId,
    Value<int>? seasonNumber,
    Value<String?>? name,
    Value<String?>? overview,
    Value<String?>? posterPath,
    Value<DateTime?>? airDate,
    Value<int?>? tmdbId,
    Value<int>? rowid,
  }) {
    return SeasonsCompanion(
      id: id ?? this.id,
      showId: showId ?? this.showId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      airDate: airDate ?? this.airDate,
      tmdbId: tmdbId ?? this.tmdbId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (showId.present) {
      map['show_id'] = Variable<String>(showId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (airDate.present) {
      map['air_date'] = Variable<DateTime>(airDate.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsCompanion(')
          ..write('id: $id, ')
          ..write('showId: $showId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('airDate: $airDate, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES seasons (id)',
    ),
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _airDateMeta = const VerificationMeta(
    'airDate',
  );
  @override
  late final GeneratedColumn<DateTime> airDate = GeneratedColumn<DateTime>(
    'air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runtimeMeta = const VerificationMeta(
    'runtime',
  );
  @override
  late final GeneratedColumn<int> runtime = GeneratedColumn<int>(
    'runtime',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stillPathMeta = const VerificationMeta(
    'stillPath',
  );
  @override
  late final GeneratedColumn<String> stillPath = GeneratedColumn<String>(
    'still_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _watchStateMeta = const VerificationMeta(
    'watchState',
  );
  @override
  late final GeneratedColumn<String> watchState = GeneratedColumn<String>(
    'watch_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UNWATCHED'),
  );
  static const VerificationMeta _playbackPositionSecondsMeta =
      const VerificationMeta('playbackPositionSeconds');
  @override
  late final GeneratedColumn<int> playbackPositionSeconds =
      GeneratedColumn<int>(
        'playback_position_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seasonId,
    episodeNumber,
    name,
    overview,
    airDate,
    runtime,
    stillPath,
    rating,
    tmdbId,
    watchState,
    playbackPositionSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Episode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonIdMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('air_date')) {
      context.handle(
        _airDateMeta,
        airDate.isAcceptableOrUnknown(data['air_date']!, _airDateMeta),
      );
    }
    if (data.containsKey('runtime')) {
      context.handle(
        _runtimeMeta,
        runtime.isAcceptableOrUnknown(data['runtime']!, _runtimeMeta),
      );
    }
    if (data.containsKey('still_path')) {
      context.handle(
        _stillPathMeta,
        stillPath.isAcceptableOrUnknown(data['still_path']!, _stillPathMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('watch_state')) {
      context.handle(
        _watchStateMeta,
        watchState.isAcceptableOrUnknown(data['watch_state']!, _watchStateMeta),
      );
    }
    if (data.containsKey('playback_position_seconds')) {
      context.handle(
        _playbackPositionSecondsMeta,
        playbackPositionSeconds.isAcceptableOrUnknown(
          data['playback_position_seconds']!,
          _playbackPositionSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      )!,
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      airDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}air_date'],
      ),
      runtime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime'],
      ),
      stillPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}still_path'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      ),
      watchState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}watch_state'],
      )!,
      playbackPositionSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playback_position_seconds'],
      )!,
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class Episode extends DataClass implements Insertable<Episode> {
  final String id;
  final String seasonId;
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
  const Episode({
    required this.id,
    required this.seasonId,
    required this.episodeNumber,
    this.name,
    this.overview,
    this.airDate,
    this.runtime,
    this.stillPath,
    this.rating,
    this.tmdbId,
    required this.watchState,
    required this.playbackPositionSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['season_id'] = Variable<String>(seasonId);
    map['episode_number'] = Variable<int>(episodeNumber);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || airDate != null) {
      map['air_date'] = Variable<DateTime>(airDate);
    }
    if (!nullToAbsent || runtime != null) {
      map['runtime'] = Variable<int>(runtime);
    }
    if (!nullToAbsent || stillPath != null) {
      map['still_path'] = Variable<String>(stillPath);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    map['watch_state'] = Variable<String>(watchState);
    map['playback_position_seconds'] = Variable<int>(playbackPositionSeconds);
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      seasonId: Value(seasonId),
      episodeNumber: Value(episodeNumber),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      airDate: airDate == null && nullToAbsent
          ? const Value.absent()
          : Value(airDate),
      runtime: runtime == null && nullToAbsent
          ? const Value.absent()
          : Value(runtime),
      stillPath: stillPath == null && nullToAbsent
          ? const Value.absent()
          : Value(stillPath),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      tmdbId: tmdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmdbId),
      watchState: Value(watchState),
      playbackPositionSeconds: Value(playbackPositionSeconds),
    );
  }

  factory Episode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      id: serializer.fromJson<String>(json['id']),
      seasonId: serializer.fromJson<String>(json['seasonId']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      name: serializer.fromJson<String?>(json['name']),
      overview: serializer.fromJson<String?>(json['overview']),
      airDate: serializer.fromJson<DateTime?>(json['airDate']),
      runtime: serializer.fromJson<int?>(json['runtime']),
      stillPath: serializer.fromJson<String?>(json['stillPath']),
      rating: serializer.fromJson<double?>(json['rating']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      watchState: serializer.fromJson<String>(json['watchState']),
      playbackPositionSeconds: serializer.fromJson<int>(
        json['playbackPositionSeconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'seasonId': serializer.toJson<String>(seasonId),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'name': serializer.toJson<String?>(name),
      'overview': serializer.toJson<String?>(overview),
      'airDate': serializer.toJson<DateTime?>(airDate),
      'runtime': serializer.toJson<int?>(runtime),
      'stillPath': serializer.toJson<String?>(stillPath),
      'rating': serializer.toJson<double?>(rating),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'watchState': serializer.toJson<String>(watchState),
      'playbackPositionSeconds': serializer.toJson<int>(
        playbackPositionSeconds,
      ),
    };
  }

  Episode copyWith({
    String? id,
    String? seasonId,
    int? episodeNumber,
    Value<String?> name = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<DateTime?> airDate = const Value.absent(),
    Value<int?> runtime = const Value.absent(),
    Value<String?> stillPath = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<int?> tmdbId = const Value.absent(),
    String? watchState,
    int? playbackPositionSeconds,
  }) => Episode(
    id: id ?? this.id,
    seasonId: seasonId ?? this.seasonId,
    episodeNumber: episodeNumber ?? this.episodeNumber,
    name: name.present ? name.value : this.name,
    overview: overview.present ? overview.value : this.overview,
    airDate: airDate.present ? airDate.value : this.airDate,
    runtime: runtime.present ? runtime.value : this.runtime,
    stillPath: stillPath.present ? stillPath.value : this.stillPath,
    rating: rating.present ? rating.value : this.rating,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    watchState: watchState ?? this.watchState,
    playbackPositionSeconds:
        playbackPositionSeconds ?? this.playbackPositionSeconds,
  );
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      id: data.id.present ? data.id.value : this.id,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      name: data.name.present ? data.name.value : this.name,
      overview: data.overview.present ? data.overview.value : this.overview,
      airDate: data.airDate.present ? data.airDate.value : this.airDate,
      runtime: data.runtime.present ? data.runtime.value : this.runtime,
      stillPath: data.stillPath.present ? data.stillPath.value : this.stillPath,
      rating: data.rating.present ? data.rating.value : this.rating,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      watchState: data.watchState.present
          ? data.watchState.value
          : this.watchState,
      playbackPositionSeconds: data.playbackPositionSeconds.present
          ? data.playbackPositionSeconds.value
          : this.playbackPositionSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('id: $id, ')
          ..write('seasonId: $seasonId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('airDate: $airDate, ')
          ..write('runtime: $runtime, ')
          ..write('stillPath: $stillPath, ')
          ..write('rating: $rating, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('watchState: $watchState, ')
          ..write('playbackPositionSeconds: $playbackPositionSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seasonId,
    episodeNumber,
    name,
    overview,
    airDate,
    runtime,
    stillPath,
    rating,
    tmdbId,
    watchState,
    playbackPositionSeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.id == this.id &&
          other.seasonId == this.seasonId &&
          other.episodeNumber == this.episodeNumber &&
          other.name == this.name &&
          other.overview == this.overview &&
          other.airDate == this.airDate &&
          other.runtime == this.runtime &&
          other.stillPath == this.stillPath &&
          other.rating == this.rating &&
          other.tmdbId == this.tmdbId &&
          other.watchState == this.watchState &&
          other.playbackPositionSeconds == this.playbackPositionSeconds);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<String> id;
  final Value<String> seasonId;
  final Value<int> episodeNumber;
  final Value<String?> name;
  final Value<String?> overview;
  final Value<DateTime?> airDate;
  final Value<int?> runtime;
  final Value<String?> stillPath;
  final Value<double?> rating;
  final Value<int?> tmdbId;
  final Value<String> watchState;
  final Value<int> playbackPositionSeconds;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.overview = const Value.absent(),
    this.airDate = const Value.absent(),
    this.runtime = const Value.absent(),
    this.stillPath = const Value.absent(),
    this.rating = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.watchState = const Value.absent(),
    this.playbackPositionSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required String id,
    required String seasonId,
    required int episodeNumber,
    this.name = const Value.absent(),
    this.overview = const Value.absent(),
    this.airDate = const Value.absent(),
    this.runtime = const Value.absent(),
    this.stillPath = const Value.absent(),
    this.rating = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.watchState = const Value.absent(),
    this.playbackPositionSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seasonId = Value(seasonId),
       episodeNumber = Value(episodeNumber);
  static Insertable<Episode> custom({
    Expression<String>? id,
    Expression<String>? seasonId,
    Expression<int>? episodeNumber,
    Expression<String>? name,
    Expression<String>? overview,
    Expression<DateTime>? airDate,
    Expression<int>? runtime,
    Expression<String>? stillPath,
    Expression<double>? rating,
    Expression<int>? tmdbId,
    Expression<String>? watchState,
    Expression<int>? playbackPositionSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seasonId != null) 'season_id': seasonId,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (name != null) 'name': name,
      if (overview != null) 'overview': overview,
      if (airDate != null) 'air_date': airDate,
      if (runtime != null) 'runtime': runtime,
      if (stillPath != null) 'still_path': stillPath,
      if (rating != null) 'rating': rating,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (watchState != null) 'watch_state': watchState,
      if (playbackPositionSeconds != null)
        'playback_position_seconds': playbackPositionSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith({
    Value<String>? id,
    Value<String>? seasonId,
    Value<int>? episodeNumber,
    Value<String?>? name,
    Value<String?>? overview,
    Value<DateTime?>? airDate,
    Value<int?>? runtime,
    Value<String?>? stillPath,
    Value<double?>? rating,
    Value<int?>? tmdbId,
    Value<String>? watchState,
    Value<int>? playbackPositionSeconds,
    Value<int>? rowid,
  }) {
    return EpisodesCompanion(
      id: id ?? this.id,
      seasonId: seasonId ?? this.seasonId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      airDate: airDate ?? this.airDate,
      runtime: runtime ?? this.runtime,
      stillPath: stillPath ?? this.stillPath,
      rating: rating ?? this.rating,
      tmdbId: tmdbId ?? this.tmdbId,
      watchState: watchState ?? this.watchState,
      playbackPositionSeconds:
          playbackPositionSeconds ?? this.playbackPositionSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (airDate.present) {
      map['air_date'] = Variable<DateTime>(airDate.value);
    }
    if (runtime.present) {
      map['runtime'] = Variable<int>(runtime.value);
    }
    if (stillPath.present) {
      map['still_path'] = Variable<String>(stillPath.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (watchState.present) {
      map['watch_state'] = Variable<String>(watchState.value);
    }
    if (playbackPositionSeconds.present) {
      map['playback_position_seconds'] = Variable<int>(
        playbackPositionSeconds.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('seasonId: $seasonId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('airDate: $airDate, ')
          ..write('runtime: $runtime, ')
          ..write('stillPath: $stillPath, ')
          ..write('rating: $rating, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('watchState: $watchState, ')
          ..write('playbackPositionSeconds: $playbackPositionSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaSourcesTable extends MediaSources
    with TableInfo<$MediaSourcesTable, MediaSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movieIdMeta = const VerificationMeta(
    'movieId',
  );
  @override
  late final GeneratedColumn<String> movieId = GeneratedColumn<String>(
    'movie_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES movies (id)',
    ),
  );
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
    'episode_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES episodes (id)',
    ),
  );
  static const VerificationMeta _storageIdMeta = const VerificationMeta(
    'storageId',
  );
  @override
  late final GeneratedColumn<String> storageId = GeneratedColumn<String>(
    'storage_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES storages (id)',
    ),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extensionMeta = const VerificationMeta(
    'extension',
  );
  @override
  late final GeneratedColumn<String> extension = GeneratedColumn<String>(
    'extension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<BigInt> fileSize = GeneratedColumn<BigInt>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoCodecMeta = const VerificationMeta(
    'videoCodec',
  );
  @override
  late final GeneratedColumn<String> videoCodec = GeneratedColumn<String>(
    'video_codec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioCodecMeta = const VerificationMeta(
    'audioCodec',
  );
  @override
  late final GeneratedColumn<String> audioCodec = GeneratedColumn<String>(
    'audio_codec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  @override
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioChannelsMeta = const VerificationMeta(
    'audioChannels',
  );
  @override
  late final GeneratedColumn<String> audioChannels = GeneratedColumn<String>(
    'audio_channels',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtitleInformationMeta =
      const VerificationMeta('subtitleInformation');
  @override
  late final GeneratedColumn<String> subtitleInformation =
      GeneratedColumn<String>(
        'subtitle_information',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstSeenAtMeta = const VerificationMeta(
    'firstSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeenAt = GeneratedColumn<DateTime>(
    'first_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availableMeta = const VerificationMeta(
    'available',
  );
  @override
  late final GeneratedColumn<bool> available = GeneratedColumn<bool>(
    'available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    movieId,
    episodeId,
    storageId,
    sourceType,
    relativePath,
    filename,
    extension,
    fileSize,
    duration,
    videoCodec,
    audioCodec,
    resolution,
    audioChannels,
    subtitleInformation,
    fingerprint,
    createdAt,
    firstSeenAt,
    lastSeenAt,
    available,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('movie_id')) {
      context.handle(
        _movieIdMeta,
        movieId.isAcceptableOrUnknown(data['movie_id']!, _movieIdMeta),
      );
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    }
    if (data.containsKey('storage_id')) {
      context.handle(
        _storageIdMeta,
        storageId.isAcceptableOrUnknown(data['storage_id']!, _storageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storageIdMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('extension')) {
      context.handle(
        _extensionMeta,
        extension.isAcceptableOrUnknown(data['extension']!, _extensionMeta),
      );
    } else if (isInserting) {
      context.missing(_extensionMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('video_codec')) {
      context.handle(
        _videoCodecMeta,
        videoCodec.isAcceptableOrUnknown(data['video_codec']!, _videoCodecMeta),
      );
    }
    if (data.containsKey('audio_codec')) {
      context.handle(
        _audioCodecMeta,
        audioCodec.isAcceptableOrUnknown(data['audio_codec']!, _audioCodecMeta),
      );
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    }
    if (data.containsKey('audio_channels')) {
      context.handle(
        _audioChannelsMeta,
        audioChannels.isAcceptableOrUnknown(
          data['audio_channels']!,
          _audioChannelsMeta,
        ),
      );
    }
    if (data.containsKey('subtitle_information')) {
      context.handle(
        _subtitleInformationMeta,
        subtitleInformation.isAcceptableOrUnknown(
          data['subtitle_information']!,
          _subtitleInformationMeta,
        ),
      );
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('first_seen_at')) {
      context.handle(
        _firstSeenAtMeta,
        firstSeenAt.isAcceptableOrUnknown(
          data['first_seen_at']!,
          _firstSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstSeenAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('available')) {
      context.handle(
        _availableMeta,
        available.isAcceptableOrUnknown(data['available']!, _availableMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaSource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      movieId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movie_id'],
      ),
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      ),
      storageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      extension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extension'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}file_size'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      videoCodec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_codec'],
      ),
      audioCodec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_codec'],
      ),
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      ),
      audioChannels: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_channels'],
      ),
      subtitleInformation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle_information'],
      ),
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      firstSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
      available: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}available'],
      )!,
    );
  }

  @override
  $MediaSourcesTable createAlias(String alias) {
    return $MediaSourcesTable(attachedDatabase, alias);
  }
}

class MediaSource extends DataClass implements Insertable<MediaSource> {
  final String id;
  final String? movieId;
  final String? episodeId;
  final String storageId;
  final String sourceType;
  final String relativePath;
  final String filename;
  final String extension;
  final BigInt fileSize;
  final int? duration;
  final String? videoCodec;
  final String? audioCodec;
  final String? resolution;
  final String? audioChannels;
  final String? subtitleInformation;
  final String? fingerprint;
  final DateTime createdAt;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final bool available;
  const MediaSource({
    required this.id,
    this.movieId,
    this.episodeId,
    required this.storageId,
    required this.sourceType,
    required this.relativePath,
    required this.filename,
    required this.extension,
    required this.fileSize,
    this.duration,
    this.videoCodec,
    this.audioCodec,
    this.resolution,
    this.audioChannels,
    this.subtitleInformation,
    this.fingerprint,
    required this.createdAt,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.available,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || movieId != null) {
      map['movie_id'] = Variable<String>(movieId);
    }
    if (!nullToAbsent || episodeId != null) {
      map['episode_id'] = Variable<String>(episodeId);
    }
    map['storage_id'] = Variable<String>(storageId);
    map['source_type'] = Variable<String>(sourceType);
    map['relative_path'] = Variable<String>(relativePath);
    map['filename'] = Variable<String>(filename);
    map['extension'] = Variable<String>(extension);
    map['file_size'] = Variable<BigInt>(fileSize);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || videoCodec != null) {
      map['video_codec'] = Variable<String>(videoCodec);
    }
    if (!nullToAbsent || audioCodec != null) {
      map['audio_codec'] = Variable<String>(audioCodec);
    }
    if (!nullToAbsent || resolution != null) {
      map['resolution'] = Variable<String>(resolution);
    }
    if (!nullToAbsent || audioChannels != null) {
      map['audio_channels'] = Variable<String>(audioChannels);
    }
    if (!nullToAbsent || subtitleInformation != null) {
      map['subtitle_information'] = Variable<String>(subtitleInformation);
    }
    if (!nullToAbsent || fingerprint != null) {
      map['fingerprint'] = Variable<String>(fingerprint);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['first_seen_at'] = Variable<DateTime>(firstSeenAt);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    map['available'] = Variable<bool>(available);
    return map;
  }

  MediaSourcesCompanion toCompanion(bool nullToAbsent) {
    return MediaSourcesCompanion(
      id: Value(id),
      movieId: movieId == null && nullToAbsent
          ? const Value.absent()
          : Value(movieId),
      episodeId: episodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeId),
      storageId: Value(storageId),
      sourceType: Value(sourceType),
      relativePath: Value(relativePath),
      filename: Value(filename),
      extension: Value(extension),
      fileSize: Value(fileSize),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      videoCodec: videoCodec == null && nullToAbsent
          ? const Value.absent()
          : Value(videoCodec),
      audioCodec: audioCodec == null && nullToAbsent
          ? const Value.absent()
          : Value(audioCodec),
      resolution: resolution == null && nullToAbsent
          ? const Value.absent()
          : Value(resolution),
      audioChannels: audioChannels == null && nullToAbsent
          ? const Value.absent()
          : Value(audioChannels),
      subtitleInformation: subtitleInformation == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitleInformation),
      fingerprint: fingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(fingerprint),
      createdAt: Value(createdAt),
      firstSeenAt: Value(firstSeenAt),
      lastSeenAt: Value(lastSeenAt),
      available: Value(available),
    );
  }

  factory MediaSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaSource(
      id: serializer.fromJson<String>(json['id']),
      movieId: serializer.fromJson<String?>(json['movieId']),
      episodeId: serializer.fromJson<String?>(json['episodeId']),
      storageId: serializer.fromJson<String>(json['storageId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      filename: serializer.fromJson<String>(json['filename']),
      extension: serializer.fromJson<String>(json['extension']),
      fileSize: serializer.fromJson<BigInt>(json['fileSize']),
      duration: serializer.fromJson<int?>(json['duration']),
      videoCodec: serializer.fromJson<String?>(json['videoCodec']),
      audioCodec: serializer.fromJson<String?>(json['audioCodec']),
      resolution: serializer.fromJson<String?>(json['resolution']),
      audioChannels: serializer.fromJson<String?>(json['audioChannels']),
      subtitleInformation: serializer.fromJson<String?>(
        json['subtitleInformation'],
      ),
      fingerprint: serializer.fromJson<String?>(json['fingerprint']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      firstSeenAt: serializer.fromJson<DateTime>(json['firstSeenAt']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      available: serializer.fromJson<bool>(json['available']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'movieId': serializer.toJson<String?>(movieId),
      'episodeId': serializer.toJson<String?>(episodeId),
      'storageId': serializer.toJson<String>(storageId),
      'sourceType': serializer.toJson<String>(sourceType),
      'relativePath': serializer.toJson<String>(relativePath),
      'filename': serializer.toJson<String>(filename),
      'extension': serializer.toJson<String>(extension),
      'fileSize': serializer.toJson<BigInt>(fileSize),
      'duration': serializer.toJson<int?>(duration),
      'videoCodec': serializer.toJson<String?>(videoCodec),
      'audioCodec': serializer.toJson<String?>(audioCodec),
      'resolution': serializer.toJson<String?>(resolution),
      'audioChannels': serializer.toJson<String?>(audioChannels),
      'subtitleInformation': serializer.toJson<String?>(subtitleInformation),
      'fingerprint': serializer.toJson<String?>(fingerprint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'firstSeenAt': serializer.toJson<DateTime>(firstSeenAt),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'available': serializer.toJson<bool>(available),
    };
  }

  MediaSource copyWith({
    String? id,
    Value<String?> movieId = const Value.absent(),
    Value<String?> episodeId = const Value.absent(),
    String? storageId,
    String? sourceType,
    String? relativePath,
    String? filename,
    String? extension,
    BigInt? fileSize,
    Value<int?> duration = const Value.absent(),
    Value<String?> videoCodec = const Value.absent(),
    Value<String?> audioCodec = const Value.absent(),
    Value<String?> resolution = const Value.absent(),
    Value<String?> audioChannels = const Value.absent(),
    Value<String?> subtitleInformation = const Value.absent(),
    Value<String?> fingerprint = const Value.absent(),
    DateTime? createdAt,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    bool? available,
  }) => MediaSource(
    id: id ?? this.id,
    movieId: movieId.present ? movieId.value : this.movieId,
    episodeId: episodeId.present ? episodeId.value : this.episodeId,
    storageId: storageId ?? this.storageId,
    sourceType: sourceType ?? this.sourceType,
    relativePath: relativePath ?? this.relativePath,
    filename: filename ?? this.filename,
    extension: extension ?? this.extension,
    fileSize: fileSize ?? this.fileSize,
    duration: duration.present ? duration.value : this.duration,
    videoCodec: videoCodec.present ? videoCodec.value : this.videoCodec,
    audioCodec: audioCodec.present ? audioCodec.value : this.audioCodec,
    resolution: resolution.present ? resolution.value : this.resolution,
    audioChannels: audioChannels.present
        ? audioChannels.value
        : this.audioChannels,
    subtitleInformation: subtitleInformation.present
        ? subtitleInformation.value
        : this.subtitleInformation,
    fingerprint: fingerprint.present ? fingerprint.value : this.fingerprint,
    createdAt: createdAt ?? this.createdAt,
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    available: available ?? this.available,
  );
  MediaSource copyWithCompanion(MediaSourcesCompanion data) {
    return MediaSource(
      id: data.id.present ? data.id.value : this.id,
      movieId: data.movieId.present ? data.movieId.value : this.movieId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      storageId: data.storageId.present ? data.storageId.value : this.storageId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      filename: data.filename.present ? data.filename.value : this.filename,
      extension: data.extension.present ? data.extension.value : this.extension,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      duration: data.duration.present ? data.duration.value : this.duration,
      videoCodec: data.videoCodec.present
          ? data.videoCodec.value
          : this.videoCodec,
      audioCodec: data.audioCodec.present
          ? data.audioCodec.value
          : this.audioCodec,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
      audioChannels: data.audioChannels.present
          ? data.audioChannels.value
          : this.audioChannels,
      subtitleInformation: data.subtitleInformation.present
          ? data.subtitleInformation.value
          : this.subtitleInformation,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      firstSeenAt: data.firstSeenAt.present
          ? data.firstSeenAt.value
          : this.firstSeenAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      available: data.available.present ? data.available.value : this.available,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaSource(')
          ..write('id: $id, ')
          ..write('movieId: $movieId, ')
          ..write('episodeId: $episodeId, ')
          ..write('storageId: $storageId, ')
          ..write('sourceType: $sourceType, ')
          ..write('relativePath: $relativePath, ')
          ..write('filename: $filename, ')
          ..write('extension: $extension, ')
          ..write('fileSize: $fileSize, ')
          ..write('duration: $duration, ')
          ..write('videoCodec: $videoCodec, ')
          ..write('audioCodec: $audioCodec, ')
          ..write('resolution: $resolution, ')
          ..write('audioChannels: $audioChannels, ')
          ..write('subtitleInformation: $subtitleInformation, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('createdAt: $createdAt, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('available: $available')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    movieId,
    episodeId,
    storageId,
    sourceType,
    relativePath,
    filename,
    extension,
    fileSize,
    duration,
    videoCodec,
    audioCodec,
    resolution,
    audioChannels,
    subtitleInformation,
    fingerprint,
    createdAt,
    firstSeenAt,
    lastSeenAt,
    available,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaSource &&
          other.id == this.id &&
          other.movieId == this.movieId &&
          other.episodeId == this.episodeId &&
          other.storageId == this.storageId &&
          other.sourceType == this.sourceType &&
          other.relativePath == this.relativePath &&
          other.filename == this.filename &&
          other.extension == this.extension &&
          other.fileSize == this.fileSize &&
          other.duration == this.duration &&
          other.videoCodec == this.videoCodec &&
          other.audioCodec == this.audioCodec &&
          other.resolution == this.resolution &&
          other.audioChannels == this.audioChannels &&
          other.subtitleInformation == this.subtitleInformation &&
          other.fingerprint == this.fingerprint &&
          other.createdAt == this.createdAt &&
          other.firstSeenAt == this.firstSeenAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.available == this.available);
}

class MediaSourcesCompanion extends UpdateCompanion<MediaSource> {
  final Value<String> id;
  final Value<String?> movieId;
  final Value<String?> episodeId;
  final Value<String> storageId;
  final Value<String> sourceType;
  final Value<String> relativePath;
  final Value<String> filename;
  final Value<String> extension;
  final Value<BigInt> fileSize;
  final Value<int?> duration;
  final Value<String?> videoCodec;
  final Value<String?> audioCodec;
  final Value<String?> resolution;
  final Value<String?> audioChannels;
  final Value<String?> subtitleInformation;
  final Value<String?> fingerprint;
  final Value<DateTime> createdAt;
  final Value<DateTime> firstSeenAt;
  final Value<DateTime> lastSeenAt;
  final Value<bool> available;
  final Value<int> rowid;
  const MediaSourcesCompanion({
    this.id = const Value.absent(),
    this.movieId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.storageId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.filename = const Value.absent(),
    this.extension = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.duration = const Value.absent(),
    this.videoCodec = const Value.absent(),
    this.audioCodec = const Value.absent(),
    this.resolution = const Value.absent(),
    this.audioChannels = const Value.absent(),
    this.subtitleInformation = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.available = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaSourcesCompanion.insert({
    required String id,
    this.movieId = const Value.absent(),
    this.episodeId = const Value.absent(),
    required String storageId,
    required String sourceType,
    required String relativePath,
    required String filename,
    required String extension,
    required BigInt fileSize,
    this.duration = const Value.absent(),
    this.videoCodec = const Value.absent(),
    this.audioCodec = const Value.absent(),
    this.resolution = const Value.absent(),
    this.audioChannels = const Value.absent(),
    this.subtitleInformation = const Value.absent(),
    this.fingerprint = const Value.absent(),
    required DateTime createdAt,
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
    this.available = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storageId = Value(storageId),
       sourceType = Value(sourceType),
       relativePath = Value(relativePath),
       filename = Value(filename),
       extension = Value(extension),
       fileSize = Value(fileSize),
       createdAt = Value(createdAt),
       firstSeenAt = Value(firstSeenAt),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<MediaSource> custom({
    Expression<String>? id,
    Expression<String>? movieId,
    Expression<String>? episodeId,
    Expression<String>? storageId,
    Expression<String>? sourceType,
    Expression<String>? relativePath,
    Expression<String>? filename,
    Expression<String>? extension,
    Expression<BigInt>? fileSize,
    Expression<int>? duration,
    Expression<String>? videoCodec,
    Expression<String>? audioCodec,
    Expression<String>? resolution,
    Expression<String>? audioChannels,
    Expression<String>? subtitleInformation,
    Expression<String>? fingerprint,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? firstSeenAt,
    Expression<DateTime>? lastSeenAt,
    Expression<bool>? available,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (movieId != null) 'movie_id': movieId,
      if (episodeId != null) 'episode_id': episodeId,
      if (storageId != null) 'storage_id': storageId,
      if (sourceType != null) 'source_type': sourceType,
      if (relativePath != null) 'relative_path': relativePath,
      if (filename != null) 'filename': filename,
      if (extension != null) 'extension': extension,
      if (fileSize != null) 'file_size': fileSize,
      if (duration != null) 'duration': duration,
      if (videoCodec != null) 'video_codec': videoCodec,
      if (audioCodec != null) 'audio_codec': audioCodec,
      if (resolution != null) 'resolution': resolution,
      if (audioChannels != null) 'audio_channels': audioChannels,
      if (subtitleInformation != null)
        'subtitle_information': subtitleInformation,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (createdAt != null) 'created_at': createdAt,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (available != null) 'available': available,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaSourcesCompanion copyWith({
    Value<String>? id,
    Value<String?>? movieId,
    Value<String?>? episodeId,
    Value<String>? storageId,
    Value<String>? sourceType,
    Value<String>? relativePath,
    Value<String>? filename,
    Value<String>? extension,
    Value<BigInt>? fileSize,
    Value<int?>? duration,
    Value<String?>? videoCodec,
    Value<String?>? audioCodec,
    Value<String?>? resolution,
    Value<String?>? audioChannels,
    Value<String?>? subtitleInformation,
    Value<String?>? fingerprint,
    Value<DateTime>? createdAt,
    Value<DateTime>? firstSeenAt,
    Value<DateTime>? lastSeenAt,
    Value<bool>? available,
    Value<int>? rowid,
  }) {
    return MediaSourcesCompanion(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      episodeId: episodeId ?? this.episodeId,
      storageId: storageId ?? this.storageId,
      sourceType: sourceType ?? this.sourceType,
      relativePath: relativePath ?? this.relativePath,
      filename: filename ?? this.filename,
      extension: extension ?? this.extension,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      resolution: resolution ?? this.resolution,
      audioChannels: audioChannels ?? this.audioChannels,
      subtitleInformation: subtitleInformation ?? this.subtitleInformation,
      fingerprint: fingerprint ?? this.fingerprint,
      createdAt: createdAt ?? this.createdAt,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      available: available ?? this.available,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (movieId.present) {
      map['movie_id'] = Variable<String>(movieId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (storageId.present) {
      map['storage_id'] = Variable<String>(storageId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (extension.present) {
      map['extension'] = Variable<String>(extension.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<BigInt>(fileSize.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (videoCodec.present) {
      map['video_codec'] = Variable<String>(videoCodec.value);
    }
    if (audioCodec.present) {
      map['audio_codec'] = Variable<String>(audioCodec.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (audioChannels.present) {
      map['audio_channels'] = Variable<String>(audioChannels.value);
    }
    if (subtitleInformation.present) {
      map['subtitle_information'] = Variable<String>(subtitleInformation.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<DateTime>(firstSeenAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (available.present) {
      map['available'] = Variable<bool>(available.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaSourcesCompanion(')
          ..write('id: $id, ')
          ..write('movieId: $movieId, ')
          ..write('episodeId: $episodeId, ')
          ..write('storageId: $storageId, ')
          ..write('sourceType: $sourceType, ')
          ..write('relativePath: $relativePath, ')
          ..write('filename: $filename, ')
          ..write('extension: $extension, ')
          ..write('fileSize: $fileSize, ')
          ..write('duration: $duration, ')
          ..write('videoCodec: $videoCodec, ')
          ..write('audioCodec: $audioCodec, ')
          ..write('resolution: $resolution, ')
          ..write('audioChannels: $audioChannels, ')
          ..write('subtitleInformation: $subtitleInformation, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('createdAt: $createdAt, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('available: $available, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransferJobsTable extends TransferJobs
    with TableInfo<$TransferJobsTable, TransferJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMediaSourceIdMeta =
      const VerificationMeta('sourceMediaSourceId');
  @override
  late final GeneratedColumn<String> sourceMediaSourceId =
      GeneratedColumn<String>(
        'source_media_source_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES media_sources (id)',
        ),
      );
  static const VerificationMeta _destinationStorageIdMeta =
      const VerificationMeta('destinationStorageId');
  @override
  late final GeneratedColumn<String> destinationStorageId =
      GeneratedColumn<String>(
        'destination_storage_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES storages (id)',
        ),
      );
  static const VerificationMeta _destinationRelativePathMeta =
      const VerificationMeta('destinationRelativePath');
  @override
  late final GeneratedColumn<String> destinationRelativePath =
      GeneratedColumn<String>(
        'destination_relative_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesTransferredMeta = const VerificationMeta(
    'bytesTransferred',
  );
  @override
  late final GeneratedColumn<BigInt> bytesTransferred = GeneratedColumn<BigInt>(
    'bytes_transferred',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
    defaultValue: Constant(BigInt.zero),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<BigInt> totalBytes = GeneratedColumn<BigInt>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaType,
    mediaId,
    sourceMediaSourceId,
    destinationStorageId,
    destinationRelativePath,
    status,
    bytesTransferred,
    totalBytes,
    error,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('source_media_source_id')) {
      context.handle(
        _sourceMediaSourceIdMeta,
        sourceMediaSourceId.isAcceptableOrUnknown(
          data['source_media_source_id']!,
          _sourceMediaSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceMediaSourceIdMeta);
    }
    if (data.containsKey('destination_storage_id')) {
      context.handle(
        _destinationStorageIdMeta,
        destinationStorageId.isAcceptableOrUnknown(
          data['destination_storage_id']!,
          _destinationStorageIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationStorageIdMeta);
    }
    if (data.containsKey('destination_relative_path')) {
      context.handle(
        _destinationRelativePathMeta,
        destinationRelativePath.isAcceptableOrUnknown(
          data['destination_relative_path']!,
          _destinationRelativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationRelativePathMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('bytes_transferred')) {
      context.handle(
        _bytesTransferredMeta,
        bytesTransferred.isAcceptableOrUnknown(
          data['bytes_transferred']!,
          _bytesTransferredMeta,
        ),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      sourceMediaSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_media_source_id'],
      )!,
      destinationStorageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_storage_id'],
      )!,
      destinationRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_relative_path'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      bytesTransferred: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}bytes_transferred'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}total_bytes'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $TransferJobsTable createAlias(String alias) {
    return $TransferJobsTable(attachedDatabase, alias);
  }
}

class TransferJob extends DataClass implements Insertable<TransferJob> {
  final String id;
  final String mediaType;
  final String mediaId;
  final String sourceMediaSourceId;
  final String destinationStorageId;
  final String destinationRelativePath;
  final String status;
  final BigInt bytesTransferred;
  final BigInt totalBytes;
  final String? error;
  final DateTime startedAt;
  final DateTime? completedAt;
  const TransferJob({
    required this.id,
    required this.mediaType,
    required this.mediaId,
    required this.sourceMediaSourceId,
    required this.destinationStorageId,
    required this.destinationRelativePath,
    required this.status,
    required this.bytesTransferred,
    required this.totalBytes,
    this.error,
    required this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['media_type'] = Variable<String>(mediaType);
    map['media_id'] = Variable<String>(mediaId);
    map['source_media_source_id'] = Variable<String>(sourceMediaSourceId);
    map['destination_storage_id'] = Variable<String>(destinationStorageId);
    map['destination_relative_path'] = Variable<String>(
      destinationRelativePath,
    );
    map['status'] = Variable<String>(status);
    map['bytes_transferred'] = Variable<BigInt>(bytesTransferred);
    map['total_bytes'] = Variable<BigInt>(totalBytes);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  TransferJobsCompanion toCompanion(bool nullToAbsent) {
    return TransferJobsCompanion(
      id: Value(id),
      mediaType: Value(mediaType),
      mediaId: Value(mediaId),
      sourceMediaSourceId: Value(sourceMediaSourceId),
      destinationStorageId: Value(destinationStorageId),
      destinationRelativePath: Value(destinationRelativePath),
      status: Value(status),
      bytesTransferred: Value(bytesTransferred),
      totalBytes: Value(totalBytes),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory TransferJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferJob(
      id: serializer.fromJson<String>(json['id']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      sourceMediaSourceId: serializer.fromJson<String>(
        json['sourceMediaSourceId'],
      ),
      destinationStorageId: serializer.fromJson<String>(
        json['destinationStorageId'],
      ),
      destinationRelativePath: serializer.fromJson<String>(
        json['destinationRelativePath'],
      ),
      status: serializer.fromJson<String>(json['status']),
      bytesTransferred: serializer.fromJson<BigInt>(json['bytesTransferred']),
      totalBytes: serializer.fromJson<BigInt>(json['totalBytes']),
      error: serializer.fromJson<String?>(json['error']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mediaType': serializer.toJson<String>(mediaType),
      'mediaId': serializer.toJson<String>(mediaId),
      'sourceMediaSourceId': serializer.toJson<String>(sourceMediaSourceId),
      'destinationStorageId': serializer.toJson<String>(destinationStorageId),
      'destinationRelativePath': serializer.toJson<String>(
        destinationRelativePath,
      ),
      'status': serializer.toJson<String>(status),
      'bytesTransferred': serializer.toJson<BigInt>(bytesTransferred),
      'totalBytes': serializer.toJson<BigInt>(totalBytes),
      'error': serializer.toJson<String?>(error),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  TransferJob copyWith({
    String? id,
    String? mediaType,
    String? mediaId,
    String? sourceMediaSourceId,
    String? destinationStorageId,
    String? destinationRelativePath,
    String? status,
    BigInt? bytesTransferred,
    BigInt? totalBytes,
    Value<String?> error = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => TransferJob(
    id: id ?? this.id,
    mediaType: mediaType ?? this.mediaType,
    mediaId: mediaId ?? this.mediaId,
    sourceMediaSourceId: sourceMediaSourceId ?? this.sourceMediaSourceId,
    destinationStorageId: destinationStorageId ?? this.destinationStorageId,
    destinationRelativePath:
        destinationRelativePath ?? this.destinationRelativePath,
    status: status ?? this.status,
    bytesTransferred: bytesTransferred ?? this.bytesTransferred,
    totalBytes: totalBytes ?? this.totalBytes,
    error: error.present ? error.value : this.error,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  TransferJob copyWithCompanion(TransferJobsCompanion data) {
    return TransferJob(
      id: data.id.present ? data.id.value : this.id,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      sourceMediaSourceId: data.sourceMediaSourceId.present
          ? data.sourceMediaSourceId.value
          : this.sourceMediaSourceId,
      destinationStorageId: data.destinationStorageId.present
          ? data.destinationStorageId.value
          : this.destinationStorageId,
      destinationRelativePath: data.destinationRelativePath.present
          ? data.destinationRelativePath.value
          : this.destinationRelativePath,
      status: data.status.present ? data.status.value : this.status,
      bytesTransferred: data.bytesTransferred.present
          ? data.bytesTransferred.value
          : this.bytesTransferred,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      error: data.error.present ? data.error.value : this.error,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferJob(')
          ..write('id: $id, ')
          ..write('mediaType: $mediaType, ')
          ..write('mediaId: $mediaId, ')
          ..write('sourceMediaSourceId: $sourceMediaSourceId, ')
          ..write('destinationStorageId: $destinationStorageId, ')
          ..write('destinationRelativePath: $destinationRelativePath, ')
          ..write('status: $status, ')
          ..write('bytesTransferred: $bytesTransferred, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('error: $error, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaType,
    mediaId,
    sourceMediaSourceId,
    destinationStorageId,
    destinationRelativePath,
    status,
    bytesTransferred,
    totalBytes,
    error,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferJob &&
          other.id == this.id &&
          other.mediaType == this.mediaType &&
          other.mediaId == this.mediaId &&
          other.sourceMediaSourceId == this.sourceMediaSourceId &&
          other.destinationStorageId == this.destinationStorageId &&
          other.destinationRelativePath == this.destinationRelativePath &&
          other.status == this.status &&
          other.bytesTransferred == this.bytesTransferred &&
          other.totalBytes == this.totalBytes &&
          other.error == this.error &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class TransferJobsCompanion extends UpdateCompanion<TransferJob> {
  final Value<String> id;
  final Value<String> mediaType;
  final Value<String> mediaId;
  final Value<String> sourceMediaSourceId;
  final Value<String> destinationStorageId;
  final Value<String> destinationRelativePath;
  final Value<String> status;
  final Value<BigInt> bytesTransferred;
  final Value<BigInt> totalBytes;
  final Value<String?> error;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const TransferJobsCompanion({
    this.id = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.sourceMediaSourceId = const Value.absent(),
    this.destinationStorageId = const Value.absent(),
    this.destinationRelativePath = const Value.absent(),
    this.status = const Value.absent(),
    this.bytesTransferred = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.error = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferJobsCompanion.insert({
    required String id,
    required String mediaType,
    required String mediaId,
    required String sourceMediaSourceId,
    required String destinationStorageId,
    required String destinationRelativePath,
    required String status,
    this.bytesTransferred = const Value.absent(),
    required BigInt totalBytes,
    this.error = const Value.absent(),
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mediaType = Value(mediaType),
       mediaId = Value(mediaId),
       sourceMediaSourceId = Value(sourceMediaSourceId),
       destinationStorageId = Value(destinationStorageId),
       destinationRelativePath = Value(destinationRelativePath),
       status = Value(status),
       totalBytes = Value(totalBytes),
       startedAt = Value(startedAt);
  static Insertable<TransferJob> custom({
    Expression<String>? id,
    Expression<String>? mediaType,
    Expression<String>? mediaId,
    Expression<String>? sourceMediaSourceId,
    Expression<String>? destinationStorageId,
    Expression<String>? destinationRelativePath,
    Expression<String>? status,
    Expression<BigInt>? bytesTransferred,
    Expression<BigInt>? totalBytes,
    Expression<String>? error,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaType != null) 'media_type': mediaType,
      if (mediaId != null) 'media_id': mediaId,
      if (sourceMediaSourceId != null)
        'source_media_source_id': sourceMediaSourceId,
      if (destinationStorageId != null)
        'destination_storage_id': destinationStorageId,
      if (destinationRelativePath != null)
        'destination_relative_path': destinationRelativePath,
      if (status != null) 'status': status,
      if (bytesTransferred != null) 'bytes_transferred': bytesTransferred,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (error != null) 'error': error,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? mediaType,
    Value<String>? mediaId,
    Value<String>? sourceMediaSourceId,
    Value<String>? destinationStorageId,
    Value<String>? destinationRelativePath,
    Value<String>? status,
    Value<BigInt>? bytesTransferred,
    Value<BigInt>? totalBytes,
    Value<String?>? error,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return TransferJobsCompanion(
      id: id ?? this.id,
      mediaType: mediaType ?? this.mediaType,
      mediaId: mediaId ?? this.mediaId,
      sourceMediaSourceId: sourceMediaSourceId ?? this.sourceMediaSourceId,
      destinationStorageId: destinationStorageId ?? this.destinationStorageId,
      destinationRelativePath:
          destinationRelativePath ?? this.destinationRelativePath,
      status: status ?? this.status,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (sourceMediaSourceId.present) {
      map['source_media_source_id'] = Variable<String>(
        sourceMediaSourceId.value,
      );
    }
    if (destinationStorageId.present) {
      map['destination_storage_id'] = Variable<String>(
        destinationStorageId.value,
      );
    }
    if (destinationRelativePath.present) {
      map['destination_relative_path'] = Variable<String>(
        destinationRelativePath.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (bytesTransferred.present) {
      map['bytes_transferred'] = Variable<BigInt>(bytesTransferred.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<BigInt>(totalBytes.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferJobsCompanion(')
          ..write('id: $id, ')
          ..write('mediaType: $mediaType, ')
          ..write('mediaId: $mediaId, ')
          ..write('sourceMediaSourceId: $sourceMediaSourceId, ')
          ..write('destinationStorageId: $destinationStorageId, ')
          ..write('destinationRelativePath: $destinationRelativePath, ')
          ..write('status: $status, ')
          ..write('bytesTransferred: $bytesTransferred, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('error: $error, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, Collection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    overview,
    posterPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Collection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Collection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class Collection extends DataClass implements Insertable<Collection> {
  final String id;
  final String name;
  final String? overview;
  final String? posterPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Collection({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      name: Value(name),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Collection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'overview': serializer.toJson<String?>(overview),
      'posterPath': serializer.toJson<String?>(posterPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Collection copyWith({
    String? id,
    String? name,
    Value<String?> overview = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Collection(
    id: id ?? this.id,
    name: name ?? this.name,
    overview: overview.present ? overview.value : this.overview,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Collection copyWithCompanion(CollectionsCompanion data) {
    return Collection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, overview, posterPath, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.id == this.id &&
          other.name == this.name &&
          other.overview == this.overview &&
          other.posterPath == this.posterPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CollectionsCompanion extends UpdateCompanion<Collection> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> overview;
  final Value<String?> posterPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionsCompanion.insert({
    required String id,
    required String name,
    this.overview = const Value.absent(),
    this.posterPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Collection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? overview,
    Expression<String>? posterPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (overview != null) 'overview': overview,
      if (posterPath != null) 'poster_path': posterPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? overview,
    Value<String?>? posterPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('overview: $overview, ')
          ..write('posterPath: $posterPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionItemsTable extends CollectionItems
    with TableInfo<$CollectionItemsTable, CollectionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES collections (id)',
    ),
  );
  static const VerificationMeta _movieIdMeta = const VerificationMeta(
    'movieId',
  );
  @override
  late final GeneratedColumn<String> movieId = GeneratedColumn<String>(
    'movie_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES movies (id)',
    ),
  );
  static const VerificationMeta _tvShowIdMeta = const VerificationMeta(
    'tvShowId',
  );
  @override
  late final GeneratedColumn<String> tvShowId = GeneratedColumn<String>(
    'tv_show_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tv_shows (id)',
    ),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collectionId,
    movieId,
    tvShowId,
    displayOrder,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('movie_id')) {
      context.handle(
        _movieIdMeta,
        movieId.isAcceptableOrUnknown(data['movie_id']!, _movieIdMeta),
      );
    }
    if (data.containsKey('tv_show_id')) {
      context.handle(
        _tvShowIdMeta,
        tvShowId.isAcceptableOrUnknown(data['tv_show_id']!, _tvShowIdMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      movieId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movie_id'],
      ),
      tvShowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tv_show_id'],
      ),
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $CollectionItemsTable createAlias(String alias) {
    return $CollectionItemsTable(attachedDatabase, alias);
  }
}

class CollectionItem extends DataClass implements Insertable<CollectionItem> {
  final String id;
  final String collectionId;
  final String? movieId;
  final String? tvShowId;
  final int displayOrder;
  final DateTime addedAt;
  const CollectionItem({
    required this.id,
    required this.collectionId,
    this.movieId,
    this.tvShowId,
    required this.displayOrder,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['collection_id'] = Variable<String>(collectionId);
    if (!nullToAbsent || movieId != null) {
      map['movie_id'] = Variable<String>(movieId);
    }
    if (!nullToAbsent || tvShowId != null) {
      map['tv_show_id'] = Variable<String>(tvShowId);
    }
    map['display_order'] = Variable<int>(displayOrder);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  CollectionItemsCompanion toCompanion(bool nullToAbsent) {
    return CollectionItemsCompanion(
      id: Value(id),
      collectionId: Value(collectionId),
      movieId: movieId == null && nullToAbsent
          ? const Value.absent()
          : Value(movieId),
      tvShowId: tvShowId == null && nullToAbsent
          ? const Value.absent()
          : Value(tvShowId),
      displayOrder: Value(displayOrder),
      addedAt: Value(addedAt),
    );
  }

  factory CollectionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionItem(
      id: serializer.fromJson<String>(json['id']),
      collectionId: serializer.fromJson<String>(json['collectionId']),
      movieId: serializer.fromJson<String?>(json['movieId']),
      tvShowId: serializer.fromJson<String?>(json['tvShowId']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'collectionId': serializer.toJson<String>(collectionId),
      'movieId': serializer.toJson<String?>(movieId),
      'tvShowId': serializer.toJson<String?>(tvShowId),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  CollectionItem copyWith({
    String? id,
    String? collectionId,
    Value<String?> movieId = const Value.absent(),
    Value<String?> tvShowId = const Value.absent(),
    int? displayOrder,
    DateTime? addedAt,
  }) => CollectionItem(
    id: id ?? this.id,
    collectionId: collectionId ?? this.collectionId,
    movieId: movieId.present ? movieId.value : this.movieId,
    tvShowId: tvShowId.present ? tvShowId.value : this.tvShowId,
    displayOrder: displayOrder ?? this.displayOrder,
    addedAt: addedAt ?? this.addedAt,
  );
  CollectionItem copyWithCompanion(CollectionItemsCompanion data) {
    return CollectionItem(
      id: data.id.present ? data.id.value : this.id,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      movieId: data.movieId.present ? data.movieId.value : this.movieId,
      tvShowId: data.tvShowId.present ? data.tvShowId.value : this.tvShowId,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItem(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('movieId: $movieId, ')
          ..write('tvShowId: $tvShowId, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, collectionId, movieId, tvShowId, displayOrder, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionItem &&
          other.id == this.id &&
          other.collectionId == this.collectionId &&
          other.movieId == this.movieId &&
          other.tvShowId == this.tvShowId &&
          other.displayOrder == this.displayOrder &&
          other.addedAt == this.addedAt);
}

class CollectionItemsCompanion extends UpdateCompanion<CollectionItem> {
  final Value<String> id;
  final Value<String> collectionId;
  final Value<String?> movieId;
  final Value<String?> tvShowId;
  final Value<int> displayOrder;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const CollectionItemsCompanion({
    this.id = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.movieId = const Value.absent(),
    this.tvShowId = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionItemsCompanion.insert({
    required String id,
    required String collectionId,
    this.movieId = const Value.absent(),
    this.tvShowId = const Value.absent(),
    this.displayOrder = const Value.absent(),
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       collectionId = Value(collectionId),
       addedAt = Value(addedAt);
  static Insertable<CollectionItem> custom({
    Expression<String>? id,
    Expression<String>? collectionId,
    Expression<String>? movieId,
    Expression<String>? tvShowId,
    Expression<int>? displayOrder,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionId != null) 'collection_id': collectionId,
      if (movieId != null) 'movie_id': movieId,
      if (tvShowId != null) 'tv_show_id': tvShowId,
      if (displayOrder != null) 'display_order': displayOrder,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? collectionId,
    Value<String?>? movieId,
    Value<String?>? tvShowId,
    Value<int>? displayOrder,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return CollectionItemsCompanion(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      movieId: movieId ?? this.movieId,
      tvShowId: tvShowId ?? this.tvShowId,
      displayOrder: displayOrder ?? this.displayOrder,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (movieId.present) {
      map['movie_id'] = Variable<String>(movieId.value);
    }
    if (tvShowId.present) {
      map['tv_show_id'] = Variable<String>(tvShowId.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItemsCompanion(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('movieId: $movieId, ')
          ..write('tvShowId: $tvShowId, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StoragesTable storages = $StoragesTable(this);
  late final $MoviesTable movies = $MoviesTable(this);
  late final $TvShowsTable tvShows = $TvShowsTable(this);
  late final $SeasonsTable seasons = $SeasonsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $MediaSourcesTable mediaSources = $MediaSourcesTable(this);
  late final $TransferJobsTable transferJobs = $TransferJobsTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $CollectionItemsTable collectionItems = $CollectionItemsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    storages,
    movies,
    tvShows,
    seasons,
    episodes,
    mediaSources,
    transferJobs,
    collections,
    collectionItems,
  ];
}

typedef $$StoragesTableCreateCompanionBuilder = StoragesCompanion Function({
  required String id,
  required String name,
  required String storageType,
  required String filesystemIdentifier,
  required String rootUri,
  required DateTime lastSeenAt,
  Value<bool> available,
  Value<int> rowid,
});
typedef $$StoragesTableUpdateCompanionBuilder = StoragesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> storageType,
  Value<String> filesystemIdentifier,
  Value<String> rootUri,
  Value<DateTime> lastSeenAt,
  Value<bool> available,
  Value<int> rowid,
});

final class $$StoragesTableReferences
    extends BaseReferences<_$AppDatabase, $StoragesTable, Storage> {
  $$StoragesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaSourcesTable, List<MediaSource>>
  _mediaSourcesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaSources,
    aliasName: 'storages__id__media_sources__storage_id',
  );

  $$MediaSourcesTableProcessedTableManager get mediaSourcesRefs {
    final manager = $$MediaSourcesTableTableManager(
      $_db,
      $_db.mediaSources,
    ).filter((f) => f.storageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaSourcesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransferJobsTable, List<TransferJob>>
  _transferJobsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transferJobs,
    aliasName: 'storages__id__transfer_jobs__destination_storage_id',
  );

  $$TransferJobsTableProcessedTableManager get transferJobsRefs {
    final manager = $$TransferJobsTableTableManager($_db, $_db.transferJobs)
        .filter(
          (f) =>
              f.destinationStorageId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_transferJobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoragesTableFilterComposer
    extends Composer<_$AppDatabase, $StoragesTable> {
  $$StoragesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageType => $composableBuilder(
    column: $table.storageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filesystemIdentifier => $composableBuilder(
    column: $table.filesystemIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootUri => $composableBuilder(
    column: $table.rootUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaSourcesRefs(
    Expression<bool> Function($$MediaSourcesTableFilterComposer f) f,
  ) {
    final $$MediaSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaSources,
      getReferencedColumn: (t) => t.storageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaSourcesTableFilterComposer(
            $db: $db,
            $table: $db.mediaSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transferJobsRefs(
    Expression<bool> Function($$TransferJobsTableFilterComposer f) f,
  ) {
    final $$TransferJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transferJobs,
      getReferencedColumn: (t) => t.destinationStorageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferJobsTableFilterComposer(
            $db: $db,
            $table: $db.transferJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoragesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoragesTable> {
  $$StoragesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageType => $composableBuilder(
    column: $table.storageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filesystemIdentifier => $composableBuilder(
    column: $table.filesystemIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootUri => $composableBuilder(
    column: $table.rootUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoragesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoragesTable> {
  $$StoragesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get storageType => $composableBuilder(
    column: $table.storageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filesystemIdentifier => $composableBuilder(
    column: $table.filesystemIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rootUri =>
      $composableBuilder(column: $table.rootUri, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get available =>
      $composableBuilder(column: $table.available, builder: (column) => column);

  Expression<T> mediaSourcesRefs<T extends Object>(
    Expression<T> Function($$MediaSourcesTableAnnotationComposer a) f,
  ) {
    final $$MediaSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaSources,
      getReferencedColumn: (t) => t.storageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transferJobsRefs<T extends Object>(
    Expression<T> Function($$TransferJobsTableAnnotationComposer a) f,
  ) {
    final $$TransferJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transferJobs,
      getReferencedColumn: (t) => t.destinationStorageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.transferJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoragesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoragesTable,
          Storage,
          $$StoragesTableFilterComposer,
          $$StoragesTableOrderingComposer,
          $$StoragesTableAnnotationComposer,
          $$StoragesTableCreateCompanionBuilder,
          $$StoragesTableUpdateCompanionBuilder,
          (Storage, $$StoragesTableReferences),
          Storage,
          PrefetchHooks Function({bool mediaSourcesRefs, bool transferJobsRefs})
        > {
  $$StoragesTableTableManager(_$AppDatabase db, $StoragesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoragesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoragesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoragesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> storageType = const Value.absent(),
                Value<String> filesystemIdentifier = const Value.absent(),
                Value<String> rootUri = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<bool> available = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoragesCompanion(
                id: id,
                name: name,
                storageType: storageType,
                filesystemIdentifier: filesystemIdentifier,
                rootUri: rootUri,
                lastSeenAt: lastSeenAt,
                available: available,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String storageType,
                required String filesystemIdentifier,
                required String rootUri,
                required DateTime lastSeenAt,
                Value<bool> available = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoragesCompanion.insert(
                id: id,
                name: name,
                storageType: storageType,
                filesystemIdentifier: filesystemIdentifier,
                rootUri: rootUri,
                lastSeenAt: lastSeenAt,
                available: available,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoragesTable, Storage>(table),
                  $$StoragesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({mediaSourcesRefs = false, transferJobsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaSourcesRefs) db.mediaSources,
                    if (transferJobsRefs) db.transferJobs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaSourcesRefs)
                        await $_getPrefetchedData<
                          Storage,
                          $StoragesTable,
                          MediaSource
                        >(
                          currentTable: table,
                          referencedTable: $$StoragesTableReferences
                              ._mediaSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoragesTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transferJobsRefs)
                        await $_getPrefetchedData<
                          Storage,
                          $StoragesTable,
                          TransferJob
                        >(
                          currentTable: table,
                          referencedTable: $$StoragesTableReferences
                              ._transferJobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoragesTableReferences(
                                db,
                                table,
                                p0,
                              ).transferJobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.destinationStorageId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StoragesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoragesTable,
      Storage,
      $$StoragesTableFilterComposer,
      $$StoragesTableOrderingComposer,
      $$StoragesTableAnnotationComposer,
      $$StoragesTableCreateCompanionBuilder,
      $$StoragesTableUpdateCompanionBuilder,
      (Storage, $$StoragesTableReferences),
      Storage,
      PrefetchHooks Function({bool mediaSourcesRefs, bool transferJobsRefs})
    >;
typedef $$MoviesTableCreateCompanionBuilder = MoviesCompanion Function({
  required String id,
  Value<String?> metadataId,
  required String title,
  Value<String?> originalTitle,
  Value<int?> year,
  Value<String?> overview,
  Value<int?> runtime,
  Value<DateTime?> releaseDate,
  Value<String?> posterPath,
  Value<String?> backdropPath,
  Value<double?> rating,
  Value<int?> voteCount,
  Value<String?> imdbId,
  Value<int?> tmdbId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> isFavorite,
  Value<bool> isWatchlist,
  Value<String> watchState,
  Value<int> playbackPositionSeconds,
  Value<int> rowid,
});
typedef $$MoviesTableUpdateCompanionBuilder = MoviesCompanion Function({
  Value<String> id,
  Value<String?> metadataId,
  Value<String> title,
  Value<String?> originalTitle,
  Value<int?> year,
  Value<String?> overview,
  Value<int?> runtime,
  Value<DateTime?> releaseDate,
  Value<String?> posterPath,
  Value<String?> backdropPath,
  Value<double?> rating,
  Value<int?> voteCount,
  Value<String?> imdbId,
  Value<int?> tmdbId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isFavorite,
  Value<bool> isWatchlist,
  Value<String> watchState,
  Value<int> playbackPositionSeconds,
  Value<int> rowid,
});

final class $$MoviesTableReferences
    extends BaseReferences<_$AppDatabase, $MoviesTable, Movie> {
  $$MoviesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaSourcesTable, List<MediaSource>>
  _mediaSourcesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaSources,
    aliasName: 'movies__id__media_sources__movie_id',
  );

  $$MediaSourcesTableProcessedTableManager get mediaSourcesRefs {
    final manager = $$MediaSourcesTableTableManager(
      $_db,
      $_db.mediaSources,
    ).filter((f) => f.movieId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaSourcesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CollectionItemsTable, List<CollectionItem>>
  _collectionItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.collectionItems,
    aliasName: 'movies__id__collection_items__movie_id',
  );

  $$CollectionItemsTableProcessedTableManager get collectionItemsRefs {
    final manager = $$CollectionItemsTableTableManager(
      $_db,
      $_db.collectionItems,
    ).filter((f) => f.movieId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MoviesTableFilterComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataId => $composableBuilder(
    column: $table.metadataId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtime => $composableBuilder(
    column: $table.runtime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get voteCount => $composableBuilder(
    column: $table.voteCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWatchlist => $composableBuilder(
    column: $table.isWatchlist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get watchState => $composableBuilder(
    column: $table.watchState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playbackPositionSeconds => $composableBuilder(
    column: $table.playbackPositionSeconds,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaSourcesRefs(
    Expression<bool> Function($$MediaSourcesTableFilterComposer f) f,
  ) {
    final $$MediaSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaSources,
      getReferencedColumn: (t) => t.movieId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaSourcesTableFilterComposer(
            $db: $db,
            $table: $db.mediaSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> collectionItemsRefs(
    Expression<bool> Function($$CollectionItemsTableFilterComposer f) f,
  ) {
    final $$CollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.movieId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MoviesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataId => $composableBuilder(
    column: $table.metadataId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtime => $composableBuilder(
    column: $table.runtime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get voteCount => $composableBuilder(
    column: $table.voteCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWatchlist => $composableBuilder(
    column: $table.isWatchlist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get watchState => $composableBuilder(
    column: $table.watchState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playbackPositionSeconds => $composableBuilder(
    column: $table.playbackPositionSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoviesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metadataId => $composableBuilder(
    column: $table.metadataId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<int> get runtime =>
      $composableBuilder(column: $table.runtime, builder: (column) => column);

  GeneratedColumn<DateTime> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get voteCount =>
      $composableBuilder(column: $table.voteCount, builder: (column) => column);

  GeneratedColumn<String> get imdbId =>
      $composableBuilder(column: $table.imdbId, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWatchlist => $composableBuilder(
    column: $table.isWatchlist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get watchState => $composableBuilder(
    column: $table.watchState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playbackPositionSeconds => $composableBuilder(
    column: $table.playbackPositionSeconds,
    builder: (column) => column,
  );

  Expression<T> mediaSourcesRefs<T extends Object>(
    Expression<T> Function($$MediaSourcesTableAnnotationComposer a) f,
  ) {
    final $$MediaSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaSources,
      getReferencedColumn: (t) => t.movieId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> collectionItemsRefs<T extends Object>(
    Expression<T> Function($$CollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$CollectionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.movieId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MoviesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoviesTable,
          Movie,
          $$MoviesTableFilterComposer,
          $$MoviesTableOrderingComposer,
          $$MoviesTableAnnotationComposer,
          $$MoviesTableCreateCompanionBuilder,
          $$MoviesTableUpdateCompanionBuilder,
          (Movie, $$MoviesTableReferences),
          Movie,
          PrefetchHooks Function({
            bool mediaSourcesRefs,
            bool collectionItemsRefs,
          })
        > {
  $$MoviesTableTableManager(_$AppDatabase db, $MoviesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> metadataId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<int?> runtime = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> voteCount = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isWatchlist = const Value.absent(),
                Value<String> watchState = const Value.absent(),
                Value<int> playbackPositionSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion(
                id: id,
                metadataId: metadataId,
                title: title,
                originalTitle: originalTitle,
                year: year,
                overview: overview,
                runtime: runtime,
                releaseDate: releaseDate,
                posterPath: posterPath,
                backdropPath: backdropPath,
                rating: rating,
                voteCount: voteCount,
                imdbId: imdbId,
                tmdbId: tmdbId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isFavorite: isFavorite,
                isWatchlist: isWatchlist,
                watchState: watchState,
                playbackPositionSeconds: playbackPositionSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> metadataId = const Value.absent(),
                required String title,
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<int?> runtime = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> voteCount = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isWatchlist = const Value.absent(),
                Value<String> watchState = const Value.absent(),
                Value<int> playbackPositionSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion.insert(
                id: id,
                metadataId: metadataId,
                title: title,
                originalTitle: originalTitle,
                year: year,
                overview: overview,
                runtime: runtime,
                releaseDate: releaseDate,
                posterPath: posterPath,
                backdropPath: backdropPath,
                rating: rating,
                voteCount: voteCount,
                imdbId: imdbId,
                tmdbId: tmdbId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isFavorite: isFavorite,
                isWatchlist: isWatchlist,
                watchState: watchState,
                playbackPositionSeconds: playbackPositionSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MoviesTable, Movie>(table),
                  $$MoviesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({mediaSourcesRefs = false, collectionItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaSourcesRefs) db.mediaSources,
                    if (collectionItemsRefs) db.collectionItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaSourcesRefs)
                        await $_getPrefetchedData<
                          Movie,
                          $MoviesTable,
                          MediaSource
                        >(
                          currentTable: table,
                          referencedTable: $$MoviesTableReferences
                              ._mediaSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MoviesTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.movieId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (collectionItemsRefs)
                        await $_getPrefetchedData<
                          Movie,
                          $MoviesTable,
                          CollectionItem
                        >(
                          currentTable: table,
                          referencedTable: $$MoviesTableReferences
                              ._collectionItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MoviesTableReferences(
                                db,
                                table,
                                p0,
                              ).collectionItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.movieId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MoviesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoviesTable,
      Movie,
      $$MoviesTableFilterComposer,
      $$MoviesTableOrderingComposer,
      $$MoviesTableAnnotationComposer,
      $$MoviesTableCreateCompanionBuilder,
      $$MoviesTableUpdateCompanionBuilder,
      (Movie, $$MoviesTableReferences),
      Movie,
      PrefetchHooks Function({bool mediaSourcesRefs, bool collectionItemsRefs})
    >;
typedef $$TvShowsTableCreateCompanionBuilder = TvShowsCompanion Function({
  required String id,
  Value<String?> metadataId,
  required String title,
  Value<String?> originalTitle,
  Value<String?> overview,
  Value<DateTime?> firstAirDate,
  Value<String?> posterPath,
  Value<String?> backdropPath,
  Value<double?> rating,
  Value<int?> tmdbId,
  Value<String?> imdbId,
  Value<bool> isFavorite,
  Value<bool> isWatchlist,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TvShowsTableUpdateCompanionBuilder = TvShowsCompanion Function({
  Value<String> id,
  Value<String?> metadataId,
  Value<String> title,
  Value<String?> originalTitle,
  Value<String?> overview,
  Value<DateTime?> firstAirDate,
  Value<String?> posterPath,
  Value<String?> backdropPath,
  Value<double?> rating,
  Value<int?> tmdbId,
  Value<String?> imdbId,
  Value<bool> isFavorite,
  Value<bool> isWatchlist,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$TvShowsTableReferences
    extends BaseReferences<_$AppDatabase, $TvShowsTable, TvShow> {
  $$TvShowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SeasonsTable, List<Season>> _seasonsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.seasons,
    aliasName: 'tv_shows__id__seasons__show_id',
  );

  $$SeasonsTableProcessedTableManager get seasonsRefs {
    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.showId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_seasonsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CollectionItemsTable, List<CollectionItem>>
  _collectionItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.collectionItems,
    aliasName: 'tv_shows__id__collection_items__tv_show_id',
  );

  $$CollectionItemsTableProcessedTableManager get collectionItemsRefs {
    final manager = $$CollectionItemsTableTableManager(
      $_db,
      $_db.collectionItems,
    ).filter((f) => f.tvShowId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TvShowsTableFilterComposer
    extends Composer<_$AppDatabase, $TvShowsTable> {
  $$TvShowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataId => $composableBuilder(
    column: $table.metadataId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstAirDate => $composableBuilder(
    column: $table.firstAirDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWatchlist => $composableBuilder(
    column: $table.isWatchlist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> seasonsRefs(
    Expression<bool> Function($$SeasonsTableFilterComposer f) f,
  ) {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.showId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> collectionItemsRefs(
    Expression<bool> Function($$CollectionItemsTableFilterComposer f) f,
  ) {
    final $$CollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.tvShowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TvShowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TvShowsTable> {
  $$TvShowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataId => $composableBuilder(
    column: $table.metadataId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstAirDate => $composableBuilder(
    column: $table.firstAirDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWatchlist => $composableBuilder(
    column: $table.isWatchlist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TvShowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TvShowsTable> {
  $$TvShowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get metadataId => $composableBuilder(
    column: $table.metadataId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<DateTime> get firstAirDate => $composableBuilder(
    column: $table.firstAirDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backdropPath => $composableBuilder(
    column: $table.backdropPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get imdbId =>
      $composableBuilder(column: $table.imdbId, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isWatchlist => $composableBuilder(
    column: $table.isWatchlist,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> seasonsRefs<T extends Object>(
    Expression<T> Function($$SeasonsTableAnnotationComposer a) f,
  ) {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.showId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> collectionItemsRefs<T extends Object>(
    Expression<T> Function($$CollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$CollectionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.tvShowId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TvShowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TvShowsTable,
          TvShow,
          $$TvShowsTableFilterComposer,
          $$TvShowsTableOrderingComposer,
          $$TvShowsTableAnnotationComposer,
          $$TvShowsTableCreateCompanionBuilder,
          $$TvShowsTableUpdateCompanionBuilder,
          (TvShow, $$TvShowsTableReferences),
          TvShow,
          PrefetchHooks Function({bool seasonsRefs, bool collectionItemsRefs})
        > {
  $$TvShowsTableTableManager(_$AppDatabase db, $TvShowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TvShowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TvShowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TvShowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> metadataId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalTitle = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<DateTime?> firstAirDate = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isWatchlist = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TvShowsCompanion(
                id: id,
                metadataId: metadataId,
                title: title,
                originalTitle: originalTitle,
                overview: overview,
                firstAirDate: firstAirDate,
                posterPath: posterPath,
                backdropPath: backdropPath,
                rating: rating,
                tmdbId: tmdbId,
                imdbId: imdbId,
                isFavorite: isFavorite,
                isWatchlist: isWatchlist,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> metadataId = const Value.absent(),
                required String title,
                Value<String?> originalTitle = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<DateTime?> firstAirDate = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> backdropPath = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isWatchlist = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TvShowsCompanion.insert(
                id: id,
                metadataId: metadataId,
                title: title,
                originalTitle: originalTitle,
                overview: overview,
                firstAirDate: firstAirDate,
                posterPath: posterPath,
                backdropPath: backdropPath,
                rating: rating,
                tmdbId: tmdbId,
                imdbId: imdbId,
                isFavorite: isFavorite,
                isWatchlist: isWatchlist,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TvShowsTable, TvShow>(table),
                  $$TvShowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({seasonsRefs = false, collectionItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (seasonsRefs) db.seasons,
                    if (collectionItemsRefs) db.collectionItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (seasonsRefs)
                        await $_getPrefetchedData<
                          TvShow,
                          $TvShowsTable,
                          Season
                        >(
                          currentTable: table,
                          referencedTable: $$TvShowsTableReferences
                              ._seasonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TvShowsTableReferences(
                                db,
                                table,
                                p0,
                              ).seasonsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.showId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (collectionItemsRefs)
                        await $_getPrefetchedData<
                          TvShow,
                          $TvShowsTable,
                          CollectionItem
                        >(
                          currentTable: table,
                          referencedTable: $$TvShowsTableReferences
                              ._collectionItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TvShowsTableReferences(
                                db,
                                table,
                                p0,
                              ).collectionItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tvShowId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TvShowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TvShowsTable,
      TvShow,
      $$TvShowsTableFilterComposer,
      $$TvShowsTableOrderingComposer,
      $$TvShowsTableAnnotationComposer,
      $$TvShowsTableCreateCompanionBuilder,
      $$TvShowsTableUpdateCompanionBuilder,
      (TvShow, $$TvShowsTableReferences),
      TvShow,
      PrefetchHooks Function({bool seasonsRefs, bool collectionItemsRefs})
    >;
typedef $$SeasonsTableCreateCompanionBuilder = SeasonsCompanion Function({
  required String id,
  required String showId,
  required int seasonNumber,
  Value<String?> name,
  Value<String?> overview,
  Value<String?> posterPath,
  Value<DateTime?> airDate,
  Value<int?> tmdbId,
  Value<int> rowid,
});
typedef $$SeasonsTableUpdateCompanionBuilder = SeasonsCompanion Function({
  Value<String> id,
  Value<String> showId,
  Value<int> seasonNumber,
  Value<String?> name,
  Value<String?> overview,
  Value<String?> posterPath,
  Value<DateTime?> airDate,
  Value<int?> tmdbId,
  Value<int> rowid,
});

final class $$SeasonsTableReferences
    extends BaseReferences<_$AppDatabase, $SeasonsTable, Season> {
  $$SeasonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TvShowsTable _showIdTable(_$AppDatabase db) =>
      db.tvShows.createAlias('seasons__show_id__tv_shows__id');

  $$TvShowsTableProcessedTableManager get showId {
    final $_column = $_itemColumn<String>('show_id')!;

    final manager = $$TvShowsTableTableManager(
      $_db,
      $_db.tvShows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_showIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EpisodesTable, List<Episode>> _episodesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.episodes,
    aliasName: 'seasons__id__episodes__season_id',
  );

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.seasonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SeasonsTableFilterComposer
    extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get airDate => $composableBuilder(
    column: $table.airDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  $$TvShowsTableFilterComposer get showId {
    final $$TvShowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.showId,
      referencedTable: $db.tvShows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TvShowsTableFilterComposer(
            $db: $db,
            $table: $db.tvShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> episodesRefs(
    Expression<bool> Function($$EpisodesTableFilterComposer f) f,
  ) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.seasonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableFilterComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SeasonsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get airDate => $composableBuilder(
    column: $table.airDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  $$TvShowsTableOrderingComposer get showId {
    final $$TvShowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.showId,
      referencedTable: $db.tvShows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TvShowsTableOrderingComposer(
            $db: $db,
            $table: $db.tvShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeasonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  $$TvShowsTableAnnotationComposer get showId {
    final $$TvShowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.showId,
      referencedTable: $db.tvShows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TvShowsTableAnnotationComposer(
            $db: $db,
            $table: $db.tvShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> episodesRefs<T extends Object>(
    Expression<T> Function($$EpisodesTableAnnotationComposer a) f,
  ) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.seasonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SeasonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeasonsTable,
          Season,
          $$SeasonsTableFilterComposer,
          $$SeasonsTableOrderingComposer,
          $$SeasonsTableAnnotationComposer,
          $$SeasonsTableCreateCompanionBuilder,
          $$SeasonsTableUpdateCompanionBuilder,
          (Season, $$SeasonsTableReferences),
          Season,
          PrefetchHooks Function({bool showId, bool episodesRefs})
        > {
  $$SeasonsTableTableManager(_$AppDatabase db, $SeasonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> showId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeasonsCompanion(
                id: id,
                showId: showId,
                seasonNumber: seasonNumber,
                name: name,
                overview: overview,
                posterPath: posterPath,
                airDate: airDate,
                tmdbId: tmdbId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String showId,
                required int seasonNumber,
                Value<String?> name = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeasonsCompanion.insert(
                id: id,
                showId: showId,
                seasonNumber: seasonNumber,
                name: name,
                overview: overview,
                posterPath: posterPath,
                airDate: airDate,
                tmdbId: tmdbId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SeasonsTable, Season>(table),
                  $$SeasonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({showId = false, episodesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (episodesRefs) db.episodes],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (showId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.showId,
                        referencedTable: $$SeasonsTableReferences._showIdTable(
                          db,
                        ),
                        referencedColumn: $$SeasonsTableReferences
                            ._showIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (episodesRefs)
                    await $_getPrefetchedData<Season, $SeasonsTable, Episode>(
                      currentTable: table,
                      referencedTable: $$SeasonsTableReferences
                          ._episodesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SeasonsTableReferences(db, table, p0).episodesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.seasonId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeasonsTable,
      Season,
      $$SeasonsTableFilterComposer,
      $$SeasonsTableOrderingComposer,
      $$SeasonsTableAnnotationComposer,
      $$SeasonsTableCreateCompanionBuilder,
      $$SeasonsTableUpdateCompanionBuilder,
      (Season, $$SeasonsTableReferences),
      Season,
      PrefetchHooks Function({bool showId, bool episodesRefs})
    >;
typedef $$EpisodesTableCreateCompanionBuilder = EpisodesCompanion Function({
  required String id,
  required String seasonId,
  required int episodeNumber,
  Value<String?> name,
  Value<String?> overview,
  Value<DateTime?> airDate,
  Value<int?> runtime,
  Value<String?> stillPath,
  Value<double?> rating,
  Value<int?> tmdbId,
  Value<String> watchState,
  Value<int> playbackPositionSeconds,
  Value<int> rowid,
});
typedef $$EpisodesTableUpdateCompanionBuilder = EpisodesCompanion Function({
  Value<String> id,
  Value<String> seasonId,
  Value<int> episodeNumber,
  Value<String?> name,
  Value<String?> overview,
  Value<DateTime?> airDate,
  Value<int?> runtime,
  Value<String?> stillPath,
  Value<double?> rating,
  Value<int?> tmdbId,
  Value<String> watchState,
  Value<int> playbackPositionSeconds,
  Value<int> rowid,
});

final class $$EpisodesTableReferences
    extends BaseReferences<_$AppDatabase, $EpisodesTable, Episode> {
  $$EpisodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SeasonsTable _seasonIdTable(_$AppDatabase db) =>
      db.seasons.createAlias('episodes__season_id__seasons__id');

  $$SeasonsTableProcessedTableManager get seasonId {
    final $_column = $_itemColumn<String>('season_id')!;

    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seasonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MediaSourcesTable, List<MediaSource>>
  _mediaSourcesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaSources,
    aliasName: 'episodes__id__media_sources__episode_id',
  );

  $$MediaSourcesTableProcessedTableManager get mediaSourcesRefs {
    final manager = $$MediaSourcesTableTableManager(
      $_db,
      $_db.mediaSources,
    ).filter((f) => f.episodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaSourcesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get airDate => $composableBuilder(
    column: $table.airDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtime => $composableBuilder(
    column: $table.runtime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stillPath => $composableBuilder(
    column: $table.stillPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get watchState => $composableBuilder(
    column: $table.watchState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playbackPositionSeconds => $composableBuilder(
    column: $table.playbackPositionSeconds,
    builder: (column) => ColumnFilters(column),
  );

  $$SeasonsTableFilterComposer get seasonId {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seasonId,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> mediaSourcesRefs(
    Expression<bool> Function($$MediaSourcesTableFilterComposer f) f,
  ) {
    final $$MediaSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaSources,
      getReferencedColumn: (t) => t.episodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaSourcesTableFilterComposer(
            $db: $db,
            $table: $db.mediaSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get airDate => $composableBuilder(
    column: $table.airDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtime => $composableBuilder(
    column: $table.runtime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stillPath => $composableBuilder(
    column: $table.stillPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get watchState => $composableBuilder(
    column: $table.watchState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playbackPositionSeconds => $composableBuilder(
    column: $table.playbackPositionSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  $$SeasonsTableOrderingComposer get seasonId {
    final $$SeasonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seasonId,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableOrderingComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<DateTime> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => column);

  GeneratedColumn<int> get runtime =>
      $composableBuilder(column: $table.runtime, builder: (column) => column);

  GeneratedColumn<String> get stillPath =>
      $composableBuilder(column: $table.stillPath, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get watchState => $composableBuilder(
    column: $table.watchState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playbackPositionSeconds => $composableBuilder(
    column: $table.playbackPositionSeconds,
    builder: (column) => column,
  );

  $$SeasonsTableAnnotationComposer get seasonId {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seasonId,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> mediaSourcesRefs<T extends Object>(
    Expression<T> Function($$MediaSourcesTableAnnotationComposer a) f,
  ) {
    final $$MediaSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaSources,
      getReferencedColumn: (t) => t.episodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTable,
          Episode,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (Episode, $$EpisodesTableReferences),
          Episode,
          PrefetchHooks Function({bool seasonId, bool mediaSourcesRefs})
        > {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> seasonId = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
                Value<int?> runtime = const Value.absent(),
                Value<String?> stillPath = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String> watchState = const Value.absent(),
                Value<int> playbackPositionSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion(
                id: id,
                seasonId: seasonId,
                episodeNumber: episodeNumber,
                name: name,
                overview: overview,
                airDate: airDate,
                runtime: runtime,
                stillPath: stillPath,
                rating: rating,
                tmdbId: tmdbId,
                watchState: watchState,
                playbackPositionSeconds: playbackPositionSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String seasonId,
                required int episodeNumber,
                Value<String?> name = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
                Value<int?> runtime = const Value.absent(),
                Value<String?> stillPath = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> tmdbId = const Value.absent(),
                Value<String> watchState = const Value.absent(),
                Value<int> playbackPositionSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion.insert(
                id: id,
                seasonId: seasonId,
                episodeNumber: episodeNumber,
                name: name,
                overview: overview,
                airDate: airDate,
                runtime: runtime,
                stillPath: stillPath,
                rating: rating,
                tmdbId: tmdbId,
                watchState: watchState,
                playbackPositionSeconds: playbackPositionSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EpisodesTable, Episode>(table),
                  $$EpisodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({seasonId = false, mediaSourcesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaSourcesRefs) db.mediaSources,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (seasonId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.seasonId,
                            referencedTable: $$EpisodesTableReferences
                                ._seasonIdTable(db),
                            referencedColumn: $$EpisodesTableReferences
                                ._seasonIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaSourcesRefs)
                        await $_getPrefetchedData<
                          Episode,
                          $EpisodesTable,
                          MediaSource
                        >(
                          currentTable: table,
                          referencedTable: $$EpisodesTableReferences
                              ._mediaSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EpisodesTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.episodeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTable,
      Episode,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (Episode, $$EpisodesTableReferences),
      Episode,
      PrefetchHooks Function({bool seasonId, bool mediaSourcesRefs})
    >;
typedef $$MediaSourcesTableCreateCompanionBuilder =
    MediaSourcesCompanion Function({
      required String id,
      Value<String?> movieId,
      Value<String?> episodeId,
      required String storageId,
      required String sourceType,
      required String relativePath,
      required String filename,
      required String extension,
      required BigInt fileSize,
      Value<int?> duration,
      Value<String?> videoCodec,
      Value<String?> audioCodec,
      Value<String?> resolution,
      Value<String?> audioChannels,
      Value<String?> subtitleInformation,
      Value<String?> fingerprint,
      required DateTime createdAt,
      required DateTime firstSeenAt,
      required DateTime lastSeenAt,
      Value<bool> available,
      Value<int> rowid,
    });
typedef $$MediaSourcesTableUpdateCompanionBuilder =
    MediaSourcesCompanion Function({
      Value<String> id,
      Value<String?> movieId,
      Value<String?> episodeId,
      Value<String> storageId,
      Value<String> sourceType,
      Value<String> relativePath,
      Value<String> filename,
      Value<String> extension,
      Value<BigInt> fileSize,
      Value<int?> duration,
      Value<String?> videoCodec,
      Value<String?> audioCodec,
      Value<String?> resolution,
      Value<String?> audioChannels,
      Value<String?> subtitleInformation,
      Value<String?> fingerprint,
      Value<DateTime> createdAt,
      Value<DateTime> firstSeenAt,
      Value<DateTime> lastSeenAt,
      Value<bool> available,
      Value<int> rowid,
    });

final class $$MediaSourcesTableReferences
    extends BaseReferences<_$AppDatabase, $MediaSourcesTable, MediaSource> {
  $$MediaSourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MoviesTable _movieIdTable(_$AppDatabase db) =>
      db.movies.createAlias('media_sources__movie_id__movies__id');

  $$MoviesTableProcessedTableManager? get movieId {
    final $_column = $_itemColumn<String>('movie_id');
    if ($_column == null) return null;
    final manager = $$MoviesTableTableManager(
      $_db,
      $_db.movies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_movieIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EpisodesTable _episodeIdTable(_$AppDatabase db) =>
      db.episodes.createAlias('media_sources__episode_id__episodes__id');

  $$EpisodesTableProcessedTableManager? get episodeId {
    final $_column = $_itemColumn<String>('episode_id');
    if ($_column == null) return null;
    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_episodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StoragesTable _storageIdTable(_$AppDatabase db) =>
      db.storages.createAlias('media_sources__storage_id__storages__id');

  $$StoragesTableProcessedTableManager get storageId {
    final $_column = $_itemColumn<String>('storage_id')!;

    final manager = $$StoragesTableTableManager(
      $_db,
      $_db.storages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransferJobsTable, List<TransferJob>>
  _transferJobsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transferJobs,
    aliasName: 'media_sources__id__transfer_jobs__source_media_source_id',
  );

  $$TransferJobsTableProcessedTableManager get transferJobsRefs {
    final manager = $$TransferJobsTableTableManager($_db, $_db.transferJobs)
        .filter(
          (f) =>
              f.sourceMediaSourceId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_transferJobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediaSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $MediaSourcesTable> {
  $$MediaSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extension => $composableBuilder(
    column: $table.extension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoCodec => $composableBuilder(
    column: $table.videoCodec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioCodec => $composableBuilder(
    column: $table.audioCodec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioChannels => $composableBuilder(
    column: $table.audioChannels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitleInformation => $composableBuilder(
    column: $table.subtitleInformation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnFilters(column),
  );

  $$MoviesTableFilterComposer get movieId {
    final $$MoviesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movieId,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableFilterComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EpisodesTableFilterComposer get episodeId {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.episodeId,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableFilterComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoragesTableFilterComposer get storageId {
    final $$StoragesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storageId,
      referencedTable: $db.storages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoragesTableFilterComposer(
            $db: $db,
            $table: $db.storages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transferJobsRefs(
    Expression<bool> Function($$TransferJobsTableFilterComposer f) f,
  ) {
    final $$TransferJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transferJobs,
      getReferencedColumn: (t) => t.sourceMediaSourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferJobsTableFilterComposer(
            $db: $db,
            $table: $db.transferJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaSourcesTable> {
  $$MediaSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extension => $composableBuilder(
    column: $table.extension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoCodec => $composableBuilder(
    column: $table.videoCodec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioCodec => $composableBuilder(
    column: $table.audioCodec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioChannels => $composableBuilder(
    column: $table.audioChannels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitleInformation => $composableBuilder(
    column: $table.subtitleInformation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnOrderings(column),
  );

  $$MoviesTableOrderingComposer get movieId {
    final $$MoviesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movieId,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableOrderingComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EpisodesTableOrderingComposer get episodeId {
    final $$EpisodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.episodeId,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableOrderingComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoragesTableOrderingComposer get storageId {
    final $$StoragesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storageId,
      referencedTable: $db.storages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoragesTableOrderingComposer(
            $db: $db,
            $table: $db.storages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaSourcesTable> {
  $$MediaSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get extension =>
      $composableBuilder(column: $table.extension, builder: (column) => column);

  GeneratedColumn<BigInt> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get videoCodec => $composableBuilder(
    column: $table.videoCodec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioCodec => $composableBuilder(
    column: $table.audioCodec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolution => $composableBuilder(
    column: $table.resolution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioChannels => $composableBuilder(
    column: $table.audioChannels,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subtitleInformation => $composableBuilder(
    column: $table.subtitleInformation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get available =>
      $composableBuilder(column: $table.available, builder: (column) => column);

  $$MoviesTableAnnotationComposer get movieId {
    final $$MoviesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movieId,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableAnnotationComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EpisodesTableAnnotationComposer get episodeId {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.episodeId,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoragesTableAnnotationComposer get storageId {
    final $$StoragesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storageId,
      referencedTable: $db.storages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoragesTableAnnotationComposer(
            $db: $db,
            $table: $db.storages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transferJobsRefs<T extends Object>(
    Expression<T> Function($$TransferJobsTableAnnotationComposer a) f,
  ) {
    final $$TransferJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transferJobs,
      getReferencedColumn: (t) => t.sourceMediaSourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransferJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.transferJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaSourcesTable,
          MediaSource,
          $$MediaSourcesTableFilterComposer,
          $$MediaSourcesTableOrderingComposer,
          $$MediaSourcesTableAnnotationComposer,
          $$MediaSourcesTableCreateCompanionBuilder,
          $$MediaSourcesTableUpdateCompanionBuilder,
          (MediaSource, $$MediaSourcesTableReferences),
          MediaSource,
          PrefetchHooks Function({
            bool movieId,
            bool episodeId,
            bool storageId,
            bool transferJobsRefs,
          })
        > {
  $$MediaSourcesTableTableManager(_$AppDatabase db, $MediaSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> movieId = const Value.absent(),
                Value<String?> episodeId = const Value.absent(),
                Value<String> storageId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<String> extension = const Value.absent(),
                Value<BigInt> fileSize = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<String?> videoCodec = const Value.absent(),
                Value<String?> audioCodec = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<String?> audioChannels = const Value.absent(),
                Value<String?> subtitleInformation = const Value.absent(),
                Value<String?> fingerprint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> firstSeenAt = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<bool> available = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaSourcesCompanion(
                id: id,
                movieId: movieId,
                episodeId: episodeId,
                storageId: storageId,
                sourceType: sourceType,
                relativePath: relativePath,
                filename: filename,
                extension: extension,
                fileSize: fileSize,
                duration: duration,
                videoCodec: videoCodec,
                audioCodec: audioCodec,
                resolution: resolution,
                audioChannels: audioChannels,
                subtitleInformation: subtitleInformation,
                fingerprint: fingerprint,
                createdAt: createdAt,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                available: available,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> movieId = const Value.absent(),
                Value<String?> episodeId = const Value.absent(),
                required String storageId,
                required String sourceType,
                required String relativePath,
                required String filename,
                required String extension,
                required BigInt fileSize,
                Value<int?> duration = const Value.absent(),
                Value<String?> videoCodec = const Value.absent(),
                Value<String?> audioCodec = const Value.absent(),
                Value<String?> resolution = const Value.absent(),
                Value<String?> audioChannels = const Value.absent(),
                Value<String?> subtitleInformation = const Value.absent(),
                Value<String?> fingerprint = const Value.absent(),
                required DateTime createdAt,
                required DateTime firstSeenAt,
                required DateTime lastSeenAt,
                Value<bool> available = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaSourcesCompanion.insert(
                id: id,
                movieId: movieId,
                episodeId: episodeId,
                storageId: storageId,
                sourceType: sourceType,
                relativePath: relativePath,
                filename: filename,
                extension: extension,
                fileSize: fileSize,
                duration: duration,
                videoCodec: videoCodec,
                audioCodec: audioCodec,
                resolution: resolution,
                audioChannels: audioChannels,
                subtitleInformation: subtitleInformation,
                fingerprint: fingerprint,
                createdAt: createdAt,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                available: available,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaSourcesTable, MediaSource>(table),
                  $$MediaSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                movieId = false,
                episodeId = false,
                storageId = false,
                transferJobsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transferJobsRefs) db.transferJobs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (movieId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.movieId,
                            referencedTable: $$MediaSourcesTableReferences
                                ._movieIdTable(db),
                            referencedColumn: $$MediaSourcesTableReferences
                                ._movieIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (episodeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.episodeId,
                            referencedTable: $$MediaSourcesTableReferences
                                ._episodeIdTable(db),
                            referencedColumn: $$MediaSourcesTableReferences
                                ._episodeIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (storageId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.storageId,
                            referencedTable: $$MediaSourcesTableReferences
                                ._storageIdTable(db),
                            referencedColumn: $$MediaSourcesTableReferences
                                ._storageIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transferJobsRefs)
                        await $_getPrefetchedData<
                          MediaSource,
                          $MediaSourcesTable,
                          TransferJob
                        >(
                          currentTable: table,
                          referencedTable: $$MediaSourcesTableReferences
                              ._transferJobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).transferJobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceMediaSourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MediaSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaSourcesTable,
      MediaSource,
      $$MediaSourcesTableFilterComposer,
      $$MediaSourcesTableOrderingComposer,
      $$MediaSourcesTableAnnotationComposer,
      $$MediaSourcesTableCreateCompanionBuilder,
      $$MediaSourcesTableUpdateCompanionBuilder,
      (MediaSource, $$MediaSourcesTableReferences),
      MediaSource,
      PrefetchHooks Function({
        bool movieId,
        bool episodeId,
        bool storageId,
        bool transferJobsRefs,
      })
    >;
typedef $$TransferJobsTableCreateCompanionBuilder =
    TransferJobsCompanion Function({
      required String id,
      required String mediaType,
      required String mediaId,
      required String sourceMediaSourceId,
      required String destinationStorageId,
      required String destinationRelativePath,
      required String status,
      Value<BigInt> bytesTransferred,
      required BigInt totalBytes,
      Value<String?> error,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$TransferJobsTableUpdateCompanionBuilder =
    TransferJobsCompanion Function({
      Value<String> id,
      Value<String> mediaType,
      Value<String> mediaId,
      Value<String> sourceMediaSourceId,
      Value<String> destinationStorageId,
      Value<String> destinationRelativePath,
      Value<String> status,
      Value<BigInt> bytesTransferred,
      Value<BigInt> totalBytes,
      Value<String?> error,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

final class $$TransferJobsTableReferences
    extends BaseReferences<_$AppDatabase, $TransferJobsTable, TransferJob> {
  $$TransferJobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaSourcesTable _sourceMediaSourceIdTable(_$AppDatabase db) => db
      .mediaSources
      .createAlias('transfer_jobs__source_media_source_id__media_sources__id');

  $$MediaSourcesTableProcessedTableManager get sourceMediaSourceId {
    final $_column = $_itemColumn<String>('source_media_source_id')!;

    final manager = $$MediaSourcesTableTableManager(
      $_db,
      $_db.mediaSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceMediaSourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StoragesTable _destinationStorageIdTable(_$AppDatabase db) => db
      .storages
      .createAlias('transfer_jobs__destination_storage_id__storages__id');

  $$StoragesTableProcessedTableManager get destinationStorageId {
    final $_column = $_itemColumn<String>('destination_storage_id')!;

    final manager = $$StoragesTableTableManager(
      $_db,
      $_db.storages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _destinationStorageIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransferJobsTableFilterComposer
    extends Composer<_$AppDatabase, $TransferJobsTable> {
  $$TransferJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationRelativePath => $composableBuilder(
    column: $table.destinationRelativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get bytesTransferred => $composableBuilder(
    column: $table.bytesTransferred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaSourcesTableFilterComposer get sourceMediaSourceId {
    final $$MediaSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceMediaSourceId,
      referencedTable: $db.mediaSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaSourcesTableFilterComposer(
            $db: $db,
            $table: $db.mediaSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoragesTableFilterComposer get destinationStorageId {
    final $$StoragesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationStorageId,
      referencedTable: $db.storages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoragesTableFilterComposer(
            $db: $db,
            $table: $db.storages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransferJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferJobsTable> {
  $$TransferJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationRelativePath => $composableBuilder(
    column: $table.destinationRelativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get bytesTransferred => $composableBuilder(
    column: $table.bytesTransferred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaSourcesTableOrderingComposer get sourceMediaSourceId {
    final $$MediaSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceMediaSourceId,
      referencedTable: $db.mediaSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.mediaSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoragesTableOrderingComposer get destinationStorageId {
    final $$StoragesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationStorageId,
      referencedTable: $db.storages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoragesTableOrderingComposer(
            $db: $db,
            $table: $db.storages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransferJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferJobsTable> {
  $$TransferJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get destinationRelativePath => $composableBuilder(
    column: $table.destinationRelativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<BigInt> get bytesTransferred => $composableBuilder(
    column: $table.bytesTransferred,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$MediaSourcesTableAnnotationComposer get sourceMediaSourceId {
    final $$MediaSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceMediaSourceId,
      referencedTable: $db.mediaSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoragesTableAnnotationComposer get destinationStorageId {
    final $$StoragesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationStorageId,
      referencedTable: $db.storages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoragesTableAnnotationComposer(
            $db: $db,
            $table: $db.storages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransferJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferJobsTable,
          TransferJob,
          $$TransferJobsTableFilterComposer,
          $$TransferJobsTableOrderingComposer,
          $$TransferJobsTableAnnotationComposer,
          $$TransferJobsTableCreateCompanionBuilder,
          $$TransferJobsTableUpdateCompanionBuilder,
          (TransferJob, $$TransferJobsTableReferences),
          TransferJob,
          PrefetchHooks Function({
            bool sourceMediaSourceId,
            bool destinationStorageId,
          })
        > {
  $$TransferJobsTableTableManager(_$AppDatabase db, $TransferJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransferJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<String> sourceMediaSourceId = const Value.absent(),
                Value<String> destinationStorageId = const Value.absent(),
                Value<String> destinationRelativePath = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<BigInt> bytesTransferred = const Value.absent(),
                Value<BigInt> totalBytes = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransferJobsCompanion(
                id: id,
                mediaType: mediaType,
                mediaId: mediaId,
                sourceMediaSourceId: sourceMediaSourceId,
                destinationStorageId: destinationStorageId,
                destinationRelativePath: destinationRelativePath,
                status: status,
                bytesTransferred: bytesTransferred,
                totalBytes: totalBytes,
                error: error,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mediaType,
                required String mediaId,
                required String sourceMediaSourceId,
                required String destinationStorageId,
                required String destinationRelativePath,
                required String status,
                Value<BigInt> bytesTransferred = const Value.absent(),
                required BigInt totalBytes,
                Value<String?> error = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransferJobsCompanion.insert(
                id: id,
                mediaType: mediaType,
                mediaId: mediaId,
                sourceMediaSourceId: sourceMediaSourceId,
                destinationStorageId: destinationStorageId,
                destinationRelativePath: destinationRelativePath,
                status: status,
                bytesTransferred: bytesTransferred,
                totalBytes: totalBytes,
                error: error,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransferJobsTable, TransferJob>(table),
                  $$TransferJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceMediaSourceId = false, destinationStorageId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceMediaSourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceMediaSourceId,
                            referencedTable: $$TransferJobsTableReferences
                                ._sourceMediaSourceIdTable(db),
                            referencedColumn: $$TransferJobsTableReferences
                                ._sourceMediaSourceIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (destinationStorageId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.destinationStorageId,
                            referencedTable: $$TransferJobsTableReferences
                                ._destinationStorageIdTable(db),
                            referencedColumn: $$TransferJobsTableReferences
                                ._destinationStorageIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransferJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferJobsTable,
      TransferJob,
      $$TransferJobsTableFilterComposer,
      $$TransferJobsTableOrderingComposer,
      $$TransferJobsTableAnnotationComposer,
      $$TransferJobsTableCreateCompanionBuilder,
      $$TransferJobsTableUpdateCompanionBuilder,
      (TransferJob, $$TransferJobsTableReferences),
      TransferJob,
      PrefetchHooks Function({
        bool sourceMediaSourceId,
        bool destinationStorageId,
      })
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      required String id,
      required String name,
      Value<String?> overview,
      Value<String?> posterPath,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> overview,
      Value<String?> posterPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CollectionsTableReferences
    extends BaseReferences<_$AppDatabase, $CollectionsTable, Collection> {
  $$CollectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CollectionItemsTable, List<CollectionItem>>
  _collectionItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.collectionItems,
    aliasName: 'collections__id__collection_items__collection_id',
  );

  $$CollectionItemsTableProcessedTableManager get collectionItemsRefs {
    final manager = $$CollectionItemsTableTableManager(
      $_db,
      $_db.collectionItems,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectionItemsRefs(
    Expression<bool> Function($$CollectionItemsTableFilterComposer f) f,
  ) {
    final $$CollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> collectionItemsRefs<T extends Object>(
    Expression<T> Function($$CollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$CollectionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionsTable,
          Collection,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (Collection, $$CollectionsTableReferences),
          Collection,
          PrefetchHooks Function({bool collectionItemsRefs})
        > {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion(
                id: id,
                name: name,
                overview: overview,
                posterPath: posterPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> overview = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion.insert(
                id: id,
                name: name,
                overview: overview,
                posterPath: posterPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionsTable, Collection>(table),
                  $$CollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (collectionItemsRefs) db.collectionItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (collectionItemsRefs)
                    await $_getPrefetchedData<
                      Collection,
                      $CollectionsTable,
                      CollectionItem
                    >(
                      currentTable: table,
                      referencedTable: $$CollectionsTableReferences
                          ._collectionItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).collectionItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.collectionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionsTable,
      Collection,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (Collection, $$CollectionsTableReferences),
      Collection,
      PrefetchHooks Function({bool collectionItemsRefs})
    >;
typedef $$CollectionItemsTableCreateCompanionBuilder =
    CollectionItemsCompanion Function({
      required String id,
      required String collectionId,
      Value<String?> movieId,
      Value<String?> tvShowId,
      Value<int> displayOrder,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$CollectionItemsTableUpdateCompanionBuilder =
    CollectionItemsCompanion Function({
      Value<String> id,
      Value<String> collectionId,
      Value<String?> movieId,
      Value<String?> tvShowId,
      Value<int> displayOrder,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

final class $$CollectionItemsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CollectionItemsTable, CollectionItem> {
  $$CollectionItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CollectionsTable _collectionIdTable(_$AppDatabase db) => db
      .collections
      .createAlias('collection_items__collection_id__collections__id');

  $$CollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$CollectionsTableTableManager(
      $_db,
      $_db.collections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MoviesTable _movieIdTable(_$AppDatabase db) =>
      db.movies.createAlias('collection_items__movie_id__movies__id');

  $$MoviesTableProcessedTableManager? get movieId {
    final $_column = $_itemColumn<String>('movie_id');
    if ($_column == null) return null;
    final manager = $$MoviesTableTableManager(
      $_db,
      $_db.movies,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_movieIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TvShowsTable _tvShowIdTable(_$AppDatabase db) =>
      db.tvShows.createAlias('collection_items__tv_show_id__tv_shows__id');

  $$TvShowsTableProcessedTableManager? get tvShowId {
    final $_column = $_itemColumn<String>('tv_show_id');
    if ($_column == null) return null;
    final manager = $$TvShowsTableTableManager(
      $_db,
      $_db.tvShows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tvShowIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollectionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CollectionsTableFilterComposer get collectionId {
    final $$CollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableFilterComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MoviesTableFilterComposer get movieId {
    final $$MoviesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movieId,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableFilterComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TvShowsTableFilterComposer get tvShowId {
    final $$TvShowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tvShowId,
      referencedTable: $db.tvShows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TvShowsTableFilterComposer(
            $db: $db,
            $table: $db.tvShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CollectionsTableOrderingComposer get collectionId {
    final $$CollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MoviesTableOrderingComposer get movieId {
    final $$MoviesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movieId,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableOrderingComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TvShowsTableOrderingComposer get tvShowId {
    final $$TvShowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tvShowId,
      referencedTable: $db.tvShows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TvShowsTableOrderingComposer(
            $db: $db,
            $table: $db.tvShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$CollectionsTableAnnotationComposer get collectionId {
    final $$CollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MoviesTableAnnotationComposer get movieId {
    final $$MoviesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movieId,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableAnnotationComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TvShowsTableAnnotationComposer get tvShowId {
    final $$TvShowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tvShowId,
      referencedTable: $db.tvShows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TvShowsTableAnnotationComposer(
            $db: $db,
            $table: $db.tvShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionItemsTable,
          CollectionItem,
          $$CollectionItemsTableFilterComposer,
          $$CollectionItemsTableOrderingComposer,
          $$CollectionItemsTableAnnotationComposer,
          $$CollectionItemsTableCreateCompanionBuilder,
          $$CollectionItemsTableUpdateCompanionBuilder,
          (CollectionItem, $$CollectionItemsTableReferences),
          CollectionItem,
          PrefetchHooks Function({
            bool collectionId,
            bool movieId,
            bool tvShowId,
          })
        > {
  $$CollectionItemsTableTableManager(
    _$AppDatabase db,
    $CollectionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> collectionId = const Value.absent(),
                Value<String?> movieId = const Value.absent(),
                Value<String?> tvShowId = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion(
                id: id,
                collectionId: collectionId,
                movieId: movieId,
                tvShowId: tvShowId,
                displayOrder: displayOrder,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String collectionId,
                Value<String?> movieId = const Value.absent(),
                Value<String?> tvShowId = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion.insert(
                id: id,
                collectionId: collectionId,
                movieId: movieId,
                tvShowId: tvShowId,
                displayOrder: displayOrder,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionItemsTable, CollectionItem>(table),
                  $$CollectionItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({collectionId = false, movieId = false, tvShowId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (collectionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.collectionId,
                            referencedTable: $$CollectionItemsTableReferences
                                ._collectionIdTable(db),
                            referencedColumn: $$CollectionItemsTableReferences
                                ._collectionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (movieId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.movieId,
                            referencedTable: $$CollectionItemsTableReferences
                                ._movieIdTable(db),
                            referencedColumn: $$CollectionItemsTableReferences
                                ._movieIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (tvShowId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tvShowId,
                            referencedTable: $$CollectionItemsTableReferences
                                ._tvShowIdTable(db),
                            referencedColumn: $$CollectionItemsTableReferences
                                ._tvShowIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CollectionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionItemsTable,
      CollectionItem,
      $$CollectionItemsTableFilterComposer,
      $$CollectionItemsTableOrderingComposer,
      $$CollectionItemsTableAnnotationComposer,
      $$CollectionItemsTableCreateCompanionBuilder,
      $$CollectionItemsTableUpdateCompanionBuilder,
      (CollectionItem, $$CollectionItemsTableReferences),
      CollectionItem,
      PrefetchHooks Function({bool collectionId, bool movieId, bool tvShowId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StoragesTableTableManager get storages =>
      $$StoragesTableTableManager(_db, _db.storages);
  $$MoviesTableTableManager get movies =>
      $$MoviesTableTableManager(_db, _db.movies);
  $$TvShowsTableTableManager get tvShows =>
      $$TvShowsTableTableManager(_db, _db.tvShows);
  $$SeasonsTableTableManager get seasons =>
      $$SeasonsTableTableManager(_db, _db.seasons);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$MediaSourcesTableTableManager get mediaSources =>
      $$MediaSourcesTableTableManager(_db, _db.mediaSources);
  $$TransferJobsTableTableManager get transferJobs =>
      $$TransferJobsTableTableManager(_db, _db.transferJobs);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$CollectionItemsTableTableManager get collectionItems =>
      $$CollectionItemsTableTableManager(_db, _db.collectionItems);
}
