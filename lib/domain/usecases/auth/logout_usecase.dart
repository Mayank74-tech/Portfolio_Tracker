import 'dart:async';

abstract class AuthRepository {
  Future<void> logout();
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call() async {
    await repository.logout();
  }
}
