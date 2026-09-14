/// Strongly-typed models for TMDB API responses.
library;

class TmdbMovieSearchResult {
  final int id;
  final String title;
  final String? originalTitle;
  final String? releaseDate;
  final int? releaseYear;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? voteAverage;
  final int? voteCount;

  const TmdbMovieSearchResult({
    required this.id,
    required this.title,
    this.originalTitle,
    this.releaseDate,
    this.releaseYear,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.voteAverage,
    this.voteCount,
  });

  factory TmdbMovieSearchResult.fromJson(Map<String, dynamic> json) {
    final relDate = json['release_date'] as String?;
    int? year;
    if (relDate != null && relDate.length >= 4) {
      year = int.tryParse(relDate.substring(0, 4));
    }

    return TmdbMovieSearchResult(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      originalTitle: json['original_title'] as String?,
      releaseDate: relDate,
      releaseYear: year,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
    );
  }
}

class TmdbMovieDetails {
  final int id;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? releaseDate;
  final int? releaseYear;
  final int? runtime;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? voteCount;
  final String? imdbId;

  const TmdbMovieDetails({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.releaseDate,
    this.releaseYear,
    this.runtime,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.imdbId,
  });

  factory TmdbMovieDetails.fromJson(Map<String, dynamic> json) {
    final relDate = json['release_date'] as String?;
    int? year;
    if (relDate != null && relDate.length >= 4) {
      year = int.tryParse(relDate.substring(0, 4));
    }

    String? imdb;
    if (json['external_ids'] is Map) {
      imdb = json['external_ids']['imdb_id'] as String?;
    } else {
      imdb = json['imdb_id'] as String?;
    }

    return TmdbMovieDetails(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      originalTitle: json['original_title'] as String?,
      overview: json['overview'] as String?,
      releaseDate: relDate,
      releaseYear: year,
      runtime: json['runtime'] as int?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      imdbId: imdb,
    );
  }
}

class TmdbTvSearchResult {
  final int id;
  final String name;
  final String? originalName;
  final String? firstAirDate;
  final int? firstAirYear;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? voteAverage;
  final int? voteCount;

  const TmdbTvSearchResult({
    required this.id,
    required this.name,
    this.originalName,
    this.firstAirDate,
    this.firstAirYear,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.voteAverage,
    this.voteCount,
  });

  factory TmdbTvSearchResult.fromJson(Map<String, dynamic> json) {
    final airDate = json['first_air_date'] as String?;
    int? year;
    if (airDate != null && airDate.length >= 4) {
      year = int.tryParse(airDate.substring(0, 4));
    }

    return TmdbTvSearchResult(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      originalName: json['original_name'] as String?,
      firstAirDate: airDate,
      firstAirYear: year,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
    );
  }
}

class TmdbTvShowDetails {
  final int id;
  final String name;
  final String? originalName;
  final String? overview;
  final String? firstAirDate;
  final int? firstAirYear;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final int? voteCount;
  final String? imdbId;
  final int numberOfSeasons;
  final int numberOfEpisodes;

  const TmdbTvShowDetails({
    required this.id,
    required this.name,
    this.originalName,
    this.overview,
    this.firstAirDate,
    this.firstAirYear,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.imdbId,
    this.numberOfSeasons = 0,
    this.numberOfEpisodes = 0,
  });

  factory TmdbTvShowDetails.fromJson(Map<String, dynamic> json) {
    final airDate = json['first_air_date'] as String?;
    int? year;
    if (airDate != null && airDate.length >= 4) {
      year = int.tryParse(airDate.substring(0, 4));
    }

    String? imdb;
    if (json['external_ids'] is Map) {
      imdb = json['external_ids']['imdb_id'] as String?;
    }

    return TmdbTvShowDetails(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      originalName: json['original_name'] as String?,
      overview: json['overview'] as String?,
      firstAirDate: airDate,
      firstAirYear: year,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      imdbId: imdb,
      numberOfSeasons: json['number_of_seasons'] as int? ?? 0,
      numberOfEpisodes: json['number_of_episodes'] as int? ?? 0,
    );
  }
}

class TmdbSeasonDetails {
  final int id;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? airDate;
  final List<TmdbEpisodeDetails> episodes;

  const TmdbSeasonDetails({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterPath,
    this.airDate,
    this.episodes = const [],
  });

  factory TmdbSeasonDetails.fromJson(Map<String, dynamic> json) {
    final epList = <TmdbEpisodeDetails>[];
    if (json['episodes'] is List) {
      for (final ep in json['episodes'] as List) {
        if (ep is Map<String, dynamic>) {
          epList.add(TmdbEpisodeDetails.fromJson(ep));
        }
      }
    }

    return TmdbSeasonDetails(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      airDate: json['air_date'] as String?,
      episodes: epList,
    );
  }
}

class TmdbEpisodeDetails {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final double? voteAverage;
  final int? runtime;

  const TmdbEpisodeDetails({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.voteAverage,
    this.runtime,
  });

  factory TmdbEpisodeDetails.fromJson(Map<String, dynamic> json) {
    return TmdbEpisodeDetails(
      id: json['id'] as int,
      episodeNumber: json['episode_number'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      stillPath: json['still_path'] as String?,
      airDate: json['air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      runtime: json['runtime'] as int?,
    );
  }
}
