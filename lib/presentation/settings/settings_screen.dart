import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/cinema_colors.dart';
import '../../data/database/database.dart';
import '../../domain/services/local_storage_manager.dart';
import '../../domain/services/storage_identity_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppDatabase database;
  final StorageIdentityService storageIdentityService;
  final LocalStorageManager localStorageManager;

  const SettingsScreen({
    super.key,
    required this.database,
    required this.storageIdentityService,
    required this.localStorageManager,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _usedBytes = 0;
  int _availableBytes = 0;

  @override
  void initState() {
    super.initState();
    _refreshStorageStats();
  }

  Future<void> _refreshStorageStats() async {
    final used = await widget.localStorageManager.getUsedOfflineStorageBytes();
    final avail = await widget.localStorageManager
        .getAvailableDeviceStorageBytes();
    if (mounted) {
      setState(() {
        _usedBytes = used;
        _availableBytes = avail;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _showAddStorageDialog() async {
    final pathController = TextEditingController();
    final nameController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: CinemaColors.card,
          title: const Text(
            'Add Storage Location',
            style: TextStyle(color: CinemaColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pathController,
                decoration: const InputDecoration(
                  labelText: 'Root Path or Document URI',
                  hintText: r'e.g. D:\Movies or content://...',
                  labelStyle: TextStyle(color: CinemaColors.textSecondary),
                ),
                style: const TextStyle(color: CinemaColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name (optional)',
                  hintText: 'e.g. Movies HDD',
                  labelStyle: TextStyle(color: CinemaColors.textSecondary),
                ),
                style: const TextStyle(color: CinemaColors.textPrimary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: CinemaColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final path = pathController.text.trim();
                if (path.isEmpty) return;

                Navigator.of(dialogCtx).pop();

                final fsId = await widget.storageIdentityService
                    .getFilesystemIdentifier(path);
                final autoName = await widget.storageIdentityService
                    .getStorageDisplayName(path);
                final chosenName = nameController.text.trim().isNotEmpty
                    ? nameController.text.trim()
                    : autoName;
                final isConn = await widget.storageIdentityService
                    .isStorageConnected(path);

                final newStorage = StoragesCompanion.insert(
                  id: const Uuid().v4(),
                  name: chosenName,
                  storageType: 'REMOVABLE_VOLUME',
                  filesystemIdentifier: fsId,
                  rootUri: path,
                  lastSeenAt: DateTime.now(),
                  available: drift.Value(isConn),
                );

                await widget.database.upsertStorage(newStorage);
              },
              child: const Text('Add Storage'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        children: [
          // Section: Registered Storage Locations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STORAGE LOCATIONS',
                style: TextStyle(
                  color: CinemaColors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showAddStorageDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Location'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          StreamBuilder<List<Storage>>(
            stream: widget.database.watchAllStorages(),
            builder: (context, snapshot) {
              final storages = snapshot.data ?? [];
              if (storages.isEmpty) {
                return const Text(
                  'Loading storages...',
                  style: TextStyle(color: CinemaColors.textMuted),
                );
              }

              return Column(
                children: storages.map((storage) {
                  final isLocal = storage.storageType == 'DEVICE_LOCAL_STORAGE';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            isLocal
                                ? Icons.tablet_android
                                : Icons.storage_rounded,
                            color: storage.available
                                ? CinemaColors.amber
                                : CinemaColors.textMuted,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      storage.name,
                                      style: const TextStyle(
                                        color: CinemaColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CinemaColors.surface,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: CinemaColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        isLocal
                                            ? 'DEVICE STORAGE'
                                            : 'EXTERNAL DISK',
                                        style: const TextStyle(
                                          color: CinemaColors.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  storage.rootUri.isNotEmpty
                                      ? storage.rootUri
                                      : 'Application-managed offline storage',
                                  style: const TextStyle(
                                    color: CinemaColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${storage.filesystemIdentifier}',
                                  style: const TextStyle(
                                    color: CinemaColors.textMuted,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: storage.available
                                          ? CinemaColors.statusAvailable
                                          : CinemaColors.statusUnavailable,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    storage.available
                                        ? 'Connected'
                                        : 'Disconnected',
                                    style: TextStyle(
                                      color: storage.available
                                          ? CinemaColors.statusAvailable
                                          : CinemaColors.statusUnavailable,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isLocal) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    // Toggle connection status for testing/simulation
                                    await (widget.database.update(
                                          widget.database.storages,
                                        )..where(
                                          (s) => s.id.equals(storage.id),
                                        ))
                                        .write(
                                          StoragesCompanion(
                                            available: drift.Value(
                                              !storage.available,
                                            ),
                                          ),
                                        );
                                  },
                                  child: Text(
                                    storage.available
                                        ? 'Simulate Disconnect'
                                        : 'Simulate Reconnect',
                                    style: const TextStyle(
                                      color: CinemaColors.amber,
                                      fontSize: 11,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),

          // Section: Device Offline Storage Capacity
          const Text(
            'THIS DEVICE (OFFLINE STORAGE)',
            style: TextStyle(
              color: CinemaColors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Offline Media Storage',
                        style: TextStyle(
                          color: CinemaColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_formatBytes(_usedBytes)} used / ${_formatBytes(_availableBytes)} free',
                        style: const TextStyle(
                          color: CinemaColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _availableBytes > 0
                        ? (_usedBytes / (_usedBytes + _availableBytes)).clamp(
                            0.0,
                            1.0,
                          )
                        : 0.0,
                    backgroundColor: CinemaColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      CinemaColors.amber,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Offline copies are stored in an application-managed directory. Deleting a local offline copy frees device space without deleting the original HDD media or removing it from your cinema.',
                    style: TextStyle(
                      color: CinemaColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Section: Playback Player Preference
          const Text(
            'PLAYBACK HANDOFF',
            style: TextStyle(
              color: CinemaColors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    color: CinemaColors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferred Media Player',
                          style: TextStyle(
                            color: CinemaColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'System Default / VLC Media Player',
                          style: TextStyle(
                            color: CinemaColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(onPressed: () {}, child: const Text('Change')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Section: About
          const Center(
            child: Text(
              'REELHOUSE v1.0 • Personal Digital Cinema\nBuild the cinema layer. Do not build Plex.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CinemaColors.textMuted,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
