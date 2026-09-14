import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/models/availability_status.dart';
import 'package:reelhouse/domain/services/availability_resolver.dart';

void main() {
  group('AvailabilityResolver', () {
    const resolver = AvailabilityResolver();

    test('returns unavailable when sources list is empty', () {
      expect(resolver.resolve([]), AvailabilityStatus.unavailable);
    });

    test(
      'returns availableLocally when only localDevice copy is available',
      () {
        final sources = [
          const SourceCheckInfo(
            sourceId: 'src-local',
            sourceType: 'localDevice',
            isSourceAvailable: true,
            storageId: 'local-device',
            storageName: 'This Device',
            isStorageConnected: true,
          ),
          const SourceCheckInfo(
            sourceId: 'src-removable',
            sourceType: 'removableStorage',
            isSourceAvailable: true,
            storageId: 'hdd-1',
            storageName: 'Movies HDD',
            isStorageConnected: false, // Disconnected!
          ),
        ];

        expect(resolver.resolve(sources), AvailabilityStatus.availableLocally);
      },
    );

    test('returns availableOnRemovableStorage when external HDD is connected and no local copy exists', () {
      final sources = [
        const SourceCheckInfo(
          sourceId: 'src-removable',
          sourceType: 'removableStorage',
          isSourceAvailable: true,
          storageId: 'hdd-1',
          storageName: 'Movies HDD',
          isStorageConnected: true,
        ),
      ];

      expect(
        resolver.resolve(sources),
        AvailabilityStatus.availableOnRemovableStorage,
      );
    });

    test('returns availableOnMultipleSources when both local copy and connected HDD exist', () {
      final sources = [
        const SourceCheckInfo(
          sourceId: 'src-local',
          sourceType: 'localDevice',
          isSourceAvailable: true,
          storageId: 'local-device',
          storageName: 'This Device',
          isStorageConnected: true,
        ),
        const SourceCheckInfo(
          sourceId: 'src-removable',
          sourceType: 'removableStorage',
          isSourceAvailable: true,
          storageId: 'hdd-1',
          storageName: 'Movies HDD',
          isStorageConnected: true,
        ),
      ];

      expect(
        resolver.resolve(sources),
        AvailabilityStatus.availableOnMultipleSources,
      );
    });

    test('returns unavailable when external HDD is disconnected and no local copy exists', () {
      final sources = [
        const SourceCheckInfo(
          sourceId: 'src-removable',
          sourceType: 'removableStorage',
          isSourceAvailable: true,
          storageId: 'hdd-1',
          storageName: 'Movies HDD',
          isStorageConnected: false,
        ),
      ];

      expect(resolver.resolve(sources), AvailabilityStatus.unavailable);
    });
  });
}
