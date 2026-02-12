import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Modular.to.popAndPushNamed('/');
        }
      }, //ฟังก์ชันที่ใช้เพื่อตรวจสอบสถานะการล็อกอิน และควบคุม navigation
      child: const RouterOutlet(),
    );
  }
}
