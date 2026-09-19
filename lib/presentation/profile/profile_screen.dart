import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/services/file_picker_service_impl.dart';
import '../../domain/services/file_picker_service.dart';
import '../../domain/services/settings_service.dart';
import '../widgets/cinema_profile_avatar.dart';

/// Dedicated Local Profile Screen.
///
/// Implements RC.2 Profile Surface Polish:
/// - Displays personal identity (Display Name & Profile Picture).
/// - Allows changing Display Name (with validation).
/// - Allows changing and removing Profile Picture with immediate fallback to initial avatar.
/// - Fully reactive against [SettingsService].
class ProfileScreen extends StatefulWidget {
  final SettingsService? settingsService;
  final FilePickerService? filePickerService;

  const ProfileScreen({
    super.key,
    this.settingsService,
    this.filePickerService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final FilePickerService _filePickerService;
  // Stable fallback notifier — only used when settingsService is null.
  // MUST NOT be created inside build() as that causes an infinite rebuild loop
  // (ListenableBuilder subscribes to a new instance every frame).
  final ChangeNotifier _fallbackNotifier = ChangeNotifier();
  String? _errorMessage;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.settingsService?.userDisplayName ?? 'Viewer',
    );
    _filePickerService = widget.filePickerService ?? FilePickerServiceImpl();

    widget.settingsService?.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settingsService?.removeListener(_onSettingsChanged);
    _nameController.dispose();
    _fallbackNotifier.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    final currentName = widget.settingsService?.userDisplayName ?? '';
    if (!_isEditingName &&
        currentName.isNotEmpty &&
        _nameController.text != currentName) {
      _nameController.text = currentName;
    }
  }

  Future<void> _saveDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _errorMessage = 'Display Name cannot be empty.';
      });
      return;
    }

    if (widget.settingsService != null) {
      await widget.settingsService!.setUserDisplayName(newName);
    }

    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isEditingName = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name updated.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      final pickedPath = await _filePickerService.pickImageFile(
        dialogTitle: 'Select Profile Picture',
      );
      if (pickedPath != null && pickedPath.trim().isNotEmpty) {
        if (widget.settingsService != null) {
          await widget.settingsService!.setUserProfilePicturePath(
            pickedPath.trim(),
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _removeProfilePicture() async {
    if (widget.settingsService != null) {
      await widget.settingsService!.setUserProfilePicturePath(null);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture removed.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);
    final notifier = widget.settingsService ?? _fallbackNotifier;

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final displayName =
            widget.settingsService?.userDisplayName.isNotEmpty == true
            ? widget.settingsService!.userDisplayName
            : (_nameController.text.isNotEmpty
                  ? _nameController.text
                  : 'Viewer');
        final picturePath = widget.settingsService?.userProfilePicturePath;

        return Scaffold(
          backgroundColor: theme.background,
          body: CustomScrollView(
            slivers: [
              // Header App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Row(
                    children: [
                      Text(
                        'PROFILE',
                        style: TextStyle(
                          color: theme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Area
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Identity Hero Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 32,
                            ),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.border),
                            ),
                            child: Column(
                              children: [
                                CinemaProfileAvatar(
                                  size: 96,
                                  displayName: displayName,
                                  profilePicturePath: picturePath,
                                  fontSize: 34,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Personal Profile',
                                  style: TextStyle(
                                    color: theme.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 2. Profile Details & Editing Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROFILE DETAILS',
                                  style: TextStyle(
                                    color: theme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Display Name field
                                Text(
                                  'Display Name',
                                  style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _nameController,
                                        onChanged: (_) {
                                          if (!_isEditingName) {
                                            setState(() {
                                              _isEditingName = true;
                                            });
                                          }
                                        },
                                        onSubmitted: (_) => _saveDisplayName(),
                                        decoration: InputDecoration(
                                          hintText: 'Enter your display name',
                                          errorText: _errorMessage,
                                          filled: true,
                                          fillColor: theme.surface2,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: theme.border,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: theme.accent,
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: _saveDisplayName,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.accent,
                                        foregroundColor: theme.onAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),
                                Divider(color: theme.border, height: 1),
                                const SizedBox(height: 24),

                                // Profile Picture Section
                                Text(
                                  'Profile Picture',
                                  style: TextStyle(
                                    color: theme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    CinemaProfileAvatar(
                                      size: 48,
                                      displayName: displayName,
                                      profilePicturePath: picturePath,
                                      fontSize: 18,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 8,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: _pickProfilePicture,
                                                icon: const Icon(
                                                  Icons.photo_camera_outlined,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  picturePath != null
                                                      ? 'Change Picture'
                                                      : 'Choose Picture',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: theme.accent,
                                                  side: BorderSide(
                                                    color: theme.border,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10,
                                                      ),
                                                ),
                                              ),
                                              if (picturePath != null)
                                                TextButton.icon(
                                                  onPressed:
                                                      _removeProfilePicture,
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    size: 16,
                                                    color: theme.statusMissing,
                                                  ),
                                                  label: Text(
                                                    'Remove Picture',
                                                    style: TextStyle(
                                                      color:
                                                          theme.statusMissing,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            picturePath != null
                                                ? 'Custom local image selected.'
                                                : 'Using initial-based avatar fallback.',
                                            style: TextStyle(
                                              color: theme.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 3. Local-Only Notice Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.surface2.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.border.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color: theme.accent,
                                  size: 24,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Local Profile Privacy',
                                        style: TextStyle(
                                          color: theme.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'This profile is stored locally on this machine. No account, password, or cloud synchronization is used.',
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
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
