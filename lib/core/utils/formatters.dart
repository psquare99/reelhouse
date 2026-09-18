/// Utility functions for displaying media metrics and timestamps.
class Formatters {
  const Formatters._();

  /// Format byte size into human readable string (e.g. 14.2 GB, 850 MB).
  static String formatBytes(BigInt bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    const tb = gb * 1024;

    final b = bytes.toDouble();
    if (b >= tb) {
      return '${(b / tb).toStringAsFixed(1)} TB';
    } else if (b >= gb) {
      return '${(b / gb).toStringAsFixed(1)} GB';
    } else if (b >= mb) {
      return '${(b / mb).toStringAsFixed(1)} MB';
    } else if (b >= kb) {
      return '${(b / kb).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  /// Format runtime in minutes to cinematic "2h 49m" format.
  static String formatRuntime(int? minutes) {
    if (minutes == null || minutes <= 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) {
      return '${h}h ${m}m';
    } else if (h > 0) {
      return '${h}h';
    } else {
      return '${m}m';
    }
  }

  /// Format duration in seconds to MM:SS or H:MM:SS format (e.g. "18:42" or "1:14:22").
  static String formatDurationSeconds(int seconds) {
    if (seconds <= 0) return '0:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final sStr = s.toString().padLeft(2, '0');
    if (h > 0) {
      final mStr = m.toString().padLeft(2, '0');
      return '$h:$mStr:$sStr';
    } else {
      return '$m:$sStr';
    }
  }
}
