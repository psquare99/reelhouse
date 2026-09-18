import '../../data/database/database.dart' show MediaSource;
import '../models/transfer_models.dart';

/// Abstract service contract for copying cinema media onto application-managed device storage.
///
/// Implements M5.2 Transfer Engine:
/// - Supports copying movies, episodes, and seasons.
/// - Performs live source availability resolution.
/// - Validates destination capacity pre-check before starting transfer.
/// - Executes buffered chunked filesystem copying to a safe temporary artifact (.reelhouse-partial).
/// - Exposes stream and callback progress reporting.
/// - Supports cooperative cancellation and failure handling.
/// - Enforces duplicate transfer protection and persists transfer records in SQLite.
abstract class TransferService {
  /// Stream emitting real-time progress events for all active transfer operations.
  Stream<TransferProgress> get progressStream;

  /// Transfers a single movie to application-managed device storage.
  ///
  /// Resolves the currently connected/available source, validates destination capacity,
  /// copies data to a temporary destination artifact, and persists state across execution.
  Future<TransferResult> transferMovie(
    String movieId, {
    CancellationToken? cancellationToken,
    void Function(TransferProgress progress)? onProgress,
  });

  /// Transfers a single TV episode to application-managed device storage.
  Future<TransferResult> transferEpisode(
    String episodeId, {
    CancellationToken? cancellationToken,
    void Function(TransferProgress progress)? onProgress,
  });

  /// Transfers all canonical episodes of a TV season to application-managed device storage.
  ///
  /// Pre-calculates aggregate capacity for all transferable episodes, validates available
  /// device space before starting, and transfers episodes sequentially with aggregate and
  /// per-episode progress reporting. TV extras (Season -1) are excluded.
  Future<List<TransferResult>> transferSeason(
    String seasonId, {
    CancellationToken? cancellationToken,
    void Function(TransferProgress progress)? onProgress,
  });

  /// Cancels an ongoing transfer by its transfer ID or media ID.
  Future<bool> cancelTransfer(String transferId);

  /// Checks if a logical media item (movieId, episodeId, or seasonId) is actively transferring.
  bool isMediaTransferring(String mediaId);

  /// Returns the current active progress snapshot for a media item, if transferring.
  TransferProgress? getActiveProgress(String mediaId);

  /// Reconciles all non-terminal or interrupted transfer jobs against the physical filesystem.
  ///
  /// Evaluates interrupted jobs:
  /// - Jobs interrupted in `VERIFYING` with valid `.reelhouse-partial` artifacts are verified
  ///   and atomically finalized to `COMPLETED`.
  /// - Jobs interrupted in `TRANSFERRING`, `PREPARING`, or `QUEUED` are marked `FAILED`
  ///   as interrupted, and incomplete partial files are safely cleaned up for clean retry.
  /// - Valid, already-finalized destination files are recognized idempotently.
  ///
  /// Safe and idempotent to invoke at application startup or on demand.
  Future<List<TransferResult>> reconcileTransfers();

  /// Cleans stale or orphaned `.reelhouse-partial` files in application-managed device storage.
  ///
  /// Only deletes partial files that are confirmed not to belong to any active transfer.
  Future<int> cleanStalePartials();

  /// Registers a finalized and verified [TransferJob] as an active, playable [MediaSource]
  /// for the corresponding canonical logical Movie or Episode.
  ///
  /// Validation & Security:
  /// - Transfer must exist and have status strictly `COMPLETED`.
  /// - Final destination file must exist on disk (`.reelhouse-partial` is rejected).
  /// - Target logical media item (Movie or Episode) must exist.
  /// - Destination storage must be registered.
  ///
  /// Idempotent: safe to call repeatedly without creating duplicate [MediaSource] records.
  Future<MediaSource> registerCompletedTransfer(String transferId);

  /// Registers all completed episode transfers for a TV season.
  Future<List<MediaSource>> registerCompletedSeasonTransfers(String seasonId);
}
