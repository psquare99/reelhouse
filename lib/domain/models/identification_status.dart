/// Durable identification state of a logical media item in MATINEE.
///
/// Discovered filesystem names are discovery hints, NOT canonical media identity.
/// Network/provider failures are operational failures, not durable identity states.
enum IdentificationStatus {
  /// Item was parsed from the filesystem and has not yet been matched against a metadata provider.
  pending,

  /// Item was matched with high confidence or manually confirmed by the user.
  identified,

  /// Item match is ambiguous or requires user review in the verification queue.
  needsVerification;

  static IdentificationStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'IDENTIFIED':
        return IdentificationStatus.identified;
      case 'NEEDS_VERIFICATION':
        return IdentificationStatus.needsVerification;
      case 'PENDING':
      default:
        return IdentificationStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case IdentificationStatus.pending:
        return 'PENDING';
      case IdentificationStatus.identified:
        return 'IDENTIFIED';
      case IdentificationStatus.needsVerification:
        return 'NEEDS_VERIFICATION';
    }
  }
}
