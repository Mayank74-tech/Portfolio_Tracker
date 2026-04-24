import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static const String _webApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const String _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String _webMessagingSenderId =
      String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID');

  static bool get hasWebConfig =>
      _webApiKey.isNotEmpty &&
      _webAppId.isNotEmpty &&
      _webMessagingSenderId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      if (!hasWebConfig) {
        throw UnsupportedError(
          'Web Firebase is not configured. Provide FIREBASE_WEB_API_KEY, '
          'FIREBASE_WEB_APP_ID, and FIREBASE_WEB_MESSAGING_SENDER_ID with '
          '--dart-define before running the web app.',
        );
      }
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMoHf2haEbM3YVOjOHu_g3KXWeUqCrsA0',
    appId: '1:996665433448:android:93b331279813a86b33cadd',
    messagingSenderId: '996665433448',
    projectId: 'smart-portfolio-tracker',
    storageBucket: 'smart-portfolio-tracker.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC50ryAhAdelKDxVzZHwqvaJ4KmLT-CKjo',
    appId: '1:996665433448:ios:5fd962df254563d033cadd',
    messagingSenderId: '996665433448',
    projectId: 'smart-portfolio-tracker',
    storageBucket: 'smart-portfolio-tracker.firebasestorage.app',
    iosBundleId: 'com.example.smartPortfolioTracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC50ryAhAdelKDxVzZHwqvaJ4KmLT-CKjo',
    appId: '1:996665433448:ios:5fd962df254563d033cadd',
    messagingSenderId: '996665433448',
    projectId: 'smart-portfolio-tracker',
    storageBucket: 'smart-portfolio-tracker.firebasestorage.app',
    iosBundleId: 'com.example.smartPortfolioTracker',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _webApiKey,
    appId: _webAppId,
    messagingSenderId: _webMessagingSenderId,
    projectId: 'smart-portfolio-tracker',
    authDomain: 'smart-portfolio-tracker.firebaseapp.com',
    storageBucket: 'smart-portfolio-tracker.firebasestorage.app',
  );
}
