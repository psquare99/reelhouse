/// Contract for cross-platform file and directory selection.
///
/// Provides a unified, testable abstraction over native file dialogs:
/// - Windows: Native Open, Save, and Folder selection dialogs.
/// - Android: SAF Document/Directory pickers.
/// - Web / Linux / macOS: Standard platform-appropriate file pickers.
abstract class FilePickerService {
  /// Prompts the user to select a directory/folder.
  /// Returns the selected directory path, or `null` if cancelled by the user.
  Future<String?> pickDirectory({String? dialogTitle});

  /// Prompts the user to select a REELHOUSE JSON backup file for import.
  /// Returns the selected file path, or `null` if cancelled by the user.
  Future<String?> pickBackupFile({String? dialogTitle});

  /// Prompts the user to choose a save destination for an exported backup JSON file.
  /// Returns the chosen file path, or `null` if cancelled by the user.
  Future<String?> saveBackupFile({
    String? dialogTitle,
    String? suggestedFileName,
  });
}
