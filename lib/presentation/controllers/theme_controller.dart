import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeController extends GetxController {
  static const String _boxName = 'settings_box';
  static const String _themeModeKey = 'theme_mode';

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    loadThemeMode();
  }

  Future<void> loadThemeMode() async {
    final box = await _box;
    final saved = box.get(_themeModeKey, defaultValue: 'system').toString();
    final mode = _parseThemeMode(saved);
    themeMode.value = mode;
    Get.changeThemeMode(mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);

    final box = await _box;
    await box.put(_themeModeKey, mode.name);
  }

  Future<void> toggleDarkMode(bool enabled) {
    return setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> useSystemTheme() {
    return setThemeMode(ThemeMode.system);
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<Box<dynamic>> get _box async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }
}
