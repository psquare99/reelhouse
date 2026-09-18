import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../data/network/tmdb_api_client.dart';
import '../../data/platform/device_storage_service_impl.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../data/services/transfer_service_impl.dart';
import '../../domain/metadata/image_cache_service.dart';
import '../../domain/metadata/metadata_service.dart';
import '../../domain/repository/library_repository.dart';
import '../../domain/scanner/library_scanner_service.dart';
import '../../domain/services/device_storage_service.dart';
import '../../domain/services/local_storage_manager.dart';
import '../../domain/services/settings_service.dart';
import '../../domain/services/storage_identity_service.dart';
import '../../domain/services/transfer_coordinator.dart';
import '../../domain/services/transfer_service.dart';
import 'needs_verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppDatabase database;
  final LibraryRepository repository;
  final StorageIdentityService storageIdentityService;
  final LocalStorageManager localStorageManager;
  final LibraryScannerService libraryScannerService;
  final DeviceStorageService deviceStorageService;
  final MetadataService? metadataService;
  final SettingsService? settingsService;
  final TransferCoordinator? transferCoordinator;
  final TransferService? transferService;

  SettingsScreen({
    super.key,
    required this.database,
    LibraryRepository? repository,
    required this.storageIdentityService,
    required this.localStorageManager,
    LibraryScannerService? libraryScannerService,
    DeviceStorageService? deviceStorageService,
    this.metadataService,
    this.settingsService,
    this.transferCoordinator,
    this.transferService,
  }) : repository = repository ?? DriftLibraryRepository(database),
       libraryScannerService =
           libraryScannerService ??
           LibraryScannerService(
             database: database,
             storageIdentityService: storageIdentityService,
           ),
       deviceStorageService =
           deviceStorageService ??
           DeviceStorageServiceImpl(
             database: database,
             localStorageManager: localStorageManager,
           );

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _usedBytes = 0;
  int _availableBytes = 0;
  late TransferCoordinator _transferCoordinator;

  late MetadataService _metadataService;
  SettingsService? _settingsService;
  late TextEditingController _apiKeyController;
  bool _isApiKeyObscured = true;
  bool _isTestingConnection = false;
  String? _testStatusMessage;
  bool _isIdentifyingLibrary = false;
  double _identifyProgress = 0.0;
  String? _identifyStatus;

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService;
    _transferCoordinator =
        widget.transferCoordinator ??
        TransferCoordinator(
          transferService:
              widget.transferService ??
              TransferServiceImpl(
                database: widget.database,
                deviceStorageService: widget.deviceStorageService,
                storageIdentityService: widget.storageIdentityService,
              ),
          database: widget.database,
          deviceStorageService: widget.deviceStorageService,
          storageIdentityService: widget.storageIdentityService,
        );
    _metadataService =
        widget.metadataService ??
        MetadataService(
          database: widget.database,
          tmdbClient: TmdbApiClient(apiKey: widget.settingsService?.tmdbApiKey),
          imageCacheService: ImageCacheService(
            localStorageManager: widget.localStorageManager,
          ),
        );
    _apiKeyController = TextEditingController(
      text: _settingsService?.tmdbApiKey ?? '',
    );
    _refreshStorageStats();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  bool get _hasApiKey =>
      _settingsService?.hasTmdbApiKey ?? _metadataService.tmdbClient.hasApiKey;

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (_settingsService != null) {
      await _settingsService!.setTmdbApiKey(key);
    }
    _metadataService.tmdbClient.updateApiKey(key.isNotEmpty ? key : null);
    if (mounted) {
      final theme = CinemaTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'TMDB API configuration saved.',
            style: TextStyle(color: theme.textPrimary),
          ),
          backgroundColor: theme.surface2,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _testTmdbConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testStatusMessage = null;
    });

    try {
      final results = await _metadataService.tmdbClient.searchMovies(
        'Inception',
        year: 2010,
      );
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _testStatusMessage = results.isNotEmpty
              ? 'Success: Connected to TMDB API.'
              : 'Connected, but no results returned.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _testStatusMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _runBatchIdentification() async {
    setState(() {
      _isIdentifyingLibrary = true;
      _identifyProgress = 0.0;
      _identifyStatus = 'Starting metadata identification...';
    });

    try {
      final summary = await _metadataService.identifyAllUnmatched(
        onProgress: (current, total, currentTitle) {
          if (mounted) {
            setState(() {
              _identifyProgress = total > 0 ? current / total : 0.0;
              _identifyStatus = '($current/$total) Identifying: $currentTitle';
            });
          }
        },
      );

      if (mounted) {
        final theme = CinemaTheme.of(context);
        setState(() {
          _isIdentifyingLibrary = false;
          _identifyStatus =
              'Completed: ${summary.automaticallyMatched} matched, '
              '${summary.routedToVerification} need verification, '
              '${summary.errors} errors.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Identification pass complete: ${summary.automaticallyMatched} matched.',
              style: TextStyle(color: theme.textPrimary),
            ),
            backgroundColor: theme.surface2,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isIdentifyingLibrary = false;
          _identifyStatus = 'Failed: $e';
        });
      }
    }
  }

  Future<void> _showPlayerDialog() async {
    final theme = CinemaTheme.of(context);
    final current = _settingsService?.preferredPlayer ?? 'vlc';
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Preferred Media Player',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              if (_settingsService != null) {
                await _settingsService!.setPreferredPlayer('vlc');
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() {});
            },
            child: Row(
              children: [
                Icon(
                  Icons.video_library,
                  color: current == 'vlc' ? theme.accent : theme.textMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  'VLC Media Player',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              if (_settingsService != null) {
                await _settingsService!.setPreferredPlayer('system');
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() {});
            },
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: current == 'system' ? theme.accent : theme.textMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  'System Default Player',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    final theme = CinemaTheme.of(context);
    final pathController = TextEditingController();
    final nameController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: theme.surface,
          title: Text(
            'Add Storage Location',
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pathController,
                decoration: InputDecoration(
                  labelText: 'Root Path or Document URI',
                  hintText: r'e.g. D:\Movies or content://...',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  hintStyle: TextStyle(color: theme.textMuted),
                  filled: true,
                  fillColor: theme.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.border),
                  ),
                ),
                style: TextStyle(color: theme.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name (optional)',
                  hintText: 'e.g. Movies HDD',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  hintStyle: TextStyle(color: theme.textMuted),
                  filled: true,
                  fillColor: theme.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.border),
                  ),
                ),
                style: TextStyle(color: theme.textPrimary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Cancel', style: TextStyle(color: theme.textMuted)),
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

  void _openScanSheet(Storage storage) {
    final theme = CinemaTheme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return _ScannerProgressSheet(
          storage: storage,
          libraryScannerService: widget.libraryScannerService,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        children: [
          // Section: Needs Verification Alert (Sections 14 & 44)
          StreamBuilder<int>(
            stream: widget.repository.watchUnmatchedTotalCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.warningSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: theme.warning, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count items need your attention',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Some movies or TV shows could not be automatically identified with high confidence.',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NeedsVerificationScreen(
                              repository: widget.repository,
                              database: widget.database,
                              metadataService: _metadataService,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accent,
                        foregroundColor: theme.onAccent,
                      ),
                      child: const Text('Review Queue'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Section: Registered Storage Locations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STORAGE LOCATIONS', style: CinemaTheme.eyebrow(context)),
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
                return Text(
                  'Loading storages...',
                  style: TextStyle(color: theme.textMuted),
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
                                ? theme.accent
                                : theme.textMuted,
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
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.surface2,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: theme.border),
                                      ),
                                      child: Text(
                                        isLocal
                                            ? 'DEVICE STORAGE'
                                            : 'EXTERNAL DISK',
                                        style: TextStyle(
                                          color: theme.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
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
                                  style: TextStyle(
                                    color: theme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${storage.filesystemIdentifier}',
                                  style: TextStyle(
                                    color: theme.textMuted,
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
                                          ? theme.statusAvailable
                                          : theme.statusMissing,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    storage.available
                                        ? 'Connected'
                                        : 'Disconnected',
                                    style: TextStyle(
                                      color: storage.available
                                          ? theme.statusAvailable
                                          : theme.statusMissing,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (storage.available &&
                                  !isLocal &&
                                  storage.rootUri.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                FilledButton.tonalIcon(
                                  onPressed: () => _openScanSheet(storage),
                                  icon: const Icon(Icons.sync, size: 14),
                                  label: const Text('Scan Now'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.accentMuted,
                                    foregroundColor: theme.accent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(0, 30),
                                    textStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              if (!isLocal) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
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
                                    style: TextStyle(
                                      color: theme.accent,
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
          Text(
            'THIS DEVICE (OFFLINE STORAGE)',
            style: CinemaTheme.eyebrow(context),
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
                      Text(
                        'Offline Media Storage',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_formatBytes(_usedBytes)} used / ${_formatBytes(_availableBytes)} free',
                        style: TextStyle(
                          color: theme.textSecondary,
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
                    backgroundColor: theme.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Offline copies are stored in an application-managed directory. Deleting a local offline copy frees device space without deleting the original HDD media or removing it from your cinema.',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Section: Offline Transfer Queue & Diagnostics (M5.5 Diagnostics)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'OFFLINE TRANSFER QUEUE & DIAGNOSTICS',
                style: CinemaTheme.eyebrow(context),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final results = await _transferCoordinator
                          .reconcileTransfers();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reconciliation complete (${results.length} jobs evaluated).',
                            ),
                            backgroundColor: theme.surface2,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.build_circle_outlined, size: 14),
                    label: const Text(
                      'Reconcile',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final count = await _transferCoordinator
                          .cleanStalePartials();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              count > 0
                                  ? 'Cleaned $count stale partial transfer file(s).'
                                  : 'No stale partial files found.',
                            ),
                            backgroundColor: theme.surface2,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.cleaning_services_outlined,
                      size: 14,
                    ),
                    label: const Text(
                      'Clean Partials',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          StreamBuilder<List<TransferJob>>(
            stream: widget.database.watchAllTransferJobs(),
            builder: (context, snapshot) {
              final jobs = snapshot.data ?? [];
              if (jobs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'No offline transfer jobs recorded.',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: jobs.take(10).map((job) {
                      final isTerminal =
                          job.status == 'COMPLETED' ||
                          job.status == 'FAILED' ||
                          job.status == 'CANCELLED';
                      final isFailed = job.status == 'FAILED';
                      final isCompleted = job.status == 'COMPLETED';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.check_circle_outline
                                  : isFailed
                                  ? Icons.error_outline
                                  : Icons.sync,
                              color: isCompleted
                                  ? theme.statusAvailable
                                  : isFailed
                                  ? theme.statusMissing
                                  : theme.accent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${job.mediaType.toUpperCase()}: ${job.destinationRelativePath.isNotEmpty ? p.basename(job.destinationRelativePath) : job.mediaId}',
                                        style: TextStyle(
                                          color: theme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (job.error != null &&
                                      job.error!.isNotEmpty) ...[
                                    Text(
                                      TransferCoordinator.formatError(
                                        job.error,
                                      ),
                                      style: TextStyle(
                                        color: theme.statusMissing,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    'Status: ${job.status} · ${_formatBytes(job.bytesTransferred.toInt())} of ${_formatBytes(job.totalBytes.toInt())}',
                                    style: TextStyle(
                                      color: theme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isTerminal) ...[
                              TextButton(
                                onPressed: () => _transferCoordinator
                                    .cancelMediaTransfer(job.mediaId),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.textSecondary,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ] else if (isFailed) ...[
                              OutlinedButton(
                                onPressed: () =>
                                    _transferCoordinator.retryTransferJob(job),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.accent,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                ),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Section: TMDB Metadata Configuration (Sections 13, 15, 40)
          Text(
            'TMDB METADATA CONFIGURATION',
            style: CinemaTheme.eyebrow(context),
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
                      Row(
                        children: [
                          Icon(Icons.public, color: theme.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'The Movie Database (TMDB) API',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _hasApiKey ? theme.surface2 : theme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _hasApiKey
                                ? theme.statusAvailable
                                : theme.statusMissing,
                          ),
                        ),
                        child: Text(
                          _hasApiKey ? 'CONFIGURED' : 'KEY MISSING',
                          style: TextStyle(
                            color: _hasApiKey
                                ? theme.statusAvailable
                                : theme.statusMissing,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A TMDB API Key or Read Access Token is required to fetch official cinema artwork, synopses, runtimes, and season/episode metadata.',
                    style: TextStyle(color: theme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _apiKeyController,
                          obscureText: _isApiKeyObscured,
                          decoration: InputDecoration(
                            labelText: 'API Key or Access Token',
                            hintText: 'Enter TMDB API Key / Token or set TMDB_API_KEY',
                            labelStyle: TextStyle(color: theme.textSecondary),
                            hintStyle: TextStyle(color: theme.textMuted),
                            filled: true,
                            fillColor: theme.surface2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: theme.accent,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isApiKeyObscured
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: theme.textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isApiKeyObscured = !_isApiKeyObscured;
                                });
                              },
                            ),
                          ),
                          style: TextStyle(color: theme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saveApiKey,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _hasApiKey && !_isTestingConnection
                            ? _testTmdbConnection
                            : null,
                        icon: _isTestingConnection
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.accent,
                                ),
                              )
                            : const Icon(Icons.network_check, size: 16),
                        label: const Text('Test Connection'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _hasApiKey && !_isIdentifyingLibrary
                            ? _runBatchIdentification
                            : null,
                        icon: _isIdentifyingLibrary
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.accent,
                                ),
                              )
                            : const Icon(Icons.auto_fix_high, size: 16),
                        label: const Text('Identify Unmatched Media'),
                      ),
                    ],
                  ),
                  if (_testStatusMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _testStatusMessage!,
                      style: TextStyle(
                        color: _testStatusMessage!.contains('Error')
                            ? theme.statusMissing
                            : theme.statusAvailable,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (_isIdentifyingLibrary) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _identifyProgress > 0 ? _identifyProgress : null,
                      color: theme.accent,
                      backgroundColor: theme.surface2,
                    ),
                    if (_identifyStatus != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _identifyStatus!,
                        style: TextStyle(color: theme.textMuted, fontSize: 11),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  Divider(color: theme.border, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Section: Appearance & Theme
          Text('APPEARANCE & THEME', style: CinemaTheme.eyebrow(context)),
          const SizedBox(height: 14),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: theme.accent,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visual Theme',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _settingsService?.themeMode == ThemeMode.light
                                  ? 'Light Mode (The Exhibition / Gallery Linen)'
                                  : _settingsService?.themeMode ==
                                        ThemeMode.system
                                  ? 'System Default'
                                  : 'Dark Mode (The Screening Room)',
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.dark_mode_outlined, size: 16),
                        label: const Text('Dark (Screening Room)'),
                        selected:
                            (_settingsService?.themeMode ?? ThemeMode.dark) ==
                            ThemeMode.dark,
                        selectedColor: theme.accentMuted,
                        backgroundColor: theme.surface2,
                        labelStyle: TextStyle(
                          color:
                              (_settingsService?.themeMode ?? ThemeMode.dark) ==
                                  ThemeMode.dark
                              ? theme.accent
                              : theme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color:
                                (_settingsService?.themeMode ??
                                        ThemeMode.dark) ==
                                    ThemeMode.dark
                                ? theme.accent
                                : theme.border,
                          ),
                        ),
                        onSelected: (selected) async {
                          if (selected && _settingsService != null) {
                            await _settingsService!.setThemeMode(
                              ThemeMode.dark,
                            );
                            setState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.light_mode_outlined, size: 16),
                        label: const Text('Light (Gallery Linen)'),
                        selected:
                            _settingsService?.themeMode == ThemeMode.light,
                        selectedColor: theme.accentMuted,
                        backgroundColor: theme.surface2,
                        labelStyle: TextStyle(
                          color: _settingsService?.themeMode == ThemeMode.light
                              ? theme.accent
                              : theme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color:
                                _settingsService?.themeMode == ThemeMode.light
                                ? theme.accent
                                : theme.border,
                          ),
                        ),
                        onSelected: (selected) async {
                          if (selected && _settingsService != null) {
                            await _settingsService!.setThemeMode(
                              ThemeMode.light,
                            );
                            setState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.settings_brightness, size: 16),
                        label: const Text('System Default'),
                        selected:
                            _settingsService?.themeMode == ThemeMode.system,
                        selectedColor: theme.accentMuted,
                        backgroundColor: theme.surface2,
                        labelStyle: TextStyle(
                          color: _settingsService?.themeMode == ThemeMode.system
                              ? theme.accent
                              : theme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color:
                                _settingsService?.themeMode == ThemeMode.system
                                ? theme.accent
                                : theme.border,
                          ),
                        ),
                        onSelected: (selected) async {
                          if (selected && _settingsService != null) {
                            await _settingsService!.setThemeMode(
                              ThemeMode.system,
                            );
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Section: Playback Player Preference
          Text('PLAYBACK HANDOFF', style: CinemaTheme.eyebrow(context)),
          const SizedBox(height: 14),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: theme.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferred Media Player',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _settingsService?.preferredPlayer == 'system'
                              ? 'System Default Player'
                              : 'VLC Media Player',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _showPlayerDialog,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Section: About & Attribution (Section 40)
          Column(
            children: [
              Text(
                'REELHOUSE v1.0 • Personal Digital Cinema',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: theme.textMuted),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                        style: TextStyle(color: theme.textMuted, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet displaying live scanner progress according to Section 43.
class _ScannerProgressSheet extends StatefulWidget {
  final Storage storage;
  final LibraryScannerService libraryScannerService;

  const _ScannerProgressSheet({
    required this.storage,
    required this.libraryScannerService,
  });

  @override
  State<_ScannerProgressSheet> createState() => _ScannerProgressSheetState();
}

class _ScannerProgressSheetState extends State<_ScannerProgressSheet> {
  ScanProgress? _progress;
  ScanSummary? _summary;
  String? _error;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  void _startScanning() {
    widget.libraryScannerService
        .scanStorage(
          widget.storage,
          onProgress: (prog) {
            if (mounted) {
              setState(() {
                _progress = prog;
                if (prog.error != null) {
                  _error = prog.error;
                }
              });
            }
          },
        )
        .then((summary) {
          if (mounted) {
            setState(() {
              _summary = summary;
              _isComplete = true;
            });
          }
        })
        .catchError((dynamic err) {
          if (mounted) {
            setState(() {
              _error = err.toString();
              _isComplete = true;
            });
          }
        });
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    int value,
    IconData icon,
  ) {
    final theme = CinemaTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: theme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);
    final filesDiscovered = _progress?.filesDiscovered ?? 0;
    final moviesIdentified = _progress?.moviesIdentified ?? 0;
    final tvEpisodesIdentified = _progress?.tvEpisodesIdentified ?? 0;
    final needsVerification = _progress?.needsVerification ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isComplete ? Icons.check_circle_outline : Icons.radar,
                    color: _isComplete ? theme.statusAvailable : theme.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isComplete ? 'Scan Complete' : 'Scanning...',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  widget.storage.name,
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          if (!_isComplete)
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(
                color: theme.accent,
                backgroundColor: theme.surface2,
                minHeight: 4,
              ),
            ),
          const SizedBox(height: 18),

          // Live Metrics (Section 43)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 500 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: constraints.maxWidth > 500 ? 1.4 : 1.8,
                children: [
                  _buildStatCard(
                    context,
                    'Files Discovered',
                    filesDiscovered,
                    Icons.folder_open,
                  ),
                  _buildStatCard(
                    context,
                    'Movies Identified',
                    moviesIdentified,
                    Icons.movie_outlined,
                  ),
                  _buildStatCard(
                    context,
                    'TV Episodes',
                    tvEpisodesIdentified,
                    Icons.tv_outlined,
                  ),
                  _buildStatCard(
                    context,
                    'Needs Verification',
                    needsVerification,
                    Icons.help_outline,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Current file ticker / Summary banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(color: theme.statusMissing, fontSize: 12),
                  ),
                ] else if (_isComplete && _summary != null) ...[
                  Text(
                    'Discovered ${_summary!.filesDiscovered} files in '
                    '${(_summary!.duration.inMilliseconds / 1000).toStringAsFixed(1)}s: '
                    '${_summary!.newSourcesAdded} new sources added, '
                    '${_summary!.sourcesRestored} restored, '
                    '${_summary!.sourcesMarkedMissing} marked missing.',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ] else ...[
                  Text('CURRENT FILE', style: CinemaTheme.eyebrow(context)),
                  const SizedBox(height: 4),
                  Text(
                    _progress?.currentFile ?? 'Inspecting filesystem...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!_isComplete)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Run in Background'),
                )
              else
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
