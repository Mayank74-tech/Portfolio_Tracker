/// Form and input validators used in auth, add-stock, and settings screens.
class Validators {
  Validators._();

  /// Returns null if valid, or an error string if invalid.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    final regex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'Value'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    final n = double.tryParse(value.trim());
    if (n == null) return '$field must be a valid number.';
    if (n <= 0) return '$field must be greater than zero.';
    return null;
  }

  static String? stockSymbol(String? value) {
    if (value == null || value.trim().isEmpty) return 'Stock symbol is required.';
    if (value.trim().length < 1 || value.trim().length > 12) {
      return 'Enter a valid stock symbol (1–12 characters).';
    }
    return null;
  }

  /// Returns true if the string is a valid ISO 8601 date.
  static bool isValidDate(String? value) =>
      value != null && DateTime.tryParse(value) != null;
}
