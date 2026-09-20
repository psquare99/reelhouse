import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
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
import '../../data/services/feedback_service_impl.dart';
import '../../data/services/file_picker_service_impl.dart';
import '../../data/services/library_backup_service_impl.dart';
import '../../domain/services/feedback_service.dart';
import '../../domain/services/file_picker_service.dart';
import '../../domain/services/library_backup_service.dart';
import '../../domain/services/transfer_coordinator.dart';
import '../../domain/services/transfer_service.dart';
import '../profile/profile_screen.dart';
import '../widgets/cinema_profile_avatar.dart';
import '../widgets/feedback_dialog.dart';
import '../widgets/library_backup_dialogs.dart';
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
  final LibraryBackupService? libraryBackupService;
  final FilePickerService? filePickerService;
  final FeedbackService? feedbackService;
  final VoidCallback? onNavigateToProfile;

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
    this.libraryBackupService,
    this.filePickerService,
    this.feedbackService,
    this.onNavigateToProfile,
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
  late LibraryBackupService _libraryBackupService;
  late final FilePickerService _filePickerService;
  late final FeedbackService _feedbackService;
  late TextEditingController _apiKeyController;
  bool _isApiKeyObscured = true;
  bool _isTestingConnection = false;
  String? _testStatusMessage;
  TmdbAuthStatus? _lastAuthStatus;
  bool _isChangingApiKey = false;
  bool _isValidatingCandidateKey = false;
  String? _candidateValidationMessage;
  bool _candidateValidationSuccess = false;
  bool _isIdentifyingLibrary = false;
  double _identifyProgress = 0.0;
  String? _identifyStatus;

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService;
    _filePickerService = widget.filePickerService ?? FilePickerServiceImpl();
    _feedbackService = widget.feedbackService ?? FeedbackServiceImpl();
    _libraryBackupService =
        widget.libraryBackupService ??
        LibraryBackupServiceImpl(
          database: widget.database,
          settingsService: widget.settingsService,
        );
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

  Future<void> _testAndSaveCandidateKey() async {
    final candidateKey = _apiKeyController.text.trim();
    if (candidateKey.isEmpty) {
      setState(() {
        _candidateValidationMessage =
            'Please enter an API key or access token.';
        _candidateValidationSuccess = false;
      });
      return;
    }

    setState(() {
      _isValidatingCandidateKey = true;
      _candidateValidationMessage = null;
    });

    final result = await _metadataService.tmdbClient.validateAuthentication(
      candidateKey,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      if (_settingsService != null) {
        await _settingsService!.setTmdbApiKey(candidateKey);
      }
      _metadataService.tmdbClient.updateApiKey(candidateKey);
      if (!mounted) return;
      setState(() {
        _isValidatingCandidateKey = false;
        _candidateValidationSuccess = true;
        _candidateValidationMessage = 'Connected to TMDB successfully.';
        _lastAuthStatus = TmdbAuthStatus.connected;
        _isChangingApiKey = false;
      });

      final theme = CinemaTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'TMDB API key verified and saved.',
            style: TextStyle(color: theme.textPrimary),
          ),
          backgroundColor: theme.surface2,
        ),
      );
    } else {
      setState(() {
        _isValidatingCandidateKey = false;
        _candidateValidationSuccess = false;
        _candidateValidationMessage = result.status == TmdbAuthStatus.invalidKey
            ? 'Invalid TMDB API key. Please check your key at themoviedb.org and try again.'
            : 'Unable to connect to TMDB. Please check your internet connection.';
        _lastAuthStatus = result.status;
      });
    }
  }

  Future<void> _testTmdbConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testStatusMessage = null;
    });

    final result = await _metadataService.tmdbClient.validateAuthentication();
    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _lastAuthStatus = result.status;
        _testStatusMessage = result.message;
      });
    }
  }

  Future<void> _disconnectTmdb() async {
    if (_settingsService != null) {
      await _settingsService!.setTmdbApiKey('');
    }
    _metadataService.tmdbClient.updateApiKey(null);
    _apiKeyController.clear();
    setState(() {
      _lastAuthStatus = TmdbAuthStatus.notConfigured;
      _isChangingApiKey = false;
      _testStatusMessage = null;
      _candidateValidationMessage = null;
    });
    if (mounted) {
      final theme = CinemaTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'TMDB disconnected.',
            style: TextStyle(color: theme.textPrimary),
          ),
          backgroundColor: theme.surface2,
        ),
      );
    }
  }

  void _openTmdbWebsite() {
    const url = 'https://www.themoviedb.org/settings/api';
    try {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        Process.run('open', [url]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
      }
    } catch (_) {}

    _showTmdbSetupGuideDialog();
  }

  void _showTmdbSetupGuideDialog() {
    final theme = CinemaTheme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Row(
          children: [
            Icon(Icons.vpn_key_outlined, color: theme.accent, size: 22),
            const SizedBox(width: 10),
            Text(
              'How to Get a TMDB API Key',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Follow these steps on themoviedb.org to create your free API key:',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildGuideStep(
              '1',
              'Sign in or create a free TMDB account.',
              theme,
            ),
            const SizedBox(height: 10),
            _buildGuideStep(
              '2',
              'Open Settings > API in your profile menu.',
              theme,
            ),
            const SizedBox(height: 10),
            _buildGuideStep(
              '3',
              'Select "Create" and choose the "Developer" option.',
              theme,
            ),
            const SizedBox(height: 10),
            _buildGuideStep(
              '4',
              'Copy your API Key (v3 auth) or API Read Access Token and paste it into REELHOUSE.',
              theme,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: theme.onAccent,
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => FeedbackDialog(feedbackService: _feedbackService),
    );
  }

  Widget _buildGuideStep(String number, String text, CinemaThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.surface2,
            shape: BoxShape.circle,
            border: Border.all(color: theme.border),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: theme.accent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthBadge(CinemaThemeData theme) {
    String label;
    Color color;

    if (_lastAuthStatus == TmdbAuthStatus.invalidKey) {
      label = 'INVALID KEY';
      color = theme.statusMissing;
    } else if (_lastAuthStatus == TmdbAuthStatus.networkFailure) {
      label = 'NETWORK ERROR';
      color = theme.warning;
    } else if (_hasApiKey) {
      label = 'CONNECTED';
      color = theme.statusAvailable;
    } else {
      label = 'NOT CONFIGURED';
      color = theme.statusMissing;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTmdbCard(CinemaThemeData theme) {
    final isConfiguredAndNotEditing = _hasApiKey && !_isChangingApiKey;

    return Card(
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
                _buildAuthBadge(theme),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'REELHOUSE uses The Movie Database (TMDB) to identify your movies and TV shows and load official posters, backdrops, and details.',
              style: TextStyle(color: theme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (isConfiguredAndNotEditing) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, color: theme.accent, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '••••••••••••••••••••••••••••••••',
                        style: TextStyle(
                          color: theme.textSecondary,
                          letterSpacing: 2,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isChangingApiKey = true;
                          _apiKeyController.clear();
                          _candidateValidationMessage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Change API Key'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isTestingConnection
                        ? null
                        : _testTmdbConnection,
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
                    onPressed: !_isIdentifyingLibrary
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
                  TextButton(
                    onPressed: _disconnectTmdb,
                    child: Text(
                      'Disconnect',
                      style: TextStyle(color: theme.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (_testStatusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _testStatusMessage!,
                  style: TextStyle(
                    color:
                        _testStatusMessage!.toLowerCase().contains('invalid') ||
                            _testStatusMessage!.toLowerCase().contains(
                              'error',
                            ) ||
                            _testStatusMessage!.toLowerCase().contains('unable')
                        ? theme.statusMissing
                        : theme.statusAvailable,
                    fontSize: 12,
                  ),
                ),
              ],
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _apiKeyController,
                      obscureText: _isApiKeyObscured,
                      decoration: InputDecoration(
                        labelText: 'API Key or Access Token',
                        hintText: 'Enter TMDB API Key / Token',
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
                          borderSide: BorderSide(color: theme.accent, width: 2),
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
                  ElevatedButton.icon(
                    onPressed: _isValidatingCandidateKey
                        ? null
                        : _testAndSaveCandidateKey,
                    icon: _isValidatingCandidateKey
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.onAccent,
                            ),
                          )
                        : const Icon(Icons.check, size: 16),
                    label: Text(
                      _isValidatingCandidateKey ? 'Testing...' : 'Test & Save',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      backgroundColor: theme.accent,
                      foregroundColor: theme.onAccent,
                    ),
                  ),
                ],
              ),
              if (_candidateValidationMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _candidateValidationMessage!,
                  style: TextStyle(
                    color: _candidateValidationSuccess
                        ? theme.statusAvailable
                        : theme.statusMissing,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _openTmdbWebsite,
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Get a TMDB API Key'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.accent,
                      side: BorderSide(color: theme.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                  if (_isChangingApiKey) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isChangingApiKey = false;
                          _candidateValidationMessage = null;
                          _apiKeyController.text =
                              _settingsService?.tmdbApiKey ?? '';
                        });
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                    ),
                  ],
                ],
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
    );
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

  Future<void> _showExportLibraryDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => ExportBackupDialog(
        libraryBackupService: _libraryBackupService,
        filePickerService: _filePickerService,
      ),
    );
  }

  Future<void> _showImportLibraryDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => ImportBackupDialog(
        libraryBackupService: _libraryBackupService,
        filePickerService: _filePickerService,
        onImportSuccess: () {
          if (mounted) setState(() {});
        },
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
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AddStorageDialog(
        database: widget.database,
        storageIdentityService: widget.storageIdentityService,
        filePickerService: _filePickerService,
        onStorageAdded: () {
          if (mounted) setState(() {});
        },
      ),
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

  Future<void> _confirmRemoveStorage(Storage storage) async {
    final theme = CinemaTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Remove Storage Location',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove "${storage.name}" (${storage.rootUri}) from REELHOUSE?',
              style: TextStyle(color: theme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: theme.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Important Details:',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Media items that only exist on this storage location will be removed from your cinema collection.\n'
                    '• Media items with offline copies on this device or other drives will remain in your library.\n'
                    '• Physical video files on your disk will NOT be deleted or modified.',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.statusMissing,
              foregroundColor: theme.textPrimary,
            ),
            child: const Text('Remove Location'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.repository.removeStorage(storage.id);
        await _refreshStorageStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Storage location "${storage.name}" removed.',
                style: TextStyle(color: theme.textPrimary),
              ),
              backgroundColor: theme.surface2,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error removing storage location: $e',
                style: TextStyle(color: theme.statusMissing),
              ),
              backgroundColor: theme.surface2,
            ),
          );
        }
      }
    }
  }

  Widget _buildProfileSummaryCard(CinemaThemeData theme) {
    final displayName =
        widget.settingsService?.userDisplayName.isNotEmpty == true
        ? widget.settingsService!.userDisplayName
        : 'Viewer';
    final picturePath = widget.settingsService?.userProfilePicturePath;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          CinemaProfileAvatar(
            size: 44,
            displayName: displayName,
            profilePicturePath: picturePath,
            fontSize: 16,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Local Cinema Profile',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              if (widget.onNavigateToProfile != null) {
                widget.onNavigateToProfile!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      settingsService: widget.settingsService,
                      filePickerService: widget.filePickerService,
                    ),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.accent,
              side: BorderSide(color: theme.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  // ── RC.5 About helpers ──────────────────────────────────────────────────

  static Widget _buildInfoRow(
    CinemaThemeData theme,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.textMuted, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static Widget _buildPackageChip(CinemaThemeData theme, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: theme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static String _getPlatformLabel() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        children: [
          // Section: Personal Profile Summary
          if (widget.settingsService != null) ...[
            _buildProfileSummaryCard(theme),
            const SizedBox(height: 20),
          ],

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
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _confirmRemoveStorage(storage),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 13,
                                    color: theme.statusMissing,
                                  ),
                                  label: Text(
                                    'Remove',
                                    style: TextStyle(
                                      color: theme.statusMissing,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: theme.statusMissing.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    minimumSize: const Size(0, 26),
                                    visualDensity: VisualDensity.compact,
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
          _buildTmdbCard(theme),
          const SizedBox(height: 32),

          // Section: Library Backup & Restore (RC.1)
          Text('LIBRARY BACKUP & RESTORE', style: CinemaTheme.eyebrow(context)),
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
                        Icons.backup_outlined,
                        color: theme.accent,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backup & Portability',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Export your catalogue, custom collections, and watch history to a versioned JSON backup, or restore a previous backup into this installation.',
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
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showExportLibraryDialog,
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('Export Library'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.surface2,
                          foregroundColor: theme.textPrimary,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showImportLibraryDialog,
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 16,
                        ),
                        label: const Text('Import Library'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textPrimary,
                          side: BorderSide(color: theme.border),
                        ),
                      ),
                    ],
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

          // Section: Feedback & Suggestions (RC.4)
          Text('FEEDBACK & SUGGESTIONS', style: CinemaTheme.eyebrow(context)),
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
                        Icons.feedback_outlined,
                        color: theme.accent,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Feedback & Suggestions',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Help improve REELHOUSE by reporting bugs, suggesting improvements, or sharing feedback.',
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
                  ElevatedButton.icon(
                    onPressed: _showFeedbackDialog,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Send Feedback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: theme.onAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Section: About & Credits (RC.5)
          Text('ABOUT', style: CinemaTheme.eyebrow(context)),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App identity
                  Row(
                    children: [
                      Icon(Icons.movie_filter, color: theme.accent, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REELHOUSE',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Personal Digital Cinema',
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Version info
                  _buildInfoRow(theme, 'Version', '1.0.0+1'),
                  const SizedBox(height: 8),
                  _buildInfoRow(theme, 'Platform', _getPlatformLabel()),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'A personal cinema application for organising and '
                    'discovering your movie and TV collection with rich '
                    'metadata from The Movie Database.',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Credits
                  Text(
                    'CREDITS',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(theme, 'Built with', 'Flutter & Dart'),
                  const SizedBox(height: 6),
                  _buildInfoRow(theme, 'Metadata', 'The Movie Database (TMDB)'),
                  const SizedBox(height: 16),

                  // Open-source acknowledgements
                  Text(
                    'ACKNOWLEDGEMENTS',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'REELHOUSE is built with these open-source packages:',
                    style: TextStyle(color: theme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildPackageChip(theme, 'drift'),
                      _buildPackageChip(theme, 'path_provider'),
                      _buildPackageChip(theme, 'uuid'),
                      _buildPackageChip(theme, 'http'),
                      _buildPackageChip(theme, 'file_picker'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // TMDB attribution
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: theme.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This product uses the TMDB API but is not '
                            'endorsed or certified by TMDB.',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // RC.5B — Legal links
                  const SizedBox(height: 16),
                  Text(
                    'LEGAL',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildLegalLink(
                    theme,
                    Icons.shield_outlined,
                    'Privacy Policy',
                    'https://feedback.thelongwayhome.dev/privacy',
                  ),
                  const SizedBox(height: 8),
                  _buildLegalLink(
                    theme,
                    Icons.article_outlined,
                    'Media, Copyright & User Responsibility',
                    'https://feedback.thelongwayhome.dev/media-responsibility',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a tappable legal link row.
  static Widget _buildLegalLink(
    CinemaThemeData theme,
    IconData icon,
    String label,
    String url,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: theme.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: theme.textPrimary, fontSize: 13),
                ),
              ),
              Icon(Icons.open_in_new, size: 14, color: theme.textMuted),
            ],
          ),
        ),
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

class AddStorageDialog extends StatefulWidget {
  final AppDatabase database;
  final StorageIdentityService storageIdentityService;
  final FilePickerService? filePickerService;
  final VoidCallback? onStorageAdded;

  const AddStorageDialog({
    super.key,
    required this.database,
    required this.storageIdentityService,
    this.filePickerService,
    this.onStorageAdded,
  });

  @override
  State<AddStorageDialog> createState() => _AddStorageDialogState();
}

class _AddStorageDialogState extends State<AddStorageDialog> {
  late final FilePickerService _filePickerService;
  late final TextEditingController _nameController;
  String? _selectedPath;
  bool _isPicking = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filePickerService = widget.filePickerService ?? FilePickerServiceImpl();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });

    try {
      final path = await _filePickerService.pickDirectory(
        dialogTitle: 'Select Media Library Folder',
      );
      if (!mounted) return;

      if (path != null && path.trim().isNotEmpty) {
        final cleanPath = path.trim();
        final isConn = await widget.storageIdentityService.isStorageConnected(
          cleanPath,
        );
        if (!isConn) {
          setState(() {
            _isPicking = false;
            _error = 'Selected directory is inaccessible or does not exist.';
          });
          return;
        }

        final autoName = await widget.storageIdentityService
            .getStorageDisplayName(cleanPath);
        setState(() {
          _selectedPath = cleanPath;
          if (_nameController.text.trim().isEmpty) {
            _nameController.text = autoName;
          }
          _isPicking = false;
          _error = null;
        });
      } else {
        setState(() {
          _isPicking = false;
          // User cancellation is not an error
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPicking = false;
          _error = 'Folder selection failed: $e';
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedPath == null || _selectedPath!.isEmpty) {
      setState(() {
        _error = 'Please choose a folder first.';
      });
      return;
    }

    final path = _selectedPath!;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final fsId = await widget.storageIdentityService.getFilesystemIdentifier(
        path,
      );
      final autoName = await widget.storageIdentityService
          .getStorageDisplayName(path);
      final chosenName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : autoName;
      final isConn = await widget.storageIdentityService.isStorageConnected(
        path,
      );

      final allStorages = await widget.database.getAllStorages();
      final existing = allStorages.cast<Storage?>().firstWhere(
        (s) =>
            s != null && (s.filesystemIdentifier == fsId || s.rootUri == path),
        orElse: () => null,
      );

      final storageId = existing?.id ?? const Uuid().v4();

      final newStorage = StoragesCompanion.insert(
        id: storageId,
        name: chosenName,
        storageType: 'REMOVABLE_VOLUME',
        filesystemIdentifier: fsId,
        rootUri: path,
        lastSeenAt: DateTime.now(),
        available: drift.Value(isConn),
      );

      await widget.database.upsertStorage(newStorage);
      if (!mounted) return;
      widget.onStorageAdded?.call();
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = 'Failed to add storage: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);

    return AlertDialog(
      backgroundColor: theme.surface,
      title: Text(
        'Add Storage Location',
        style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose the folder containing your media library.',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (_selectedPath == null) ...[
              OutlinedButton.icon(
                onPressed: _isPicking || _isSubmitting ? null : _pickFolder,
                icon: _isPicking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open, size: 18),
                label: Text(_isPicking ? 'Selecting...' : 'Choose Folder'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.accent,
                  side: BorderSide(color: theme.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder, color: theme.accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Media Folder',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedPath!,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Change Folder',
                      onPressed: _isPicking || _isSubmitting
                          ? null
                          : _pickFolder,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.accent),
                ),
              ),
              style: TextStyle(color: theme.textPrimary, fontSize: 14),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: theme.stateUnavailable, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: theme.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: (_isSubmitting || _selectedPath == null) ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add, size: 16),
          label: Text(_isSubmitting ? 'Adding...' : 'Add Storage'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.accent,
            foregroundColor: theme.onAccent,
          ),
        ),
      ],
    );
  }
}
