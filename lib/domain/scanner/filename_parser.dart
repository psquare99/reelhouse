import 'package:path/path.dart' as p;

import 'parsed_media_info.dart';

/// Parses raw video filenames and relative directory paths to extract structured media identity.
class FilenameParser {
  const FilenameParser();

  /// Supported video file extensions in REELHOUSE.
  static const Set<String> supportedExtensions = {
    'mkv',
    'mp4',
    'avi',
    'mov',
    'm4v',
    'webm',
    'ts',
    'wmv',
    'iso',
    'm2ts',
    'flv',
  };

  /// Returns true if [filePathOrName] is an indexable media file.
  static bool isSupportedMediaFile(String filePathOrName) {
    final filename = p.basename(filePathOrName);
    if (filename.startsWith('.') || filename.startsWith('._')) {
      return false;
    }
    final ext = p.extension(filename).replaceAll('.', '').toLowerCase();
    return supportedExtensions.contains(ext);
  }

  /// Returns true if [filename] indicates a promotional or sample snippet rather than full media.
  static bool isSampleFile(String filename, [int fileSize = 0]) {
    final lower = p.basenameWithoutExtension(filename).toLowerCase();
    // Typical samples are named sample.mkv, movie-sample.mp4, etc.
    final hasSampleWord = RegExp(r'(?:^|[._\s-])sample(?:$|[._\s-])')
        .hasMatch(lower);
    if (hasSampleWord) {
      // If file size is known and over 350 MB, it is likely not a sample despite the name
      if (fileSize > 350 * 1024 * 1024) return false;
      return true;
    }
    return false;
  }

  static final RegExp _tvPatternSxxExx = RegExp(
    r'(?:^|[._\s-])(?:s|season\s*)(\d{1,2})[._\s-]*(?:e|ep|episode\s*)(\d{1,3})',
    caseSensitive: false,
  );

  static final RegExp _tvPatternNxNN = RegExp(
    r'(?:^|[._\s-])(\d{1,2})x(\d{1,3})',
    caseSensitive: false,
  );

  static final RegExp _tvPatternSeasonFolder = RegExp(
    r'(?:^|[\\/])(?:season|s)\s*(\d{1,2})(?:[\\/])',
    caseSensitive: false,
  );

  static final RegExp _yearPattern = RegExp(
    r'(?:^|[.\s_(-])(19\d{2}|20\d{2})(?:[).\s_-]|$)',
  );

  static final RegExp _resolutionPattern = RegExp(
    r'\b(2160p|4k|uhd|1080p|1080i|720p|576p|480p)\b',
    caseSensitive: false,
  );

  static final RegExp _videoCodecPattern = RegExp(
    r'\b(x265|h265|hevc|x264|h264|avc|av1|xvid|divx|vp9)\b',
    caseSensitive: false,
  );

  static final RegExp _audioCodecPattern = RegExp(
    r'\b(dts-hd|dts|truehd|atmos|eac3|ddp|ac3|aac|flac|mp3)\b',
    caseSensitive: false,
  );

  static final RegExp _audioChannelsPattern = RegExp(
    r'\b(7\.1|5\.1|2\.0|stereo)\b',
    caseSensitive: false,
  );

  static final RegExp _garbageTokens = RegExp(
    r'\b(bluray|blu-ray|bdrip|brrip|web-dl|webdl|webrip|web-rip|hdtv|dvdrip|remux|proper|repack|extended|unrated|director.?s.?cut|remastered|criterion)\b',
    caseSensitive: false,
  );

  static final RegExp _releaseGroups = RegExp(
    r'-[a-zA-Z0-9_]+$',
    caseSensitive: false,
  );

