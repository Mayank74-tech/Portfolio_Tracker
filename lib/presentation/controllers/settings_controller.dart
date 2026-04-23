import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/services/local/cache_manager.dart';

class SettingsController extends GetxController {
  static const String _boxName = 'settings_box';
  static const String _currencyKey = 'currency';
  static const String _notificationsKey = 'notifications_enabled';

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString currency = 'INR'.obs;
  final RxBool notificationsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      isLoading.value = true;
      final box = await _box;
      currency.value = box.get(_currencyKey, defaultValue: 'INR').toString();
      notificationsEnabled.value =
          box.get(_notificationsKey, defaultValue: true) == true;
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setCurrency(String value) async {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) return;

    currency.value = normalized;
    final box = await _box;
    await box.put(_currencyKey, normalized);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    final box = await _box;
    await box.put(_notificationsKey, value);
  }

  Future<void> clearCache() async {
    await CacheManager.clear();
  }

  void clearError() {
    errorMessage.value = '';
  }

  Future<Box<dynamic>> get _box async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }
}
