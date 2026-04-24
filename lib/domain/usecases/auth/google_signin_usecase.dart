import 'dart:async';

import '../../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithGoogle();
}

class GoogleSignInUseCase {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  Future<UserEntity> call() async {
    return await repository.signInWithGoogle();
  }
}