  /// Parses [relativePath] and [fileSize] to extract media identity.
  ParsedMediaInfo parse({required String relativePath, required int fileSize}) {
    final rawFilename = p.basename(relativePath);
    final ext = p.extension(rawFilename).replaceAll('.', '').toLowerCase();
    final nameWithoutExt = p.basenameWithoutExtension(rawFilename);

    final resolution = _extractResolution(nameWithoutExt);
    final videoCodec = _extractVideoCodec(nameWithoutExt);
    final audioCodec = _extractAudioCodec(nameWithoutExt);
    final audioChannels = _extractAudioChannels(nameWithoutExt);

    // 1. Check for TV Show pattern (e.g. Breaking.Bad.S02E03.1080p.mkv)
    final tvMatchSxxExx = _tvPatternSxxExx.firstMatch(nameWithoutExt);
    final tvMatchNxNN = _tvPatternNxNN.firstMatch(nameWithoutExt);

    if (tvMatchSxxExx != null) {
      final season = int.tryParse(tvMatchSxxExx.group(1) ?? '');
      final episode = int.tryParse(tvMatchSxxExx.group(2) ?? '');
      final rawTitle = nameWithoutExt.substring(0, tvMatchSxxExx.start);
      var cleanTitle = _cleanTitle(rawTitle);

      if (cleanTitle.isEmpty) {
        cleanTitle = _findShowTitleFromPath(relativePath);
      }

      String? epTitle;
      if (tvMatchSxxExx.end < nameWithoutExt.length) {
        final rest = nameWithoutExt.substring(tvMatchSxxExx.end);
        final candidate = _cleanEpisodeTitle(rest);
        if (candidate.isNotEmpty) {
          epTitle = candidate;
        }
      }

      return ParsedMediaInfo(
        type: ParsedMediaType.tvEpisode,
        title: cleanTitle.isNotEmpty ? cleanTitle : 'TV Series',
        seasonNumber: season,
        episodeNumber: episode,
        episodeTitle: epTitle,
        resolution: resolution,
        videoCodec: videoCodec,
        audioCodec: audioCodec,
        audioChannels: audioChannels,
        rawFilename: rawFilename,
        relativePath: relativePath,
        fileSize: fileSize,
        extension: ext,
      );
    } else if (tvMatchNxNN != null) {
      final season = int.tryParse(tvMatchNxNN.group(1) ?? '');
      final episode = int.tryParse(tvMatchNxNN.group(2) ?? '');
      final rawTitle = nameWithoutExt.substring(0, tvMatchNxNN.start);
      var cleanTitle = _cleanTitle(rawTitle);

      if (cleanTitle.isEmpty) {
        cleanTitle = _findShowTitleFromPath(relativePath);
      }

      return ParsedMediaInfo(
        type: ParsedMediaType.tvEpisode,
        title: cleanTitle.isNotEmpty ? cleanTitle : 'TV Series',
        seasonNumber: season,
        episodeNumber: episode,
        resolution: resolution,
        videoCodec: videoCodec,
        audioCodec: audioCodec,
        audioChannels: audioChannels,
        rawFilename: rawFilename,
        relativePath: relativePath,
        fileSize: fileSize,
        extension: ext,
      );
    }

    // 2. Check directory structure for Season folder (e.g. Severance/Season 1/01.mkv)
    final seasonFolderMatch = _tvPatternSeasonFolder.firstMatch(relativePath);
    if (seasonFolderMatch != null) {
      final season = int.tryParse(seasonFolderMatch.group(1) ?? '');
      final episodeNumberMatch = RegExp(
        r'\b(?:ep?|episode\s*)?(\d{1,3})\b',
        caseSensitive: false,
      ).firstMatch(nameWithoutExt);
      final epNum = episodeNumberMatch != null
          ? int.tryParse(episodeNumberMatch.group(1) ?? '')
          : null;

      final showTitle = _findShowTitleFromPath(relativePath);

      if (season != null && epNum != null) {
        return ParsedMediaInfo(
          type: ParsedMediaType.tvEpisode,
          title: showTitle.isNotEmpty ? showTitle : 'TV Series',
          seasonNumber: season,
          episodeNumber: epNum,
          resolution: resolution,
          videoCodec: videoCodec,
          audioCodec: audioCodec,
          audioChannels: audioChannels,
          rawFilename: rawFilename,
          relativePath: relativePath,
          fileSize: fileSize,
          extension: ext,
        );
      }
    }

    // 3. Check for TV Extras / Bonus / Specials content within TV show directories
    final normalizedPath = relativePath.replaceAll('\\', '/');
    final pathSegments = normalizedPath
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    if (pathSegments.isNotEmpty) {
      pathSegments.removeLast(); // remove filename
    }

    final hasExtrasFolder = pathSegments.any(
      (seg) => RegExp(
        r'^(?:extras?|bonus|specials?|featurettes?|behind\s*the\s*scenes|deleted\s*scenes?|bonus\s*material)$',
        caseSensitive: false,
      ).hasMatch(seg),
    );

    final hasSeasonFolder = pathSegments.any(
      (seg) => RegExp(
        r'^(?:season|s)\s*\d+|^got\s*s\d+|^thf\s*s\d+',
        caseSensitive: false,
      ).hasMatch(seg),
    );

    final hasBonusFilenamePattern = RegExp(
      r'^(?:deleted\s*scenes?|featurettes?|behind\s*the\s*scenes?|character\s*profile|history\s*[-–]|making\s*of|interview|bonus\s*feature|locations\s*[-–]|rebelion|religons|rountable|taming)',
      caseSensitive: false,
    ).hasMatch(nameWithoutExt);

    if (hasExtrasFolder || (hasSeasonFolder && hasBonusFilenamePattern)) {
      final showTitle = _findShowTitleFromPath(relativePath);
      if (showTitle.isNotEmpty) {
        var extraTitle = _cleanEpisodeTitle(nameWithoutExt);
        if (extraTitle.isEmpty) {
          extraTitle = _cleanTitle(nameWithoutExt);
        }

        final episodeNumberMatch = RegExp(
          r'\b(?:ep?|episode|extra|special\s*)?(\d{1,3})\b',
          caseSensitive: false,
        ).firstMatch(nameWithoutExt);
        final epNum = episodeNumberMatch != null
            ? int.tryParse(episodeNumberMatch.group(1) ?? '')
            : null;

        return ParsedMediaInfo(
          type: ParsedMediaType.tvEpisode,
          title: showTitle,
          seasonNumber: 0, // Season 0 for Specials / Extras
          episodeNumber: epNum,
          episodeTitle: extraTitle.isNotEmpty ? extraTitle : nameWithoutExt,
          resolution: resolution,
          videoCodec: videoCodec,
          audioCodec: audioCodec,
          audioChannels: audioChannels,
          rawFilename: rawFilename,
          relativePath: relativePath,
          fileSize: fileSize,
          extension: ext,
        );
      }
    }

    // 4. Fallback to Movie
    int? year;
    String rawTitle = nameWithoutExt;

    final yearMatches = _yearPattern.allMatches(nameWithoutExt).toList();
    if (yearMatches.isNotEmpty) {
      final lastYearMatch = yearMatches.last;
      year = int.tryParse(lastYearMatch.group(1) ?? '');
      rawTitle = nameWithoutExt.substring(0, lastYearMatch.start);
    }

    var cleanTitle = _cleanTitle(rawTitle);
    if (cleanTitle.isEmpty || _isGenericName(cleanTitle)) {
      // If filename is just year or generic, check parent directory name
      final parentDir = p.basename(p.dirname(relativePath));
      if (parentDir.isNotEmpty && parentDir != '.' && parentDir != '/') {
        final parentYearMatches = _yearPattern.allMatches(parentDir).toList();
        if (parentYearMatches.isNotEmpty) {
          final lastParentYear = parentYearMatches.last;
          year ??= int.tryParse(lastParentYear.group(1) ?? '');
          final parentWithoutYear = parentDir.substring(
            0,
            lastParentYear.start,
          );
          final parentClean = _cleanTitle(parentWithoutYear);
          if (parentClean.isNotEmpty) {
            cleanTitle = parentClean;
          }
        } else {
          final parentClean = _cleanTitle(parentDir);
          if (parentClean.isNotEmpty) {
            cleanTitle = parentClean;
          }
        }
      }
    }

    if (cleanTitle.isEmpty) {
      cleanTitle = nameWithoutExt;
    }

    return ParsedMediaInfo(
      type: ParsedMediaType.movie,
      title: cleanTitle,
      year: year,
      resolution: resolution,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      audioChannels: audioChannels,
      rawFilename: rawFilename,
      relativePath: relativePath,
      fileSize: fileSize,
      extension: ext,
    );
  }

