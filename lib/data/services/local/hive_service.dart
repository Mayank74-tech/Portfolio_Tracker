import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _userBox = 'user_box';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserUid = 'user_uid';

  // ─── Call once in main.dart ───────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_userBox);
  }

  // ─── Save user after login/signup ─────────────
  static Future<void> saveUser({
    required String uid,
    required String email,
    required String name,
  }) async {
    final box = Hive.box(_userBox);
    await box.put(_keyUserUid, uid);
    await box.put(_keyUserEmail, email);
    await box.put(_keyUserName, name);
  }

  // ─── Getters ──────────────────────────────────
  static String? get savedName =>
      Hive.box(_userBox).get(_keyUserName);
  static String? get savedEmail =>
      Hive.box(_userBox).get(_keyUserEmail);
  static String? get savedUid =>
      Hive.box(_userBox).get(_keyUserUid);

  // ─── Clear on logout ──────────────────────────
  static Future<void> clearUser() async {
    await Hive.box(_userBox).clear();
  }
}