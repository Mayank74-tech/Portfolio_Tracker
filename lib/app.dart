import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bindings/initial_binding.dart';
import 'presentation/routes/app_pages.dart';
import 'presentation/routes/app_routes.dart';
import 'presentation/widgets/common/app_background.dart';

class SmartPortfolioApp extends StatelessWidget {
  const SmartPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // ─── APP INFO ────────────────────────────────────────
      title: 'Smart Portfolio Tracker',
      debugShowCheckedModeBanner: false,

      // ─── THEME ───────────────────────────────────────────
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // ─── INITIAL BINDING ─────────────────────────────────
      initialBinding: InitialBinding(),

      // ─── NAVIGATION ──────────────────────────────────────
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.pages,

      // ─── FASTER TRANSITION ───────────────────────────────
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200), // 300→200ms

      // ─── GLOBAL BUILDER ──────────────────────────────────
      builder: (context, child) {
        // ✅ Lock text scale - stops layout recalc when
        // system font size changes
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.noScaling,
          ),
          // ✅ AppBackground only repaints when child changes
          // NOT on every MediaQuery/theme update
          child: AppBackground(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}