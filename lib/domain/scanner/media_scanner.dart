import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'filename_parser.dart';
import 'parsed_media_info.dart';

/// A media file discovered on a storage device.
class DiscoveredMediaFile {
  final String relativePath;
  final String fullPath;
  final int fileSize;
  final ParsedMediaInfo parsedInfo;

  const DiscoveredMediaFile({
    required this.relativePath,
    required this.fullPath,
    required this.fileSize,
    required this.parsedInfo,
  });

  @override
  String toString() =>
      'DiscoveredMediaFile($relativePath, ${fileSize ~/ (1024 * 1024)}MB, ${parsedInfo.title})';
}

/// Non-blocking recursive media scanner for registered storage locations.
class MediaScanner {
  final FilenameParser parser;

  const MediaScanner({this.parser = const FilenameParser()});

  /// Directories and file prefixes to unconditionally skip during scanning.
  static const Set<String> _skipDirectories = {
    r'$recycle.bin',
    r'system volume information',
    '.git',
    '.trash',
    '.trashes',
    '.temporaryitems',
    '.appdata',
    '.android',
    'lost+found',
    'node_modules',
  };

  /// Scans [rootPath] recursively and yields [DiscoveredMediaFile]s as they are discovered.
  ///
  /// Runs without blocking UI frames. On desktop/mobile platforms, can utilize background isolates.
  Stream<DiscoveredMediaFile> scanStream({
    required String rootPath,
    void Function(String currentPath, int discoveredCount)? onProgress,
  }) async* {
    if (kIsWeb) {
      // Web environments do not have direct filesystem access
      return;
    }

    final rootDir = Directory(rootPath);
    if (!rootDir.existsSync()) {
      return;
    }

    var count = 0;
    final normalizedRoot = p.normalize(rootPath);

    await for (final entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;

      final fullPath = entity.path;
      final filename = p.basename(fullPath);

      // 1. Skip hidden files
      if (filename.startsWith('.') || filename.startsWith('._')) {
        continue;
      }

      // 2. Check if file is within a skipped system directory
      final relPath = p.relative(fullPath, from: normalizedRoot);
      if (_isWithinSkippedDirectory(relPath)) {
        continue;
      }

      // 3. Verify media extension
      if (!FilenameParser.isSupportedMediaFile(filename)) {
        continue;
      }

      // 4. File size & sample check
      int fileSize = 0;
      try {
        fileSize = await entity.length();
      } catch (_) {
        // Skip unreadable files
        continue;
      }

      if (FilenameParser.isSampleFile(filename, fileSize)) {
        continue;
      }

      // 5. Parse metadata from filename and directory structure
      final parsed = parser.parse(relativePath: relPath, fileSize: fileSize);

      count++;
      onProgress?.call(filename, count);

      yield DiscoveredMediaFile(
        relativePath: relPath,
        fullPath: fullPath,
        fileSize: fileSize,
        parsedInfo: parsed,
      );
    }
  }

  /// Non-blocking scan that collects all media files in [rootPath].
  ///
  /// Uses a background isolate when supported to prevent any UI stutter
  /// when inspecting drives with tens of thousands of items.
  Future<List<DiscoveredMediaFile>> scanDirectory({
    required String rootPath,
    void Function(String currentPath, int discoveredCount)? onProgress,
  }) async {
    if (kIsWeb) {
      return [];
    }

    // Try background isolate execution
    try {
      return await _scanWithIsolate(rootPath, onProgress);
    } catch (_) {
      // Fallback to async stream scan
      final results = <DiscoveredMediaFile>[];
      await for (final file in scanStream(
        rootPath: rootPath,
        onProgress: onProgress,
      )) {
        results.add(file);
      }
      return results;
    }
  }

  Future<List<DiscoveredMediaFile>> _scanWithIsolate(
    String rootPath,
    void Function(String currentPath, int discoveredCount)? onProgress,
  ) async {
    final receivePort = ReceivePort();
    final completer = Completer<List<DiscoveredMediaFile>>();
    final results = <DiscoveredMediaFile>[];

    final isolate = await Isolate.spawn(
      _isolateScannerEntryPoint,
      _IsolateScanMessage(sendPort: receivePort.sendPort, rootPath: rootPath),
    );

    receivePort.listen((dynamic message) {
      if (message is _DiscoveredFileTransfer) {
        final parsed = parser.parse(
          relativePath: message.relativePath,
          fileSize: message.fileSize,
        );
        final item = DiscoveredMediaFile(
          relativePath: message.relativePath,
          fullPath: message.fullPath,
          fileSize: message.fileSize,
          parsedInfo: parsed,
        );
        results.add(item);
        onProgress?.call(p.basename(message.fullPath), results.length);
      } else if (message is _ScanDoneTransfer) {
        receivePort.close();
        isolate.kill();
        completer.complete(results);
      } else if (message is _ScanErrorTransfer) {
        receivePort.close();
        isolate.kill();
        completer.completeError(Exception(message.error));
      }
    });

    return completer.future;
  }

  static bool _isWithinSkippedDirectory(String relativePath) {
    final segments = p.split(relativePath.toLowerCase());
    for (final seg in segments) {
      if (_skipDirectories.contains(seg)) {
        return true;
      }
    }
    return false;
  }
}

class _IsolateScanMessage {
  final SendPort sendPort;
  final String rootPath;

  _IsolateScanMessage({required this.sendPort, required this.rootPath});
}

class _DiscoveredFileTransfer {
  final String relativePath;
  final String fullPath;
  final int fileSize;

  _DiscoveredFileTransfer({
    required this.relativePath,
    required this.fullPath,
    required this.fileSize,
  });
}

class _ScanDoneTransfer {
  const _ScanDoneTransfer();
}

class _ScanErrorTransfer {
  final String error;
  _ScanErrorTransfer(this.error);
}

void _isolateScannerEntryPoint(_IsolateScanMessage message) {
  final sendPort = message.sendPort;
  final rootPath = message.rootPath;

  try {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) {
      sendPort.send(const _ScanDoneTransfer());
      return;
    }

    final normalizedRoot = p.normalize(rootPath);

    final entities = dir.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is! File) continue;

      final filename = p.basename(entity.path);
      if (filename.startsWith('.') || filename.startsWith('._')) continue;

      final relPath = p.relative(entity.path, from: normalizedRoot);
      if (MediaScanner._isWithinSkippedDirectory(relPath)) continue;

      if (!FilenameParser.isSupportedMediaFile(filename)) continue;

      final size = entity.lengthSync();
      if (FilenameParser.isSampleFile(filename, size)) continue;

      sendPort.send(
        _DiscoveredFileTransfer(
          relativePath: relPath,
          fullPath: entity.path,
          fileSize: size,
        ),
      );
    }

    sendPort.send(const _ScanDoneTransfer());
  } catch (e) {
    sendPort.send(_ScanErrorTransfer(e.toString()));
  }
}
