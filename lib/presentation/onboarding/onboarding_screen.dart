import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../data/network/tmdb_api_client.dart';
import '../../data/repository/drift_library_repository.dart';
import '../../data/services/file_picker_service_impl.dart';
import '../../data/services/library_backup_service_impl.dart';
import '../../domain/metadata/image_cache_service.dart';
import '../../domain/metadata/metadata_service.dart';
import '../../domain/repository/library_repository.dart';
import '../../domain/scanner/library_scanner_service.dart';
import '../../domain/services/device_storage_service.dart';
import '../../domain/services/file_picker_service.dart';
import '../../domain/services/library_backup_service.dart';
import '../../domain/services/local_storage_manager.dart';
import '../../domain/services/settings_service.dart';
import '../../domain/services/storage_identity_service.dart';
import '../../domain/services/storage_monitor_service.dart';
import '../../domain/services/transfer_coordinator.dart';
import '../../domain/services/transfer_service.dart';
import '../widgets/library_backup_dialogs.dart';

/// One-time First-Run Onboarding Flow for newly installed MATINEE.
///
/// Implements REELHOUSE_V1_RELEASE_COMPLETENESS_SPECIFICATION_v1.0 Milestone RC.2:
/// 1. Welcome Screen
/// 2. Local Profile (Display Name & optional Profile Photo)
/// 3. TMDB Metadata Setup (with Skip option)
/// 4. Library Setup (Start New Library vs Import Existing Backup)
class OnboardingScreen extends StatefulWidget {
  final AppDatabase database;
  final LibraryRepository repository;
  final StorageIdentityService storageIdentityService;
  final LocalStorageManager localStorageManager;
  final DeviceStorageService? deviceStorageService;
  final LibraryScannerService? libraryScannerService;
  final StorageMonitorService? storageMonitorService;
  final MetadataService? metadataService;
  final SettingsService settingsService;
  final TransferService? transferService;
  final TransferCoordinator? transferCoordinator;
  final LibraryBackupService? libraryBackupService;
  final FilePickerService? filePickerService;
  final VoidCallback? onComplete;

  OnboardingScreen({
    super.key,
    required this.database,
    LibraryRepository? repository,
    required this.storageIdentityService,
    required this.localStorageManager,
    this.deviceStorageService,
    this.libraryScannerService,
    this.storageMonitorService,
    this.metadataService,
    required this.settingsService,
    this.transferService,
    this.transferCoordinator,
    this.libraryBackupService,
    this.filePickerService,
    this.onComplete,
  }) : repository = repository ?? DriftLibraryRepository(database);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0; // 0: Welcome, 1: Profile, 2: TMDB, 3: Library
  late final TextEditingController _displayNameController;
  late final TextEditingController _apiKeyController;
  late final FilePickerService _filePickerService;
  late final LibraryBackupService _libraryBackupService;
  late MetadataService _metadataService;

