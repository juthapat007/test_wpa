// lib/core/widgets/app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/chat/data/services/chat_websocket_service.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/connection_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final NotificationBloc _notificationBloc;
  late final ConnectionBloc _connectionBloc;
  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();

    _notificationBloc = Modular.get<NotificationBloc>()..add(LoadUnreadCount());

    _connectionBloc = Modular.get<ConnectionBloc>()
      ..add(LoadConnectionRequests());

    _chatBloc = Modular.get<ChatBloc>();

    // ✅ Connect WebSocket ทันทีหลัง login ถ้ายังไม่ได้ connect
    // (ไม่ใช่แค่ตอนเปิดหน้า Chat)
    // WS จำเป็นต้องเปิดตั้งแต่ต้นเพราะ NotificationChannel อยู่ใน connection เดียวกัน
    final wsService = Modular.get<ChatWebSocketService>();
    if (!wsService.isConnected) {
      _chatBloc.add(ConnectWebSocket());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _notificationBloc),
        BlocProvider.value(value: _connectionBloc),
        BlocProvider.value(value: _chatBloc),
      ],
      child: widget.child,
    );
  }
}
