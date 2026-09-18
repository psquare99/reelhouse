import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reelhouse/domain/metadata/image_cache_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';

class MockLocalStorageManager implements LocalStorageManager {
  final String testPath;
  MockLocalStorageManager(this.testPath);

  @override
  Future<String> getLocalMediaDirectoryPath() async => testPath;

  @override
  Future<int> getAvailableDeviceStorageBytes() async => 50000000;

  @override
  Future<int> getTotalDeviceStorageBytes() async => 100000000;

  @override
  Future<int> getUsedOfflineStorageBytes() async => 0;

  @override
  Future<String> resolveLocalPath(String relativePath) async =>
      '$testPath/$relativePath';

  @override
  Future<bool> verifyLocalCopyIntegrity(
    String relativePath,
    int expectedBytes,
  ) async => true;

  @override
  Future<bool> deleteLocalCopy(String relativePath) async => true;
}

void main() {
  late Directory tempDir;
  late MockLocalStorageManager storageManager;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('reelhouse_img_test_');
    storageManager = MockLocalStorageManager(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('cachePoster downloads and writes file locally, then reuses without re-downloading', () async {
    var downloadCount = 0;
    final mockClient = MockClient((request) async {
      downloadCount++;
      return http.Response.bytes([1, 2, 3, 4], 200);
    });

    final imageService = ImageCacheService(
      localStorageManager: storageManager,
      httpClient: mockClient,
    );

    // 1. Initial download
    final path1 = await imageService.cachePoster(
      'https://image.tmdb.org/t/p/w500/test.jpg',
      'movie_1',
    );
    expect(path1, isNotNull);
    expect(File(path1!).existsSync(), isTrue);
    expect(File(path1).lengthSync(), 4);
    expect(downloadCount, 1);

    // 2. Second request should hit local file cache
    final path2 = await imageService.cachePoster(
      'https://image.tmdb.org/t/p/w500/test.jpg',
      'movie_1',
    );
    expect(path2, path1);
    expect(downloadCount, 1); // No second HTTP request!
  });

  test('handles network failure gracefully by returning null', () async {
    final mockClient = MockClient((request) async {
      return http.Response('Not Found', 404);
    });

    final imageService = ImageCacheService(
      localStorageManager: storageManager,
      httpClient: mockClient,
    );

    final path = await imageService.cachePoster(
      'https://image.tmdb.org/t/p/w500/missing.jpg',
      'movie_missing',
    );
    expect(path, isNull);
  });
}
