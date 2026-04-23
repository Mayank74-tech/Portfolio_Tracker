import 'package:get/get.dart';

import '../controllers/portfolio_controller.dart';
import '../controllers/stock_controller.dart';

class StockDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StockController>()) {
      Get.lazyPut<StockController>(() => StockController());
    }
    if (!Get.isRegistered<PortfolioController>()) {
      Get.lazyPut<PortfolioController>(() => PortfolioController());
    }
  }
}
