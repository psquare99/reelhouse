import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../domain/services/file_picker_service.dart';

/// Concrete implementation of [FilePickerService] using the `file_picker` package.
class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<String?> pickDirectory({String? dialogTitle}) async {
    try {
      final selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: dialogTitle ?? 'Select Media Folder',
      );
      return selectedPath;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> pickBackupFile({String? dialogTitle}) async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: dialogTitle ?? 'Select REELHOUSE Backup File',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      return file?.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> saveBackupFile({
    String? dialogTitle,
    String? suggestedFileName,
  }) async {
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: dialogTitle ?? 'Save REELHOUSE Backup',
        fileName: suggestedFileName ?? 'reelhouse_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List(0),
      );
      if (uri == null) return null;
      if (uri.hasScheme && uri.scheme == 'file') {
        return uri.toFilePath();
      }
      return uri.path;
    } catch (_) {
      return null;
    }
  }
}
