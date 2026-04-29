import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_portfolio_tracker/app.dart';
import 'package:smart_portfolio_tracker/config/hive_config.dart';
import 'package:smart_portfolio_tracker/data/services/local/hive_service.dart';
import 'package:smart_portfolio_tracker/firebase_options.dart';


/// Run Bank server
// cd mock_bank_api
// dart run bin/server.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await HiveService.init();   // opens user_box
  await HiveConfig.init();    // opens all behavioral boxes (attention, belief, decision, profile)

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const SmartPortfolioApp());
  } catch (error) {
    runApp(BootstrapErrorApp(message: _bootstrapErrorMessage(error)));
  }
}

String _bootstrapErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('Web Firebase is not configured')) {
    return 'Web Firebase is not configured yet. Add the FIREBASE_WEB_* '
        'dart-defines before running the web app.';
  }
  if (text.contains('Firebase is not configured for')) {
    return 'This project is currently configured for Android, iOS, and macOS '
        'Firebase builds.';
  }
  return 'App bootstrap failed: $text';
}

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Startup configuration issue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