  /// Traverses path segments upwards to discover the TV Show name,
  /// skipping "Season XX", "Specials", or "Extras" directories.
  String _findShowTitleFromPath(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();

    // Remove filename segment
    if (segments.isNotEmpty) {
      segments.removeLast();
    }

    for (var i = segments.length - 1; i >= 0; i--) {
      final seg = segments[i];
      final isNonShowFolder = RegExp(
        r'^(?:season|s)\s*\d+$|^specials?$|^extras?$|^bonus$|^featurettes?$|^behind\s*the\s*scenes$|^deleted\s*scenes?$|^got\s*s\d+$|^thf\s*s\d+$',
        caseSensitive: false,
      ).hasMatch(seg);
      if (!isNonShowFolder) {
        final clean = _cleanTitle(seg);
        if (clean.isNotEmpty) {
          return clean;
        }
      }
    }
    return '';
  }

  bool _isGenericName(String name) {
    final lower = name.toLowerCase().trim();
    return lower == 'cd1' ||
        lower == 'cd2' ||
        lower == 'part1' ||
        lower == 'part2' ||
        lower == 'movie' ||
        lower == 'film' ||
        lower == 'video';
  }

  String _cleanTitle(String raw) {
    var title = raw;

    // Remove release group suffixes (e.g. -SPARKS, -YIFY)
    title = title.replaceAll(_releaseGroups, '');

    // Remove junk tokens
    title = title.replaceAll(_garbageTokens, ' ');
    title = title.replaceAll(_resolutionPattern, ' ');
    title = title.replaceAll(_videoCodecPattern, ' ');
    title = title.replaceAll(_audioCodecPattern, ' ');
    title = title.replaceAll(_audioChannelsPattern, ' ');

    // Replace dots, underscores, hyphens with spaces
    title = title.replaceAll(RegExp(r'[._]'), ' ');
    title = title.replaceAll(RegExp(r'\s*-\s*'), ' ');

    // Remove remaining brackets or lingering symbols
    title = title.replaceAll(RegExp(r'[\[\]\(\)\{\}]'), ' ');

    // Collapse multiple whitespace
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return title;
  }

