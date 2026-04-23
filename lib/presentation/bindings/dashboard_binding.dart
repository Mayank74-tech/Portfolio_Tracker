import 'package:get/get.dart';

import '../controllers/portfolio_controller.dart';
import '../controllers/watchlist_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PortfolioController>()) {
      Get.lazyPut<PortfolioController>(() => PortfolioController());
    }
    if (!Get.isRegistered<WatchlistController>()) {
      Get.lazyPut<WatchlistController>(() => WatchlistController());
    }
  }
}
