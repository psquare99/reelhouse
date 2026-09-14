import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/models/playback_resolution.dart';
import 'package:reelhouse/domain/services/availability_resolver.dart';
import 'package:reelhouse/domain/services/playback_source_resolver.dart';

void main() {
  group('PlaybackSourceResolver', () {
    const resolver = PlaybackSourceResolver();

    test('Priority 1: prefers device-local offline copy when present', () {
      final sources = [
        const SourceCheckInfo(
          sourceId: 'src-removable',
          sourceType: 'removableStorage',
          isSourceAvailable: true,
          storageId: 'hdd-1',
          storageName: 'Movies HDD',
          isStorageConnected: true,
        ),
        const SourceCheckInfo(
          sourceId: 'src-local',
          sourceType: 'localDevice',
          isSourceAvailable: true,
          storageId: 'local-device',
          storageName: 'This Device',
          isStorageConnected: true,
        ),
      ];

      final resolution = resolver.resolve(sources);
      expect(resolution.action, PlaybackAction.playOffline);
      expect(resolution.selectedSourceId, 'src-local');
      expect(resolution.buttonLabel, 'PLAY OFFLINE');
      expect(resolution.isPlayable, true);
    });

    test('Priority 2: falls back to connected external HDD when local copy is absent', () {
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

      final resolution = resolver.resolve(sources);
      expect(resolution.action, PlaybackAction.play);
      expect(resolution.selectedSourceId, 'src-removable');
      expect(resolution.buttonLabel, 'PLAY');
      expect(resolution.isPlayable, true);
    });

    test(
      'Priority 3: prompts to connect external storage when neither available',
      () {
        final sources = [
          const SourceCheckInfo(
            sourceId: 'src-removable',
            sourceType: 'removableStorage',
            isSourceAvailable: true,
            storageId: 'hdd-1',
            storageName: 'Movies HDD',
            isStorageConnected: false, // Disconnected!
          ),
        ];

        final resolution = resolver.resolve(sources);
        expect(resolution.action, PlaybackAction.connectDisk);
        expect(resolution.buttonLabel, 'CONNECT Movies HDD');
        expect(resolution.isPlayable, false);
      },
    );

    test('Empty sources list returns connect disk without crashing', () {
      final resolution = resolver.resolve([]);
      expect(resolution.action, PlaybackAction.connectDisk);
      expect(resolution.buttonLabel, 'CONNECT DISK');
      expect(resolution.isPlayable, false);
    });
  });
}
