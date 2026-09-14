import 'dart:async';

import '../../data/database/database.dart';
import 'storage_identity_service.dart';

/// Event emitted when a storage location connects or disconnects.
class StorageConnectivityEvent {
  final Storage storage;
  final bool isConnected;
  final DateTime timestamp;

  const StorageConnectivityEvent({
    required this.storage,
    required this.isConnected,
    required this.timestamp,
  });
}

/// Service that actively monitors connection states of registered storage devices
/// and cascades availability changes to physical media sources.
class StorageMonitorService {
  final AppDatabase database;
  final StorageIdentityService storageIdentityService;

  Timer? _pollingTimer;
  final _eventController =
      StreamController<StorageConnectivityEvent>.broadcast();

  StorageMonitorService({
    required this.database,
    required this.storageIdentityService,
  });

  /// Stream of connectivity events for reactive UI updates.
  Stream<StorageConnectivityEvent> get onConnectivityChanged =>
      _eventController.stream;

  /// Starts periodic background polling of all storage locations.
  void startMonitoring({Duration interval = const Duration(seconds: 10)}) {
    stopMonitoring();
    _pollingTimer = Timer.periodic(interval, (_) => checkAllStorages());
  }

  /// Stops periodic polling.
  void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Checks the connectivity status of all registered storages immediately.
  Future<void> checkAllStorages() async {
    final storages = await database.getAllStorages();
    final now = DateTime.now();

    for (final storage in storages) {
      // Local device storage is built-in and always connected
      if (storage.storageType == 'DEVICE_LOCAL_STORAGE') {
        if (!storage.available) {
          await database.updateStorageStatus(
            storage.id,
            available: true,
            lastSeenAt: now,
          );
        }
        continue;
      }

      final isCurrentlyConnected = await storageIdentityService
          .isStorageConnected(storage.rootUri);

      if (isCurrentlyConnected != storage.available) {
        // Status changed!
        await database.updateStorageStatus(
          storage.id,
          available: isCurrentlyConnected,
          lastSeenAt: now,
        );

        if (!isCurrentlyConnected) {
          // Drive disconnected: mark all its physical sources unavailable
          await database.setAllSourcesAvailableForStorage(storage.id, false);
        } else {
          // Drive reconnected: mark sources on this drive available
          await database.setAllSourcesAvailableForStorage(storage.id, true);
        }

        final updatedStorage = storage.copyWith(
          available: isCurrentlyConnected,
          lastSeenAt: now,
        );

        _eventController.add(
          StorageConnectivityEvent(
            storage: updatedStorage,
            isConnected: isCurrentlyConnected,
            timestamp: now,
          ),
        );
      }
    }
  }

  /// Disposes resources and closes streams.
  void dispose() {
    stopMonitoring();
    _eventController.close();
  }
}
