/// Number and currency formatting helpers.
class Formatters {
  Formatters._();

  /// Formats a number in Indian style:
  /// 1500000 → "₹15.00L", 10000000 → "₹1.00Cr"
  static String currency(double value, {String symbol = '₹'}) {
    if (value >= 10000000) {
      return '$symbol${(value / 10000000).toStringAsFixed(2)}Cr';
    }
    if (value >= 100000) {
      return '$symbol${(value / 100000).toStringAsFixed(2)}L';
    }
    if (value >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${value.toStringAsFixed(2)}';
  }

  /// Formats a percent: 12.345 → "+12.35%"
  static String percent(double value, {int decimals = 2, bool sign = true}) {
    final formatted = value.toStringAsFixed(decimals);
    if (sign && value > 0) return '+$formatted%';
    return '$formatted%';
  }

  /// Abbreviates large numbers: 1500 → "1.5K", 1200000 → "1.2M"
  static String compact(double value) {
    if (value.abs() >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
    if (value.abs() >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
    if (value.abs() >= 1e3) return '${(value / 1e3).toStringAsFixed(1)}K';
    return value.toStringAsFixed(2);
  }

  /// Formats a quantity, removing trailing zeros for whole numbers.
  static String quantity(double qty) =>
      qty.truncateToDouble() == qty
          ? qty.toStringAsFixed(0)
          : qty.toStringAsFixed(2);
}
