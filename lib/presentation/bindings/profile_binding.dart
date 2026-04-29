import 'package:get/get.dart';

import '../controllers/portfolio_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/theme_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SettingsController>()) {
      Get.lazyPut<SettingsController>(() => SettingsController());
      Get.put(PortfolioController(), permanent: true); // ← add permanent: true

    }
    if (!Get.isRegistered<ThemeController>()) {
      Get.lazyPut<ThemeController>(() => ThemeController());
      Get.put(PortfolioController(), permanent: true); // ← add permanent: true

    }
  }
}
