// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static final _localNotifications = FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     // ตั้งค่า Android
//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );

//     // ตั้งค่า iOS
//     const iosSettings = DarwinInitializationSettings();

//     await _localNotifications.initialize(
//       const InitializationSettings(android: androidSettings, iOS: iosSettings),
//     );

//     // ✅ ฟัง notification ตอน Foreground
//     FirebaseMessaging.onMessage.listen((message) {
//       if (message.notification != null) {
//         showNotification(message);
//       }
//     });
//   }

//   static Future<void> showNotification(RemoteMessage message) async {
//     const androidDetail = AndroidNotificationDetails(
//       'default_channel',
//       'Default',
//       importance: Importance.high,
//       priority: Priority.high,
//     );

//     await _localNotifications.show(
//       message.hashCode,
//       message.notification?.title,
//       message.notification?.body,
//       const NotificationDetails(android: androidDetail),
//     );
//   }
// }
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        showNotification(message);
      }
    });
  }

  static Future<void> showNotification(RemoteMessage message) async {
    const androidDetail = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: const NotificationDetails(android: androidDetail),
    );
  }
}
