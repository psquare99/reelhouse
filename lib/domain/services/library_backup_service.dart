import '../models/library_backup_models.dart';

/// Application domain service for exporting and importing versioned REELHOUSE library backups.
///
/// Implements RC.1 requirements:
/// - Portable versioned JSON representation of logical library data.
/// - Excludes all physical paths, machine identifiers, media files, and secrets (TMDB credentials).
/// - Atomic transactional import with canonical deduplication and watch state reconciliation.
abstract interface class LibraryBackupService {
  /// Generates a portable, versioned [LibraryBackupPayload] from the current local database and settings.
  Future<LibraryBackupPayload> createBackupPayload();

  /// Exports the library backup directly to a JSON file at [targetFilePath] and returns the path.
  Future<String> exportBackupToFile(String targetFilePath);

  /// Inspects a backup file and returns its high-level [BackupSummary] without mutating state.
  Future<BackupSummary> inspectBackupFile(String filePath);

  /// Inspects a raw JSON string payload and returns its [BackupSummary] without mutating state.
  Future<BackupSummary> inspectBackupJson(String jsonContent);

  /// Reads, validates, and imports a backup file transactionally into the local library.
  Future<BackupImportResult> importBackupFromFile(String filePath);

  /// Validates and imports a [LibraryBackupPayload] transactionally into the local library.
  Future<BackupImportResult> importBackupPayload(LibraryBackupPayload payload);
}
