import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/scanner/filename_parser.dart';
import 'package:reelhouse/domain/scanner/parsed_media_info.dart';

void main() {
  const parser = FilenameParser();

  group('FilenameParser — Movie Tests', () {
    test('parses standard movie with year, resolution, source, and codec', () {
      final result = parser.parse(
        relativePath: 'Interstellar.2014.1080p.BluRay.x265.mkv',
        fileSize: 2500000000,
      );

      expect(result.type, ParsedMediaType.movie);
      expect(result.title, 'Interstellar');
      expect(result.year, 2014);
      expect(result.resolution, '1080p');
      expect(result.videoCodec, 'HEVC');
      expect(result.extension, 'mkv');
    });

    test('parses 4K UHD Atmos movie', () {
      final result = parser.parse(
        relativePath: r'Movies\The.Matrix.1999.2160p.UHD.HDR.HEVC.TrueHD.7.1.Atmos-SPARKS.mkv',
        fileSize: 45000000000,
      );

      expect(result.type, ParsedMediaType.movie);
      expect(result.title, 'The Matrix');
      expect(result.year, 1999);
      expect(result.resolution, '2160p');
      expect(result.videoCodec, 'HEVC');
      expect(result.audioCodec, 'TrueHD');
      expect(result.audioChannels, '7.1');
    });

    test('parses movie with brackets and dots', () {
      final result = parser.parse(
        relativePath: 'Inception (2010) [1080p] [x264] [AAC 5.1].mp4',
        fileSize: 3100000000,
      );

      expect(result.type, ParsedMediaType.movie);
      expect(result.title, 'Inception');
      expect(result.year, 2010);
      expect(result.resolution, '1080p');
      expect(result.videoCodec, 'AVC');
      expect(result.audioCodec, 'AAC');
      expect(result.audioChannels, '5.1');
      expect(result.extension, 'mp4');
    });

    test('parses movie without year cleanly', () {
      final result = parser.parse(
        relativePath: 'Fight Club.mp4',
        fileSize: 1500000000,
      );

      expect(result.type, ParsedMediaType.movie);
      expect(result.title, 'Fight Club');
      expect(result.year, isNull);
    });

    test('falls back to parent folder when filename is generic cd1', () {
      final result = parser.parse(
        relativePath: r'Pulp Fiction (1994)\cd1.avi',
        fileSize: 700000000,
      );

      expect(result.type, ParsedMediaType.movie);
      expect(result.title, 'Pulp Fiction');
      expect(result.year, 1994);
    });

    test('preserves intra-word hyphens in titles like Ant-Man, Spider-Man, and Nobody-2', () {
      final antMan = parser.parse(
        relativePath: 'MARVEL/13. Ant-Man 2015 BluRay 1080p Hindi English DD 5.1 x264-RARBG.mkv',
        fileSize: 11000000000,
      );
      expect(antMan.title, '13 Ant-Man');
      expect(antMan.year, 2015);

      final spiderMan = parser.parse(
        relativePath: 'THE AMAZING SPIDERMAN/The Amazing Spider-Man 2012 BluRay 1080p x264-Telly.mkv',
        fileSize: 10000000000,
      );
      expect(spiderMan.title, 'The Amazing Spider-Man');
      expect(spiderMan.year, 2012);

      final nobody2 = parser.parse(
        relativePath: 'Nobody-2.2025.1080p.AMZN.WEB-DL.x264-HDHub.mkv',
        fileSize: 5000000000,
      );
      expect(nobody2.title, 'Nobody-2');
      expect(nobody2.year, 2025);
    });

    test('cuts title at technical boundaries when year is omitted', () {
      final shangChi = parser.parse(
        relativePath: 'MARVEL/26. Shang-Chi And The Legend of the Ten Rings 1080p IMAX WEB-DL [DD 5.1 Hindi + DD 5.1 English] x264-UHDMovies [7.3GB].mkv',
        fileSize: 7300000000,
      );
      expect(shangChi.title, '26 Shang-Chi And The Legend of the Ten Rings');
      expect(shangChi.year, isNull);
      expect(shangChi.resolution, '1080p');
    });

    test('correctly parses titles starting with 4-digit numbers adjacent to release year', () {
      final m1917 = parser.parse(
        relativePath: '1917.2019.1080p.BluRay.x264.mkv',
        fileSize: 4000000000,
      );
      expect(m1917.title, '1917');
      expect(m1917.year, 2019);
    });
  });

  group('FilenameParser — TV Series Tests', () {
    test('parses standard SxxExx with episode title and quality', () {
      final result = parser.parse(
        relativePath:
            'Breaking.Bad.S02E03.Bit.by.a.Dead.Bee.1080p.WEB-DL.x264.mkv',
        fileSize: 1200000000,
      );

      expect(result.type, ParsedMediaType.tvEpisode);
      expect(result.title, 'Breaking Bad');
      expect(result.seasonNumber, 2);
      expect(result.episodeNumber, 3);
      expect(result.episodeTitle, 'Bit by a Dead Bee');
      expect(result.resolution, '1080p');
      expect(result.videoCodec, 'AVC');
    });

    test('parses NxNN format (e.g. 1x04)', () {
      final result = parser.parse(
        relativePath: 'The.Wire.1x04.Old.Cases.720p.HDTV.mkv',
        fileSize: 800000000,
      );

      expect(result.type, ParsedMediaType.tvEpisode);
      expect(result.title, 'The Wire');
      expect(result.seasonNumber, 1);
      expect(result.episodeNumber, 4);
      expect(result.resolution, '720p');
    });

    test(
      'resolves show title from grandparent directory with Season folder',
      () {
        final result = parser.parse(
          relativePath: r'Severance\Season 1\S01E01.mkv',
          fileSize: 1500000000,
        );

        expect(result.type, ParsedMediaType.tvEpisode);
        expect(result.title, 'Severance');
        expect(result.seasonNumber, 1);
        expect(result.episodeNumber, 1);
      },
    );

    test('resolves simple episode number inside Season folder', () {
      final result = parser.parse(
        relativePath: r'Succession/Season 3/04.mkv',
        fileSize: 1600000000,
      );

      expect(result.type, ParsedMediaType.tvEpisode);
      expect(result.title, 'Succession');
      expect(result.seasonNumber, 3);
      expect(result.episodeNumber, 4);
    });

    test('parses TV bonus and extras content associating them with parent TV show as Season -1 Extras', () {
      // Game of Thrones Season 2 Extras from user's library
      final nightwatch = parser.parse(
        relativePath: 'GAME OF THRONES/GOT S2/Extras/History- Nightwatch.mkv',
        fileSize: 500000000,
      );
      expect(nightwatch.type, ParsedMediaType.tvEpisode);
      expect(nightwatch.title, 'GAME OF THRONES');
      expect(nightwatch.seasonNumber, -1);
      expect(nightwatch.isExtra, isTrue);
      expect(nightwatch.episodeTitle, 'History- Nightwatch');

      final battle = parser.parse(
        relativePath: 'GAME OF THRONES/GOT S2/Extras/Creating the Battle of Blackwater Bay.mkv',
        fileSize: 800000000,
      );
      expect(battle.type, ParsedMediaType.tvEpisode);
      expect(battle.title, 'GAME OF THRONES');
      expect(battle.seasonNumber, -1);
      expect(battle.isExtra, isTrue);
      expect(battle.episodeTitle, 'Creating the Battle of Blackwater Bay');

      final deletedScene = parser.parse(
        relativePath: 'GAME OF THRONES/GOT S2/Extras/Deleted Scene- Sansa and Clegane.mkv',
        fileSize: 200000000,
      );
      expect(deletedScene.type, ParsedMediaType.tvEpisode);
      expect(deletedScene.title, 'GAME OF THRONES');
      expect(deletedScene.seasonNumber, -1);
      expect(deletedScene.isExtra, isTrue);
      expect(deletedScene.episodeTitle, 'Deleted Scene- Sansa and Clegane');

      // Extras under show root
      final breakingBadExtra = parser.parse(
        relativePath: 'Breaking Bad/Extras/Inside Breaking Bad.mkv',
        fileSize: 400000000,
      );
      expect(breakingBadExtra.type, ParsedMediaType.tvEpisode);
      expect(breakingBadExtra.title, 'Breaking Bad');
      expect(breakingBadExtra.seasonNumber, -1);
      expect(breakingBadExtra.isExtra, isTrue);

      // Bonus under season folder
      final lastOfUsBonus = parser.parse(
        relativePath:
            'The Last of Us/Season 1/Bonus/Making of The Last of Us.mkv',
        fileSize: 600000000,
      );
      expect(lastOfUsBonus.type, ParsedMediaType.tvEpisode);
      expect(lastOfUsBonus.title, 'The Last of Us');
      expect(lastOfUsBonus.seasonNumber, -1);
      expect(lastOfUsBonus.isExtra, isTrue);
    });
  });

  group('FilenameParser — Supported Media & Samples', () {
    test('identifies supported video extensions', () {
      expect(FilenameParser.isSupportedMediaFile('movie.mkv'), isTrue);
      expect(FilenameParser.isSupportedMediaFile('movie.mp4'), isTrue);
      expect(FilenameParser.isSupportedMediaFile('movie.avi'), isTrue);
      expect(FilenameParser.isSupportedMediaFile('movie.mov'), isTrue);
      expect(FilenameParser.isSupportedMediaFile('movie.m4v'), isTrue);
      expect(FilenameParser.isSupportedMediaFile('movie.webm'), isTrue);
      expect(FilenameParser.isSupportedMediaFile('movie.ts'), isTrue);
      expect(FilenameParser.isSupportedMediaFile('movie.wmv'), isTrue);

      expect(FilenameParser.isSupportedMediaFile('subtitle.srt'), isFalse);
      expect(FilenameParser.isSupportedMediaFile('info.nfo'), isFalse);
      expect(FilenameParser.isSupportedMediaFile('cover.jpg'), isFalse);
      expect(FilenameParser.isSupportedMediaFile('.hidden.mkv'), isFalse);
      expect(
        FilenameParser.isSupportedMediaFile('._interstellar.mkv'),
        isFalse,
      );
    });

    test('identifies sample files', () {
      expect(FilenameParser.isSampleFile('sample.mkv', 20000000), isTrue);
      expect(FilenameParser.isSampleFile('movie-sample.mp4', 30000000), isTrue);
      expect(
        FilenameParser.isSampleFile('Interstellar.2014.mkv', 2000000000),
        isFalse,
      );
      // Large file with sample in title shouldn't be dismissed as a small snippet
      expect(
        FilenameParser.isSampleFile('Sampling.The.World.mkv', 500000000),
        isFalse,
      );
    });
  });
}
