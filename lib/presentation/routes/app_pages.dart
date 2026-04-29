import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/screens/dashboard/dashboard_screen.dart';
import '../bindings/auth_binding.dart';
import '../bindings/dashboard_binding.dart';
import '../bindings/stock_detail_binding.dart';
import '../bindings/ai_chat_binding.dart';
import '../bindings/news_binding.dart';
import '../bindings/profile_binding.dart';
import '../screens/holding_screen/holdings_screen.dart';
import '../screens/insights/attention_map_screen.dart';
import '../screens/insights/identity_drift_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/insights/memory_reality_screen.dart';
import '../screens/insights/time_machine_screen.dart';
import '../screens/insights/uncertainty_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/main_navigation_screen.dart';
import '../screens/stock_detail/stock_detail_screen.dart';
import '../screens/add_stock/add_stock_screen.dart';
import '../screens/import_csv/import_csv_screen.dart';
import '../screens/ai_chat/ai_chat_screen.dart';
import '../screens/market_news/market_news_screen.dart';
import '../screens/market_news/news_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/success/success_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    // ─── SPLASH ──────────────────────────────────
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashScreen(),
    ),

    // ─── ONBOARDING ──────────────────────────────
    GetPage(
      name: AppRoutes.ONBOARDING,
      page: () => const OnboardingScreen(),
    ),

    // ─── AUTH ────────────────────────────────────
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.SIGNUP,
      page: () => const SignupScreen(),
      binding: AuthBinding(),
    ),

    // ─── DASHBOARD (with bottom nav) ─────────────
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => const MainNavigationScreen(child: DashboardScreen()),
      binding: DashboardBinding(),
      transition: Transition.fadeIn,
    ),

    // ─── STOCK DETAIL (no bottom nav) ────────────
    GetPage(
      name: AppRoutes.STOCK_DETAIL,
      page: () => const StockDetailScreen(),
      binding: StockDetailBinding(),
      transition: Transition.rightToLeft,
    ),

    // ─── ADD STOCK (no bottom nav) ───────────────
    GetPage(
      name: AppRoutes.ADD_STOCK,
      page: () => const AddStockScreen(),
      binding: StockDetailBinding(),
      transition: Transition.downToUp,
    ),

    // ─── IMPORT CSV (no bottom nav) ──────────────
    GetPage(
      name: AppRoutes.IMPORT_CSV,
      page: () => const ImportCsvScreen(),
      transition: Transition.downToUp,
    ),

    // ─── AI CHAT (with bottom nav) ───────────────
    GetPage(
      name: AppRoutes.AI_CHAT,
      page: () => const MainNavigationScreen(child: AiChatScreen()),
      binding: AiChatBinding(),
      // transition: Transition.rightToLeft,
      // preventDuplicates: true,
    ),

    // ─── MARKET NEWS (with bottom nav) ───────────
    GetPage(
      name: AppRoutes.MARKET_NEWS,
      page: () => const MainNavigationScreen(child: MarketNewsScreen()),
      binding: NewsBinding(),
    ),
    GetPage(
      name: AppRoutes.NEWS_DETAIL,
      page: () => const NewsDetailScreen(),
      transition: Transition.rightToLeft,
    ),

    // ─── PROFILE (with bottom nav) ───────────────
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const MainNavigationScreen(child: ProfileScreen()),
      binding: ProfileBinding(),
    ),

    // ─── SUCCESS ─────────────────────────────────
    GetPage(
      name: AppRoutes.SUCCESS,
      page: () => const SuccessScreen(),
      transition: Transition.zoom,
    ),

    GetPage(name: AppRoutes.HOLDINGS,
        page: () => const HoldingsScreen()),

    GetPage(
      name: AppRoutes.INSIGHTS,
      page: () => const InsightsScreen(),
    ),
    GetPage(name: AppRoutes.INSIGHTS,
        page: () => const InsightsScreen()),
    GetPage(name: AppRoutes.MEMORY_REALITY,
        page: () => const MemoryRealityScreen()),
    GetPage(name: AppRoutes.TIME_MACHINE,
        page: () => const TimeMachineScreen()),
    GetPage(name: AppRoutes.ATTENTION_MAP,
        page: () => const AttentionMapScreen()),
    GetPage(name: AppRoutes.UNCERTAINTY,
        page: () => const UncertaintyScreen()),
    GetPage(name: AppRoutes.IDENTITY_DRIFT,
        page: () => const IdentityDriftScreen()),
  ];
}
