/// Base exception for all app-specific errors.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException($code): $message';
}

/// Thrown when a remote API call fails (non-2xx, timeout, parse error).
class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

/// Thrown when local cache read/write fails (Hive errors).
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// Thrown when there is no internet connectivity.
class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection.'])
      : super(message, code: 'NETWORK_ERROR');
}

/// Thrown when Firebase Auth operations fail.
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Thrown when Firestore read/write fails.
class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.code});
}

/// Thrown when required environment variables are missing.
class ConfigurationException extends AppException {
  const ConfigurationException(super.message)
      : super(code: 'CONFIG_MISSING');
}
