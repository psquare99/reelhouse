import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/data/network/tmdb_api_client.dart';
import 'package:reelhouse/domain/metadata/image_cache_service.dart';
import 'package:reelhouse/domain/metadata/metadata_matcher.dart';
import 'package:reelhouse/domain/metadata/metadata_service.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/presentation/settings/needs_verification_screen.dart';

class FakeLocalStorageManager implements LocalStorageManager {
  @override
  Future<String> getLocalMediaDirectoryPath() async => '/fake/offline_media';

  @override
  Future<int> getAvailableDeviceStorageBytes() async => 1000000;

  @override
  Future<int> getTotalDeviceStorageBytes() async => 2000000;

  @override
  Future<int> getUsedOfflineStorageBytes() async => 0;

  @override
  Future<String> resolveLocalPath(String relativePath) async =>
      '/fake/offline_media/$relativePath';

  @override
  Future<bool> verifyLocalCopyIntegrity(
    String relativePath,
    int expectedBytes,
  ) async => true;

  @override
  Future<bool> deleteLocalCopy(String relativePath) async => true;
}

void main() {
  late AppDatabase db;
  late MetadataService metadataService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    metadataService = MetadataService(
      database: db,
      tmdbClient: TmdbApiClient(apiKey: 'fake_key'),
      matcher: const MetadataMatcher(),
      imageCacheService: ImageCacheService(
        localStorageManager: FakeLocalStorageManager(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'NeedsVerificationScreen shows empty state when all media is verified',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NeedsVerificationScreen(
            database: db,
            metadataService: metadataService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Needs Verification'), findsOneWidget);
      expect(find.text('No Movies Need Verification'), findsOneWidget);

      // Switch to TV Shows tab
      await tester.tap(find.text('TV Shows'));
      await tester.pumpAndSettle();

      expect(find.text('No TV Shows Need Verification'), findsOneWidget);

      // Unmount and flush Drift stream cancel timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'NeedsVerificationScreen renders unmatched movie and presents resolve option',
    (WidgetTester tester) async {
      // Insert an unmatched movie
      await db
          .into(db.movies)
          .insert(
            MoviesCompanion.insert(
              id: 'm-unmatched',
              detectedTitle: 'The Thing',
              title: const drift.Value('The Thing'),
              year: const drift.Value(1982),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          home: NeedsVerificationScreen(
            database: db,
            metadataService: metadataService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('The Thing'), findsOneWidget);
      expect(find.text('(1982)'), findsOneWidget);
      expect(find.text('Resolve'), findsOneWidget);

      // Unmount and flush Drift stream cancel timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