  String _cleanEpisodeTitle(String rest) {
    var s = rest.replaceAll(_releaseGroups, '');
    s = s.replaceAll(_garbageTokens, ' ');
    s = s.replaceAll(_resolutionPattern, ' ');
    s = s.replaceAll(_videoCodecPattern, ' ');
    s = s.replaceAll(_audioCodecPattern, ' ');
    s = s.replaceAll(_audioChannelsPattern, ' ');
    s = s.replaceAll(RegExp(r'[._]'), ' ');
    s = s.replaceAll(RegExp(r'\s*-\s*'), ' ');
    s = s.replaceAll(RegExp(r'[\[\]\(\)\{\}]'), ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _extractResolution(String text) {
    final match = _resolutionPattern.firstMatch(text);
    if (match == null) return null;
    final val = match.group(1)?.toLowerCase();
    if (val == '4k' || val == 'uhd') return '4K';
    if (val == '2160p') return '2160p';
    if (val == '1080p') return '1080p';
    if (val == '1080i') return '1080i';
    if (val == '720p') return '720p';
    if (val == '576p') return '576p';
    if (val == '480p') return '480p';
    return match.group(1);
  }

  String? _extractVideoCodec(String text) {
    final match = _videoCodecPattern.firstMatch(text);
    if (match == null) return null;
    final val = match.group(1)?.toLowerCase();
    if (val == 'x265' || val == 'h265' || val == 'hevc') return 'HEVC';
    if (val == 'x264' || val == 'h264' || val == 'avc') return 'AVC';
    if (val == 'av1') return 'AV1';
    if (val == 'xvid' || val == 'divx') return 'MPEG-4';
    if (val == 'vp9') return 'VP9';
    return match.group(1);
  }

  String? _extractAudioCodec(String text) {
    final match = _audioCodecPattern.firstMatch(text);
    if (match == null) return null;
    final val = match.group(1)?.toLowerCase();
    if (val == 'dts-hd') return 'DTS-HD';
    if (val == 'dts') return 'DTS';
    if (val == 'truehd') return 'TrueHD';
    if (val == 'atmos') return 'Dolby Atmos';
    if (val == 'eac3' || val == 'ddp') return 'E-AC3';
    if (val == 'ac3') return 'AC3';
    if (val == 'aac') return 'AAC';
    if (val == 'flac') return 'FLAC';
    if (val == 'mp3') return 'MP3';
    return match.group(1)?.toUpperCase();
  }

  String? _extractAudioChannels(String text) {
    final match = _audioChannelsPattern.firstMatch(text);
    if (match == null) return null;
    final val = match.group(1)?.toLowerCase();
    if (val == 'stereo') return '2.0';
    return match.group(1);
  }
}
