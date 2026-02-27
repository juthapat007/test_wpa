import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';

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

  Future<void> _checkToken() async {
    final storage = Modular.get<FlutterSecureStorage>();
    final token = await storage.read(key: 'auth_token');

    if (token != null) {
      //===================================================================
      Modular.get<ChatBloc>()
        ..add(ConnectWebSocket())
        ..add(LoadChatRooms());
      Modular.get<NotificationBloc>().add(LoadUnreadCount());
      //===================================================================
      Modular.to.navigate('/meeting'); // มี token → เข้าแอปเลย
    } else {
      Modular.to.navigate('/login'); // ไม่มี token ==> ไป login
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
