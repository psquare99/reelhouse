import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/services/file_picker_service_impl.dart';
import '../../domain/models/library_backup_models.dart';
import '../../domain/services/file_picker_service.dart';
import '../../domain/services/library_backup_service.dart';

class ExportBackupDialog extends StatefulWidget {
  final LibraryBackupService libraryBackupService;
  final FilePickerService? filePickerService;

  const ExportBackupDialog({
    super.key,
    required this.libraryBackupService,
    this.filePickerService,
  });

  @override
  State<ExportBackupDialog> createState() => _ExportBackupDialogState();
}

class _ExportBackupDialogState extends State<ExportBackupDialog> {
  late final FilePickerService _filePickerService;
  String? _selectedPath;
  bool _isExporting = false;
  bool _isPicking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filePickerService = widget.filePickerService ?? FilePickerServiceImpl();
  }

  String _generateSuggestedFilename() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    return 'reelhouse_backup_$timestamp.json';
  }

  Future<void> _pickSaveLocation() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });

    try {
      final path = await _filePickerService.saveBackupFile(
        dialogTitle: 'Save MATINEE Backup',
        suggestedFileName: _generateSuggestedFilename(),
      );
      if (!mounted) return;
      setState(() {
        _isPicking = false;
        if (path != null && path.trim().isNotEmpty) {
          _selectedPath = path.trim();
          _error = null;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPicking = false;
          _error = 'Save location selection failed: $e';
        });
      }
    }
  }

  Future<void> _executeExport(String targetPath) async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = CinemaTheme.of(context);

    try {
      final savedPath = await widget.libraryBackupService.exportBackupToFile(
        targetPath,
      );
      if (!mounted) return;
      setState(() {
        _isExporting = false;
      });
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Library exported successfully to $savedPath',
            style: TextStyle(color: theme.textPrimary),
          ),
          backgroundColor: theme.surface2,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _error = 'Export failed: $e';
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
        'Export Library Backup',
        style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a versioned, portable backup of your MATINEE catalogue, custom collections, and watch states.',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: theme.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Included: Movies, TV Shows, Episodes, Collections, Watch History, User Preferences',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: theme.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Excluded: Video files and TMDB API credentials (never exported)',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose where to save your backup.',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            if (_selectedPath == null) ...[
              OutlinedButton.icon(
                onPressed: _isExporting || _isPicking
                    ? null
                    : _pickSaveLocation,
                icon: _isPicking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open, size: 18),
                label: Text(
                  _isPicking ? 'Selecting...' : 'Choose Save Location',
                ),
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
                    Icon(Icons.save_as_outlined, color: theme.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Save Location',
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
                      tooltip: 'Change Location',
                      onPressed: _isExporting || _isPicking
                          ? null
                          : _pickSaveLocation,
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
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
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: _isExporting
              ? null
              : () async {
                  if (_selectedPath != null) {
                    await _executeExport(_selectedPath!);
                  } else {
                    final path = await _filePickerService.saveBackupFile(
                      dialogTitle: 'Save MATINEE Backup',
                      suggestedFileName: _generateSuggestedFilename(),
                    );
                    if (path != null && path.trim().isNotEmpty && mounted) {
                      _selectedPath = path.trim();
                      await _executeExport(path.trim());
                    }
                  }
                },
          icon: _isExporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download, size: 16),
          label: Text(_isExporting ? 'Exporting...' : 'Export Backup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.accent,
            foregroundColor: theme.onAccent,
          ),
        ),
      ],
    );
  }
}

class ImportBackupDialog extends StatefulWidget {
  final LibraryBackupService libraryBackupService;
  final VoidCallback onImportSuccess;
  final FilePickerService? filePickerService;

  const ImportBackupDialog({
    super.key,
    required this.libraryBackupService,
    required this.onImportSuccess,
    this.filePickerService,
  });

  @override
  State<ImportBackupDialog> createState() => _ImportBackupDialogState();
}

