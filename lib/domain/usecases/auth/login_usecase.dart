import 'dart:async';

import '../../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
}

class LoginParams {
  final String email;
  final String password;

  LoginParams({required this.email, required this.password});
}

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> call(LoginParams params) async {
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(params.email)) {
      throw ArgumentError('Invalid email format.');
    }
    if (params.password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }
    return await repository.login(
        email: params.email, password: params.password);
  }
}
