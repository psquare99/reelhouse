enum ParsedMediaType { movie, tvEpisode, unknown }

/// Structured metadata extracted from a media filename and relative path.
class ParsedMediaInfo {
  final ParsedMediaType type;
  final String title;
  final int? year;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? episodeTitle;
  final bool isExtra;
  final String? resolution; // e.g. "1080p", "4K", "720p"
  final String? videoCodec; // e.g. "HEVC", "AVC", "AV1"
  final String? audioCodec; // e.g. "DTS", "AAC", "AC3"
  final String? audioChannels; // e.g. "5.1", "7.1", "Stereo"
  final String rawFilename;
  final String relativePath;
  final int fileSize;
  final String extension;

  const ParsedMediaInfo({
    required this.type,
    required this.title,
    this.year,
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
    this.isExtra = false,
    this.resolution,
    this.videoCodec,
    this.audioCodec,
    this.audioChannels,
    required this.rawFilename,
    required this.relativePath,
    required this.fileSize,
    required this.extension,
  });

  bool get isMovie => type == ParsedMediaType.movie;
  bool get isTvEpisode => type == ParsedMediaType.tvEpisode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedMediaInfo &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          title == other.title &&
          year == other.year &&
          seasonNumber == other.seasonNumber &&
          episodeNumber == other.episodeNumber &&
          episodeTitle == other.episodeTitle &&
          isExtra == other.isExtra &&
          resolution == other.resolution &&
          videoCodec == other.videoCodec &&
          audioCodec == other.audioCodec &&
          audioChannels == other.audioChannels &&
          rawFilename == other.rawFilename &&
          relativePath == other.relativePath &&
          fileSize == other.fileSize &&
          extension == other.extension;

  @override
  int get hashCode => Object.hash(
    type,
    title,
    year,
    seasonNumber,
    episodeNumber,
    episodeTitle,
    isExtra,
    resolution,
    videoCodec,
    audioCodec,
    audioChannels,
    rawFilename,
    relativePath,
    fileSize,
    extension,
  );

  @override
  String toString() {
    if (isTvEpisode) {
      if (isExtra) {
        return 'ParsedMediaInfo(TV Extra: $title - $episodeTitle, res: $resolution, codec: $videoCodec)';
      }
      return 'ParsedMediaInfo(TV: $title S${seasonNumber?.toString().padLeft(2, '0')}E${episodeNumber?.toString().padLeft(2, '0')}, res: $resolution, codec: $videoCodec)';
    }
    return 'ParsedMediaInfo(Movie: $title ($year), res: $resolution, codec: $videoCodec)';
  }
}
