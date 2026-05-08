import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/portfolio_controller.dart';
import '../controllers/stock_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/behavioral_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ PERMANENT: Must exist immediately, tiny footprint
    Get.put(ThemeController(), permanent: true);
    Get.put(AuthController(), permanent: true);

    // ✅ LAZY + FENIX: Created only when first screen needs them
    // This alone removes the 212-frame startup skip
    // fenix: true = auto-recreate if GetX GC disposes them
    Get.lazyPut<PortfolioController>(
          () => PortfolioController(),
      fenix: true,
    );

    Get.lazyPut<StockController>(
          () => StockController(),
      fenix: true,
    );

    Get.lazyPut<BehavioralController>(
          () => BehavioralController(),
      fenix: true,
    );
  }
}