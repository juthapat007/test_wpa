import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static String? _pendingPayload;

  static String? get pendingPayload {
    final p = _pendingPayload;
    _pendingPayload = null;
    return p;
  }

  static Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!kIsWeb) {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: (details) {
          _navigateFromPayload(details.payload);
        },
      );

      // Foreground: รับ FCM ==> แสดง local notification
      FirebaseMessaging.onMessage.listen((message) {
        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });
    }

    // Background: กด notification ==> app เปิดขึ้นมา
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _navigateFromFcm(message),
      );
    });

    // Terminated: app ถูกเปิดจาก notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _pendingPayload = _buildPayload(
        initial,
        senderName: initial.notification?.title ?? '',
      );
      print('Terminated payload saved: $_pendingPayload');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    const androidDetail = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    final senderName = message.notification?.title ?? '';
    final payload = _buildPayload(message, senderName: senderName);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(android: androidDetail),
      payload: payload,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _buildPayload(RemoteMessage message, {String senderName = ''}) {
    final data = message.data;
    final type = data['type'] as String?;
    final senderId = data['sender_id'] as String?;

    final name = senderName.isNotEmpty
        ? senderName
        : (message.notification?.title ?? '');

    print('FCM data: $data');
    print('FCM type=$type sender_id=$senderId name=$name');

    if ((type == 'new_message' || type == 'new_group_message') &&
        senderId != null &&
        senderId.isNotEmpty &&
        senderId != 'null') {
      return 'chat:$senderId:$name';
    }
    return 'notification';
  }

  static void _navigateFromFcm(RemoteMessage message) {
    final senderName = message.notification?.title ?? '';
    final payload = _buildPayload(message, senderName: senderName);
    print('navigate from FCM payload: $payload');
    _navigateFromPayload(payload);
  }

  static void _navigateFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      if (payload.startsWith('chat:')) {
        final parts = payload.substring(5).split(':');
        final senderId = parts.isNotEmpty ? parts[0] : '';
        final senderName = parts.length > 1 ? parts[1] : '';
        if (senderId.isNotEmpty) _openChat(senderId, senderName: senderName);
      } else {
        Modular.to.navigate('/notification');
      }
    } catch (e) {
      print('Router not ready, saving payload: $payload');
      _pendingPayload = payload;
    }
  }

  /// เรียกจาก SplashPage หลัง router พร้อมแล้ว
  static void handlePendingPayload(String payload) {
    _navigateFromPayload(payload);
  }

  static void _openChat(String senderId, {String senderName = ''}) {
    Modular.to.navigate('/chat');
    Future.delayed(const Duration(milliseconds: 400), () {
      Modular.get<ChatBloc>().add(CreateChatRoom(senderId, senderName));
      Modular.to.pushNamed('/chat/room');
    });
  }
}
