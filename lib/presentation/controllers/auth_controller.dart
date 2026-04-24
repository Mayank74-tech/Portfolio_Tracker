import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../routes/app_routes.dart';
import '../../data/services/local/hive_service.dart';

class AuthController extends GetxController {
  final AuthRepository _repo = AuthRepository();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<User> firebaseUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_repo.authStateChanges);
    ever(firebaseUser, _handleAuthChange);
  }

  // ─── Auth state handler ───────────────────────
  void _handleAuthChange(User? user) {
    if (Get.currentRoute == AppRoutes.SPLASH) return;
    if (user != null) {
      Get.offAllNamed(AppRoutes.DASHBOARD);
    } else {
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }

  // ─── Email Login ──────────────────────────────
  Future<void> loginWithEmail(String email, String password) async {
    try {
      isLoading(true);
      errorMessage('');
      final user = await _repo.loginWithEmail(email, password);
      if (user != null) {
        await HiveService.saveUser(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? email.split('@').first,
        );
      }
    } on FirebaseAuthException catch (e) {
      errorMessage(_mapError(e.code));
    } finally {
      isLoading(false);
    }
  }

  // ─── Email Signup ─────────────────────────────
  Future<void> signupWithEmail(
      String email, String password, String name) async {
    try {
      isLoading(true);
      errorMessage('');
      final user = await _repo.signupWithEmail(email, password);
      await user?.updateDisplayName(name);
      if (user != null) {
        await HiveService.saveUser(
          uid: user.uid,
          email: user.email ?? '',
          name: name,
        );
      }
    } on FirebaseAuthException catch (e) {
      errorMessage(_mapError(e.code));
    } finally {
      isLoading(false);
    }
  }

  // ─── Google Sign-In ───────────────────────────
  Future<void> signInWithGoogle() async {
    try {
      isLoading(true);
      errorMessage('');
      await _repo.signInWithGoogle();
    } catch (e) {
      errorMessage('Google sign-in cancelled.');
    } finally {
      isLoading(false);
    }
  }

  // ─── Logout ───────────────────────────────────
  Future<void> logout() async {
    await _repo.logout();
    await HiveService.clearUser();
  }

  // ─── Password Reset ───────────────────────────
  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Enter your email first',
        backgroundColor: const Color(0xFF1E293B),
        colorText: const Color(0xFFF1F5F9),
      );
      return;
    }
    try {
      isLoading(true);
      await _repo.sendPasswordResetEmail(email);
      Get.snackbar(
        'Email Sent',
        'Check your inbox to reset your password',
        backgroundColor: const Color(0xFF1E293B),
        colorText: const Color(0xFFF1F5F9),
      );
    } on FirebaseAuthException catch (e) {
      errorMessage(_mapError(e.code));
    } finally {
      isLoading(false);
    }
  }

  // ─── Error mapper ─────────────────────────────
  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Something went wrong. Try again.';
    }
  }
}
