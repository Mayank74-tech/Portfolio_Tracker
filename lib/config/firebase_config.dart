import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Firebase initialization helper.
class FirebaseConfig {
  FirebaseConfig._();

  static bool _initialized = false;

  /// Initializes Firebase only once. Safe to call multiple times.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        // Already initialized — safe to ignore on hot restart
        if (e.toString().contains('duplicate-app')) {
          _initialized = true;
          return;
        }
        debugPrint('FirebaseConfig.init error: $e');
      }
    }
  }

  static bool get isInitialized => _initialized;
}
