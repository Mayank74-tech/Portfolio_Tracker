import 'package:get/get.dart';

import '../controllers/ai_controller.dart';
import '../controllers/portfolio_controller.dart';

class AiChatBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PortfolioController>()) {
      Get.lazyPut<PortfolioController>(() => PortfolioController());
    }
    if (!Get.isRegistered<AiController>()) {
      Get.lazyPut<AiController>(() => AiController());
    }
  }
}
