import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../services/local_storage_manager.dart';

/// Service responsible for downloading and persistently caching poster and backdrop images locally.
///
/// Implements Section 15 and Principle 2.5:
/// All images are stored on the local device filesystem so browsing never requires repeated network requests.
class ImageCacheService {
  final LocalStorageManager localStorageManager;
  final http.Client _httpClient;

  ImageCacheService({
    required this.localStorageManager,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Downloads and caches a poster image, returning the absolute local file path.
  ///
  /// If the image has already been cached, returns the local path immediately without network traffic.
  Future<String?> cachePoster(String? remoteUrl, String entityKey) async {
    return _cacheImage(
      remoteUrl: remoteUrl,
      subfolder: 'posters',
      filename: '$entityKey.jpg',
    );
  }

  /// Downloads and caches a backdrop image, returning the absolute local file path.
  Future<String?> cacheBackdrop(String? remoteUrl, String entityKey) async {
    return _cacheImage(
      remoteUrl: remoteUrl,
      subfolder: 'backdrops',
      filename: '$entityKey.jpg',
    );
  }

  Future<String?> _cacheImage({
    required String? remoteUrl,
    required String subfolder,
    required String filename,
  }) async {
    if (remoteUrl == null || remoteUrl.trim().isEmpty) {
      return null;
    }

    if (kIsWeb) {
      // In Web browsers, direct filesystem writing is not available; return remote URL
      return remoteUrl;
    }

    try {
      final baseDir = await localStorageManager.getLocalMediaDirectoryPath();
      final cacheDir = Directory(p.join(baseDir, 'metadata_cache', subfolder));
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      final targetFile = File(p.join(cacheDir.path, filename));

      // 1. Return immediately if already cached
      if (targetFile.existsSync() && targetFile.lengthSync() > 0) {
        return targetFile.path;
      }

      // 2. Download from remote URL
      final uri = Uri.tryParse(remoteUrl);
      if (uri == null) return null;

      final response = await _httpClient.get(uri);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await targetFile.writeAsBytes(response.bodyBytes);
        return targetFile.path;
      }
    } catch (_) {
      // Graceful offline fallback: return null
    }

    return null;
  }

  void dispose() {
    _httpClient.close();
  }
}
