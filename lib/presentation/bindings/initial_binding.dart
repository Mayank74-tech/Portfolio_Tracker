// import 'package:get/get.dart';
// import '../controllers/theme_controller.dart';
// import '../controllers/settings_controller.dart';
// import '../../data/services/local/hive_service.dart';
// import '../../data/services/firebase/firebase_auth_service.dart';
// import '../../data/services/firebase/firestore_service.dart';
//
// class InitialBinding extends Bindings {
//   @override
//   void dependencies() {
//
//     // ─── CORE SERVICES ──────────────────────────────
//     // fenix:true means recreate if disposed
//     Get.lazyPut<HiveService>(
//           () => HiveService(),
//       fenix: true,
//     );
//     Get.lazyPut<FirebaseAuthService>(
//           () => FirebaseAuthService(),
//       fenix: true,
//     );
//     Get.lazyPut<FirestoreService>(
//           () => FirestoreService(),
//       fenix: true,
//     );
//
//     // ─── GLOBAL CONTROLLERS ─────────────────────────
//     // permanent:true means never disposed
//     Get.put<ThemeController>(
//       ThemeController(),
//       permanent: true,
//     );
//     Get.put<SettingsController>(
//       SettingsController(),
//       permanent: true,
//     );
//   }
// }