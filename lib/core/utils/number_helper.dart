/// Generic numeric helpers.
class NumberHelper {
  NumberHelper._();

  /// Safely converts any value to double.
  static double toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  /// Clamps a value between [min] and [max].
  static double clamp(double value, double min, double max) =>
      value.clamp(min, max);

  /// Returns 0 if value is NaN or Infinity.
  static double safe(double v) => v.isFinite ? v : 0.0;

  /// Rounds to [decimals] places.
  static double round(double v, int decimals) {
    final factor = pow(10, decimals);
    return (v * factor).round() / factor;
  }

  /// Calculates percentage: (part / total) * 100.
  static double percent(double part, double total) =>
      total == 0 ? 0.0 : (part / total) * 100;

  /// Simple percentage change: ((now - then) / then) * 100.
  static double changePercent(double then, double now) =>
      then == 0 ? 0.0 : ((now - then) / then) * 100;

  static double pow(num base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
