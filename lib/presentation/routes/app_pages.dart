import 'package:get/get.dart';
import 'package:smart_portfolio_tracker/presentation/screens/dashboard/dashboard_screen.dart';
import '../bindings/auth_binding.dart';
import '../bindings/dashboard_binding.dart';
import '../bindings/stock_detail_binding.dart';
import '../bindings/ai_chat_binding.dart';
import '../bindings/news_binding.dart';
import '../bindings/profile_binding.dart';
import '../screens/finance/spending_analysis_screen.dart';
import '../screens/finance/transactions_screen.dart';
import '../screens/finance/finance_dashboard_screen.dart';
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
  AppPages._(); // ✅ Prevent instantiation

  static final pages = [

    // ─── SPLASH ──────────────────────────────────────────
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashScreen(),
      // ✅ No animation for splash - saves first-frame time
      transition: Transition.noTransition,
    ),

    // ─── ONBOARDING ──────────────────────────────────────
    GetPage(
      name: AppRoutes.ONBOARDING,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    // ─── AUTH ─────────────────────────────────────────────
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.SIGNUP,
      page: () => const SignupScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    // ─── DASHBOARD ────────────────────────────────────────
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => const MainNavigationScreen(child: DashboardScreen()),
      binding: DashboardBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      // ✅ Fixes: [GETX] REMOVING ROUTE /dashboard (appeared twice in logs)
      preventDuplicates: true,
    ),

    // ─── STOCK DETAIL ─────────────────────────────────────
    GetPage(
      name: AppRoutes.STOCK_DETAIL,
      page: () => const StockDetailScreen(),
      binding: StockDetailBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    // ─── ADD STOCK ────────────────────────────────────────
    GetPage(
      name: AppRoutes.ADD_STOCK,
      page: () => const AddStockScreen(),
      binding: StockDetailBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    // ─── IMPORT CSV ───────────────────────────────────────
    GetPage(
      name: AppRoutes.IMPORT_CSV,
      page: () => const ImportCsvScreen(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    // ─── AI CHAT ──────────────────────────────────────────
    GetPage(
      name: AppRoutes.AI_CHAT,
      page: () => const MainNavigationScreen(child: AiChatScreen()),
      binding: AiChatBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      preventDuplicates: true,
    ),

    // ─── MARKET NEWS ──────────────────────────────────────
    GetPage(
      name: AppRoutes.MARKET_NEWS,
      page: () => const MainNavigationScreen(child: MarketNewsScreen()),
      binding: NewsBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      preventDuplicates: true,
    ),
    GetPage(
      name: AppRoutes.NEWS_DETAIL,
      page: () => const NewsDetailScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    // ─── PROFILE ──────────────────────────────────────────
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const MainNavigationScreen(child: ProfileScreen()),
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      preventDuplicates: true,
    ),

    // ─── SUCCESS ──────────────────────────────────────────
    GetPage(
      name: AppRoutes.SUCCESS,
      page: () => const SuccessScreen(),
      transition: Transition.zoom,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    // ─── HOLDINGS ─────────────────────────────────────────
    GetPage(
      name: AppRoutes.HOLDINGS,
      page: () => const HoldingsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    // ─── INSIGHTS ─────────────────────────────────────────
    GetPage(
      name: AppRoutes.INSIGHTS,
      page: () => const InsightsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
      preventDuplicates: true,
    ),
    GetPage(
      name: AppRoutes.MEMORY_REALITY,
      page: () => const MemoryRealityScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.TIME_MACHINE,
      page: () => const TimeMachineScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.ATTENTION_MAP,
      page: () => const AttentionMapScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.UNCERTAINTY,
      page: () => const UncertaintyScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.IDENTITY_DRIFT,
      page: () => const IdentityDriftScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),

    // ─── FINANCE ──────────────────────────────────────────
    GetPage(
      name: AppRoutes.TRANSACTIONS,
      page: () => const TransactionsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.SPENDING_ANALYSIS,
      page: () => const SpendingAnalysisScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.FINANCE_DASHBOARD,
      page: () => const FinanceDashboardScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 200),
      preventDuplicates: true,
    ),
  ];
}