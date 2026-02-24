// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:test_wpa/app/app_module.dart';
// import 'package:test_wpa/app/app_widget.dart';
// import 'package:flutter_modular/flutter_modular.dart';
// import 'package:test_wpa/core/network/dio_client.dart';
// import 'package:test_wpa/core/services/notification_service.dart';
// import 'package:test_wpa/features/auth/domain/repositories/auth_repository.dart';
// import 'package:test_wpa/services/deep_link_service.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:test_wpa/firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   await NotificationService.init();

//   final deepLinkService = DeepLinkService();
//   deepLinkService.init();

//   await DioClient().init();
//   //เพิ่มตรงนี้ — ฟัง token refresh อัตโนมัติ

//   FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
//     final storage = Modular.get<FlutterSecureStorage>();
//     final jwt = await storage.read(key: 'auth_token');
//     if (jwt != null) {
//       // ยัง login อยู่ → ส่ง token ใหม่
//       await Modular.get<AuthRepository>().registerDeviceToken(newToken);
//     }
//   });

//   runApp(ModularApp(module: AppModule(), child: const AppWidget()));
// }

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   print('Background message: ${message.notification?.title}');
//   // แค่นี้พอ firebase จัดการแสดง notification ให้เองตอน background
// }

//===========================================================================================
import 'package:flutter/material.dart';
import 'package:test_wpa/app/app_module.dart';
import 'package:test_wpa/app/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔇 ปิดทั้งหมดสำหรับ Web testing:
  // - Firebase.initializeApp
  // - FirebaseMessaging.onBackgroundMessage
  // - NotificationService.init
  // - DeepLinkService
  // - FirebaseMessaging.instance.onTokenRefresh

  await DioClient().init();

  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
