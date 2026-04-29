/// Date formatting helpers used across the app.
class DateHelper {
  DateHelper._();

  /// Formats a DateTime as dd/MM/yyyy.
  static String formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  /// Formats a DateTime as "12 Apr 2025".
  static String formatReadable(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  /// Returns a relative time string: "2h ago", "3d ago", "just now".
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Safely parses an ISO 8601 string; returns null on failure.
  static DateTime? tryParse(String? raw) =>
      raw != null ? DateTime.tryParse(raw) : null;

  /// Returns the number of calendar days between two dates.
  static int daysBetween(DateTime from, DateTime to) =>
      to.difference(from).inDays.abs();

  /// True if the date is today.
  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }
}
