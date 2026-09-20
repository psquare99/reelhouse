import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/domain/services/local_storage_manager.dart';
import 'package:reelhouse/domain/services/storage_identity_service.dart';
import 'package:reelhouse/main.dart';

class FakeStorageIdentityService implements StorageIdentityService {
  @override
  Future<String> getFilesystemIdentifier(String rootUriOrPath) async =>
      'fake-id';

  @override
  Future<String> getStorageDisplayName(String rootUriOrPath) async =>
      'Fake Storage';

  @override
  Future<bool> isStorageConnected(String rootUriOrPath) async => true;

  @override
  Future<String?> readMarkerIdentifier(String rootUriOrPath) async => null;

  @override
  Future<void> writeMarkerIdentifier(
    String rootUriOrPath,
    String storageId,
  ) async {}
}

class FakeLocalStorageManager implements LocalStorageManager {
  @override
  Future<String> getLocalMediaDirectoryPath() async => '/fake/offline_media';

  @override
  Future<int> getAvailableDeviceStorageBytes() async => 64 * 1024 * 1024 * 1024;

  @override
  Future<int> getTotalDeviceStorageBytes() async => 128 * 1024 * 1024 * 1024;

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
  testWidgets('ReelhouseApp renders cinema branding and shell', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final fakeIdentity = FakeStorageIdentityService();
    final fakeStorage = FakeLocalStorageManager();

    await tester.pumpWidget(
      ReelhouseApp(
        database: db,
        storageIdentityService: fakeIdentity,
        localStorageManager: fakeStorage,
      ),
    );

    await tester.pumpAndSettle();

    // Verify cinematic header
    expect(find.text('MATINEE'), findsAtLeastNWidgets(1));
    expect(find.text('Personal Digital Cinema'), findsOneWidget);
    expect(find.text('EXPLORE CINEMA'), findsOneWidget);

    await db.close();
  });
}
