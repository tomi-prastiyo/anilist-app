import 'package:intl/intl.dart';

class DateUtil {
  DateUtil._();

  /// Formats a FuzzyDate object {year, month, day} to human readable string
  static String formatFuzzyDate(Map<String, dynamic>? dateMap) {
    if (dateMap == null) return '?';
    final year = dateMap['year'] as int?;
    final month = dateMap['month'] as int?;
    final day = dateMap['day'] as int?;

    if (year == null) return '?';
    if (month == null) return '$year';
    if (day == null) return DateFormat('MMM yyyy').format(DateTime(year, month));
    return DateFormat('MMM d, yyyy').format(DateTime(year, month, day));
  }

  /// Calculates human-readable countdown string from seconds remaining until episode air
  static String formatCountdown(int? seconds) {
    if (seconds == null || seconds <= 0) return 'Aired';
    final duration = Duration(seconds: seconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Converts epoch timestamp in seconds to formatted date time
  static String formatTimestamp(int? seconds) {
    if (seconds == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  /// Relative time ago (e.g., "5m ago", "2h ago", "3d ago")
  static String timeAgo(int? seconds) {
    if (seconds == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
