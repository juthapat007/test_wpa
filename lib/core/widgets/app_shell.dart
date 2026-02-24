// lib/core/widgets/app_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/connection_bloc.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _wsInitialized = false;

  @override
  void initState() {
    super.initState();
    // ✅ Connect WebSocket และ load initial data หลังจาก frame แรก render เสร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRealtime();
    });
  }

  Future<void> _initializeRealtime() async {
    if (_wsInitialized) return;
    _wsInitialized = true;

    final chatBloc = Modular.get<ChatBloc>();
    final notifBloc = Modular.get<NotificationBloc>();

    // ✅ 1. Connect WebSocket ทันที (ไม่ต้องรอให้ navigate ไป /chat)
    chatBloc.add(ConnectWebSocket());

    // ✅ 2. Load notification unread count ทันที เพื่อให้ badge แสดงตัวเลข
    notifBloc.add(LoadUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Provide singleton BLoC instances ทั้งหมดให้ทุก child route
    // ใช้ BlocProvider.value เพื่อไม่ให้ dispose bloc เมื่อ route เปลี่ยน
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: Modular.get<AuthBloc>()),
        BlocProvider.value(value: Modular.get<ChatBloc>()),
        BlocProvider.value(value: Modular.get<NotificationBloc>()),
        BlocProvider.value(value: Modular.get<ConnectionBloc>()),
      ],
      child: widget.child,
    );
  }
}
