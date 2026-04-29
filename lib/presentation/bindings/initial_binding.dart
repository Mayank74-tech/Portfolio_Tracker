// lib/presentation/bindings/initial_binding.dart

import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/portfolio_controller.dart';
import '../controllers/stock_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/behavioral_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(PortfolioController(), permanent: true);
    Get.put(StockController(), permanent: true);
    Get.put(BehavioralController(), permanent: true); // ← add this
  }
}