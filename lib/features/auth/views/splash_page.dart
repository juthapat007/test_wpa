import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/core/services/notification_service.dart';
import 'package:dio/dio.dart';

// ต้องเพิ่ม Splash Screen ที่คอยเช็ค token ก่อน แล้วค่อย redirect(เปล่ี่ยนเส้นทาง)
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  // Future<void> _checkToken() async {
  //   final storage = Modular.get<FlutterSecureStorage>();
  //   final token = await storage.read(key: 'auth_token');

  //   if (token != null) {
  //     Modular.get<ChatBloc>()
  //       ..add(ConnectWebSocket())
  //       ..add(LoadChatRooms());
  //     Modular.get<NotificationBloc>().add(LoadUnreadCount());

  //     final pending = NotificationService.pendingPayload;
  //     if (pending != null) {
  //       await Future.delayed(const Duration(milliseconds: 300));
  //       NotificationService.handlePendingPayload(pending);
  //       return; // ไม่ต้อง navigate('/meeting')
  //     }

  //     Modular.to.navigate('/meeting');
  //   } else {
  //     Modular.to.navigate('/login');
  //   }
  // }

  Future<void> _checkToken() async {
    final storage = Modular.get<FlutterSecureStorage>();
    final token = await storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      Modular.to.navigate('/login');
      return;
    }

    try {
      final dio = Modular.get<Dio>();
      await dio.get('/delegates/me');

      Modular.get<ChatBloc>()
        ..add(ConnectWebSocket())
        ..add(LoadChatRooms());
      Modular.get<NotificationBloc>().add(LoadUnreadCount());

      final pending = NotificationService.pendingPayload;
      if (pending != null) {
        await Future.delayed(const Duration(milliseconds: 300));
        NotificationService.handlePendingPayload(pending);
        return;
      }

      Modular.to.navigate('/meeting');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
