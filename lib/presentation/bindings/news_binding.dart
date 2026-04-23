import 'package:get/get.dart';

import '../controllers/news_controller.dart';
import '../controllers/portfolio_controller.dart';

class NewsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NewsController>()) {
      Get.lazyPut<NewsController>(() => NewsController());
    }
    if (!Get.isRegistered<PortfolioController>()) {
      Get.lazyPut<PortfolioController>(() => PortfolioController());
    }
  }
}
