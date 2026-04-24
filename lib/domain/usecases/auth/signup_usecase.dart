import 'dart:async';

import '../../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signUp({
    required String username,
    required String email,
    required String password,
  });
}

class SignUpParams {
  final String username;
  final String email;
  final String password;

  SignUpParams(
      {required this.username, required this.email, required this.password});
}

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<UserEntity> call(SignUpParams params) async {
    if (params.username.trim().length < 3) {
      throw ArgumentError('Username must be at least 3 characters.');
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(params.email)) {
      throw ArgumentError('Invalid email format.');
    }
    if (params.password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }
    return await repository.signUp(
      username: params.username,
      email: params.email,
      password: params.password,
    );
  }
}