class _ImportBackupDialogState extends State<ImportBackupDialog> {
  late final FilePickerService _filePickerService;
  String? _selectedPath;
  BackupSummary? _summary;
  BackupImportResult? _importResult;
  bool _isPicking = false;
  bool _isInspecting = false;
  bool _isImporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filePickerService = widget.filePickerService ?? FilePickerServiceImpl();
  }

  Future<void> _pickBackupFile() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });

    try {
      final path = await _filePickerService.pickBackupFile(
        dialogTitle: 'Select MATINEE Backup File',
      );
      if (!mounted) return;

      if (path != null && path.trim().isNotEmpty) {
        final cleanPath = path.trim();
        setState(() {
          _selectedPath = cleanPath;
          _isPicking = false;
          _isInspecting = true;
          _error = null;
          _summary = null;
        });

        try {
          final s = await widget.libraryBackupService.inspectBackupFile(
            cleanPath,
          );
          if (mounted) {
            setState(() {
              _summary = s;
              _isInspecting = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = 'Failed to inspect backup: $e';
              _summary = null;
              _isInspecting = false;
            });
          }
        }
      } else {
        setState(() {
          _isPicking = false;
          // Cancellation is not an error
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPicking = false;
          _error = 'File selection failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CinemaTheme.of(context);

    if (_importResult != null) {
      final result = _importResult!;
      return AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Import Complete',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully reconciled backup into library:',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              '• ${result.moviesImported} new movies added (${result.moviesUpdated} updated)\n'
              '• ${result.showsImported} new shows, ${result.episodesImported} new episodes (${result.episodesUpdated} watch states merged)\n'
              '• ${result.collectionsImported} collections restored (${result.collectionsUpdated} updated)',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Warnings: ${result.warnings.length} items skipped or modified.',
                style: TextStyle(color: theme.warning, fontSize: 11),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: theme.surface,
      title: Text(
        'Import Library Backup',
        style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500),
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a MATINEE backup to restore.',
              style: TextStyle(color: theme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (_selectedPath == null) ...[
              OutlinedButton.icon(
                onPressed: _isPicking || _isInspecting || _isImporting
                    ? null
                    : _pickBackupFile,
                icon: _isPicking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_open, size: 18),
                label: Text(_isPicking ? 'Selecting...' : 'Choose Backup'),
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
                    Icon(
                      Icons.inventory_2_outlined,
                      color: theme.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup File',
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
                      tooltip: 'Change Backup',
                      onPressed: _isPicking || _isInspecting || _isImporting
                          ? null
                          : _pickBackupFile,
                    ),
                  ],
                ),
              ),
            ],
            if (_isInspecting) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Inspecting backup file...',
                    style: TextStyle(color: theme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (_summary != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup Payload Overview (v${_summary!.formatVersion})',
                      style: TextStyle(
                        color: theme.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ${_summary!.movieCount} Movies\n'
                      '• ${_summary!.tvShowCount} TV Shows (${_summary!.seasonCount} Seasons, ${_summary!.episodeCount} Episodes)\n'
                      '• ${_summary!.collectionCount} Curated Collections\n'
                      '• Exported: ${_summary!.exportedAt.toLocal().toString().split('.').first}',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.warningSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: theme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notice: Media files are NOT included in backups. Physical files must exist on your storage devices. Imported items remain unavailable until original media sources are scanned.',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
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
          onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed:
              (_isImporting ||
                  _isInspecting ||
                  _selectedPath == null ||
                  _summary == null)
              ? null
              : () async {
                  final path = _selectedPath!;
                  setState(() {
                    _isImporting = true;
                    _error = null;
                  });

                  final result = await widget.libraryBackupService
                      .importBackupFromFile(path);
                  if (!mounted) return;
                  if (result.success) {
                    widget.onImportSuccess();
                    setState(() {
                      _isImporting = false;
                      _importResult = result;
                    });
                  } else {
                    setState(() {
                      _isImporting = false;
                      _error =
                          'Import failed: ${result.errorMessage ?? 'Unknown error'}';
                    });
                  }
                },
          icon: _isImporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload, size: 16),
          label: Text(_isImporting ? 'Importing...' : 'Restore Library'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.accent,
            foregroundColor: theme.onAccent,
          ),
        ),
      ],
    );
  }
}
