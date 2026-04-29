import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../controllers/theme_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // PortfolioController is already registered as permanent via InitialBinding
    if (!Get.isRegistered<SettingsController>()) {
      Get.lazyPut<SettingsController>(() => SettingsController());
    }
    if (!Get.isRegistered<ThemeController>()) {
      Get.lazyPut<ThemeController>(() => ThemeController());
    }
  }
}
