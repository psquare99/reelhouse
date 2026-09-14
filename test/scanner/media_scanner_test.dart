import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reelhouse/domain/scanner/media_scanner.dart';
import 'package:reelhouse/domain/scanner/parsed_media_info.dart';

void main() {
  late Directory tempDir;
  late MediaScanner scanner;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('reelhouse_scan_test_');
    scanner = const MediaScanner();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void createTestFile(String relativePath, [int sizeBytes = 1024]) {
    final fullPath = p.join(tempDir.path, relativePath);
    final file = File(fullPath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(List.filled(sizeBytes, 0));
  }

  test(
    'MediaScanner discovers media files and ignores non-media & samples',
    () async {
      // 1. Valid movie files
      createTestFile('Interstellar.2014.1080p.mkv', 1024);
      createTestFile(r'Movies\Inception (2010)\Inception.mp4', 2048);

      // 2. Valid TV episode file
      createTestFile(r'TV\Breaking Bad\Season 1\S01E01.Pilot.mkv', 4096);

      // 3. Ignored files
      createTestFile('movie.nfo', 100);
      createTestFile('subtitles.srt', 200);
      createTestFile('.hidden_video.mkv', 1024);
      createTestFile(r'$RECYCLE.BIN\deleted.mkv', 1024);
      createTestFile('sample.mkv', 500); // sample file under 350MB is ignored

      final discovered = await scanner.scanDirectory(rootPath: tempDir.path);

      expect(discovered.length, 3);

      final filenames = discovered
          .map((d) => d.parsedInfo.rawFilename)
          .toList();
      expect(filenames, contains('Interstellar.2014.1080p.mkv'));
      expect(filenames, contains('Inception.mp4'));
      expect(filenames, contains('S01E01.Pilot.mkv'));

      final tvEpisode = discovered.firstWhere((d) => d.parsedInfo.isTvEpisode);
      expect(tvEpisode.parsedInfo.title, 'Breaking Bad');
      expect(tvEpisode.parsedInfo.seasonNumber, 1);
      expect(tvEpisode.parsedInfo.episodeNumber, 1);
    },
  );

  test('MediaScanner scanStream emits items with progress callback', () async {
    createTestFile('Fight Club (1999).mp4', 1024);
    createTestFile('The Matrix (1999).mkv', 1024);

    final progressReports = <String>[];
    final items = <DiscoveredMediaFile>[];

    await for (final item in scanner.scanStream(
      rootPath: tempDir.path,
      onProgress: (currentPath, count) {
        progressReports.add('$count: $currentPath');
      },
    )) {
      items.add(item);
    }

    expect(items.length, 2);
    expect(progressReports.length, 2);
    expect(
      items.every((i) => i.parsedInfo.type == ParsedMediaType.movie),
      isTrue,
    );
  });
}
