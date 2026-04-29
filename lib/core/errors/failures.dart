/// Base failure class — used in the domain layer instead of exceptions.
/// Repositories catch exceptions and convert them to Failures.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '${runtimeType}: $message';
}

/// Remote API call failed.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Local Hive cache operation failed.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Device has no internet access.
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection.'])
      : super(message);
}

/// Firebase Auth error.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Firestore read/write error.
class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}

/// Missing API key or environment config.
class ConfigurationFailure extends Failure {
  const ConfigurationFailure(super.message);
}
