import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bindings/initial_binding.dart';
import 'presentation/routes/app_pages.dart';
import 'presentation/routes/app_routes.dart';

class SmartPortfolioApp extends StatelessWidget {
  const SmartPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // ─── APP INFO ──────────────────────────────────────
      title: 'Smart Portfolio Tracker',
      debugShowCheckedModeBanner: false,

      // ─── THEME ─────────────────────────────────────────
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ─── INITIAL BINDING (runs before app loads) ───────
      initialBinding: InitialBinding(),

      // ─── NAVIGATION STARTS FROM SPLASH ─────────────────
      initialRoute: AppRoutes.SPLASH,

      // ─── ALL ROUTES REGISTERED ─────────────────────────
      getPages: AppPages.pages,

      // ─── DEFAULT TRANSITION ────────────────────────────
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