  String? _profilePicturePath;
  String? _profileError;
  bool _isObscureKey = true;
  bool _isTestingTmdb = false;
  String? _tmdbTestMessage;
  bool _tmdbTestSuccess = false;
  bool _isTmdbSkipped = false;
  bool _showApiKeyInput = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.settingsService.userDisplayName,
    );
    _profilePicturePath = widget.settingsService.userProfilePicturePath;
    _apiKeyController = TextEditingController(
      text: widget.settingsService.tmdbApiKey ?? '',
    );
    _filePickerService = widget.filePickerService ?? FilePickerServiceImpl();
    _libraryBackupService =
        widget.libraryBackupService ??
        LibraryBackupServiceImpl(
          database: widget.database,
          settingsService: widget.settingsService,
        );
    _metadataService =
        widget.metadataService ??
        MetadataService(
          database: widget.database,
          tmdbClient: TmdbApiClient(apiKey: widget.settingsService.tmdbApiKey),
          imageCacheService: ImageCacheService(
            localStorageManager: widget.localStorageManager,
          ),
        );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  bool get _hasTmdbKey =>
      widget.settingsService.hasTmdbApiKey ||
      _apiKeyController.text.trim().isNotEmpty;

  Future<void> _pickProfilePicture() async {
    try {
      final path = await _filePickerService.pickImageFile(
        dialogTitle: 'Select Profile Photo',
      );
      if (path != null && path.trim().isNotEmpty && mounted) {
        setState(() {
          _profilePicturePath = path.trim();
        });
      }
    } catch (_) {}
  }

  void _removeProfilePicture() {
    setState(() {
      _profilePicturePath = null;
    });
  }

  Future<void> _testTmdbConnection() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _tmdbTestMessage = 'Please enter an API key or access token first.';
        _tmdbTestSuccess = false;
      });
      return;
    }

    setState(() {
      _isTestingTmdb = true;
      _tmdbTestMessage = null;
    });

    final result = await _metadataService.tmdbClient.validateAuthentication(
      key,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      await widget.settingsService.setTmdbApiKey(key);
      _metadataService.tmdbClient.updateApiKey(key);
      setState(() {
        _isTestingTmdb = false;
        _tmdbTestSuccess = true;
        _tmdbTestMessage = 'TMDB connection successful.';
      });
    } else {
      setState(() {
        _isTestingTmdb = false;
        _tmdbTestSuccess = false;
        _tmdbTestMessage = result.status == TmdbAuthStatus.invalidKey
            ? 'Invalid TMDB API Key. Please verify your key at themoviedb.org'
            : 'Unable to connect to TMDB. Check your internet connection.';
      });
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
              'Copy your API Key (v3 auth) or API Read Access Token and paste it into MATINEE.',
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

  void _validateAndAdvanceFromProfile() {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _profileError = 'Display Name is required.';
      });
      return;
    }

    widget.settingsService.setUserDisplayName(name);
    widget.settingsService.setUserProfilePicturePath(_profilePicturePath);

    setState(() {
      _profileError = null;
      _currentStep = 2; // Move to TMDB
    });
  }

  void _completeOnboarding() {
    final name = _displayNameController.text.trim();
    if (name.isNotEmpty) {
      widget.settingsService.setUserDisplayName(name);
    }
    widget.settingsService.setUserProfilePicturePath(_profilePicturePath);
    widget.settingsService.setOnboardingCompleted(true);

    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  Future<void> _showImportDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => ImportBackupDialog(
        libraryBackupService: _libraryBackupService,
        filePickerService: _filePickerService,
        onImportSuccess: () {
          _completeOnboarding();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
              )
            : null,
        title: Text(
          'MATINEE SETUP',
          style: TextStyle(
            color: theme.textMuted,
            fontSize: 12,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: _buildCurrentStep(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(CinemaThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(theme);
      case 1:
        return _buildProfileStep(theme);
      case 2:
        return _buildTmdbStep(theme);
      case 3:
      default:
        return _buildLibraryStep(theme);
    }
  }

  // --- STEP 1: WELCOME ---
  Widget _buildWelcomeStep(CinemaThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: theme.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.movie_filter_rounded,
              color: theme.accent,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Welcome to MATINEE',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Your personal digital cinema.',
          style: TextStyle(
            color: theme.accent,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Organize, browse, and experience your movie and TV collections with a private, local-first cinema experience designed for your storage devices.',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: theme.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: LOCAL PROFILE ---
  Widget _buildProfileStep(CinemaThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Profile',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How should MATINEE greet you?',
          style: TextStyle(color: theme.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Preview
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipOval(
                      child: Container(
                        width: 92,
                        height: 92,
                        color: theme.surface2,
                        child: _profilePicturePath != null
                            ? Image.file(
                                File(_profilePicturePath!),
                                width: 92,
                                height: 92,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Icon(
                                        Icons.person_outline,
                                        size: 44,
                                        color: theme.textMuted,
                                      ),
                                    ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.person_outline,
                                  size: 44,
                                  color: theme.textMuted,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickProfilePicture,
                    icon: const Icon(Icons.photo_camera, size: 16),
                    label: Text(
                      _profilePicturePath == null
                          ? 'Add Photo'
                          : 'Change Photo',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.accent,
                      side: BorderSide(color: theme.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                  if (_profilePicturePath != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _removeProfilePicture,
                      child: Text(
                        'Remove',
                        style: TextStyle(
                          color: theme.statusMissing,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _displayNameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Display Name *',
                  hintText: 'e.g. Alex, Cinema Room, Movie Buff',
                  errorText: _profileError,
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
                    borderSide: BorderSide(color: theme.accent, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _validateAndAdvanceFromProfile(),
              ),
              const SizedBox(height: 12),
              Text(
                'Profiles in MATINEE are strictly local. No cloud account, email, or password required.',
                style: TextStyle(color: theme.textMuted, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _validateAndAdvanceFromProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: theme.onAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 3: TMDB SETUP ---
  Widget _buildTmdbStep(CinemaThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect MATINEE to TMDB',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MATINEE uses The Movie Database (TMDB) to identify your movies and TV shows and load official metadata, cast, and artwork.',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        if (!_isTmdbSkipped) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
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
                          'TMDB API Status',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
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
                        color: _hasTmdbKey ? theme.surface2 : theme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _hasTmdbKey
                              ? theme.statusAvailable
                              : theme.statusMissing,
                        ),
                      ),
                      child: Text(
                        _hasTmdbKey ? 'CONFIGURED' : 'NOT CONFIGURED',
                        style: TextStyle(
                          color: _hasTmdbKey
                              ? theme.statusAvailable
                              : theme.statusMissing,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_showApiKeyInput || _hasTmdbKey) ...[
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _isObscureKey,
                    decoration: InputDecoration(
                      labelText: 'API Key or Access Token',
                      hintText: 'Enter your TMDB API Key',
                      labelStyle: TextStyle(color: theme.textSecondary),
                      hintStyle: TextStyle(color: theme.textMuted),
                      filled: true,
                      fillColor: theme.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscureKey = !_isObscureKey;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isTestingTmdb ? null : _testTmdbConnection,
                        icon: _isTestingTmdb
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check, size: 16),
                        label: Text(
                          _isTestingTmdb ? 'Testing...' : 'Test & Save',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accent,
                          foregroundColor: theme.onAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _openTmdbWebsite,
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Get a Key'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.accent,
                          side: BorderSide(color: theme.border),
                        ),
                      ),
                    ],
                  ),
                  if (_tmdbTestMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _tmdbTestMessage!,
                      style: TextStyle(
                        color: _tmdbTestSuccess
                            ? theme.statusAvailable
                            : theme.statusMissing,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ] else ...[
                  Text(
                    'An official free API key from TMDB allows MATINEE to automatically identify movies and series as soon as you connect your hard drives.',
                    style: TextStyle(
                      color: theme.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showApiKeyInput = true;
                          });
                        },
                        icon: const Icon(Icons.key, size: 16),
                        label: const Text('I Have an API Key'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accent,
                          foregroundColor: theme.onAccent,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openTmdbWebsite,
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Get a TMDB API Key'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.accent,
                          side: BorderSide(color: theme.border),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentStep = 3; // Advance to Library Setup
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: theme.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _hasTmdbKey ? 'Continue' : 'Skip for Now',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (!_hasTmdbKey) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isTmdbSkipped = true;
                    });
                  },
                  child: Text(
                    'Learn Consequences',
                    style: TextStyle(color: theme.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ] else ...[
          // Explanation when explicitly exploring skipped state
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.warning, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "TMDB isn't configured yet",
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'You can continue using MATINEE, but identifying your library and loading metadata will require a TMDB API key.\n\nYou can add it at any time from Settings → TMDB.',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep = 3;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accent,
                        foregroundColor: theme.onAccent,
                      ),
                      child: const Text('Continue to Library Setup'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isTmdbSkipped = false;
                        });
                      },
                      child: Text(
                        'Enter Key',
                        style: TextStyle(color: theme.accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- STEP 4: LIBRARY SETUP ---
  Widget _buildLibraryStep(CinemaThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Library',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'How would you like to get started with MATINEE?',
          style: TextStyle(color: theme.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 24),

        // Option 1: Start New Library
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.movie_creation_outlined,
                        color: theme.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start a New Library',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create a fresh library from scratch',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Start with a clean cinema catalogue. You can register your external hard drives, USB disks, and media folders anytime from Settings.',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: theme.onAccent,
                    ),
                    child: const Text('Start a New Library'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Option 2: Import Existing Library
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.settings_backup_restore,
                        color: theme.textPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Existing Library',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Restore a previous MATINEE backup file',
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Restore an existing MATINEE JSON export file. Reconciles your movies, TV shows, custom collections, and watch progress.',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showImportDialog,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Import Backup File'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textPrimary,
                      side: BorderSide(color: theme.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
