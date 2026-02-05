import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_theme.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      //การให้wrap bloc แก่ widget AuthBloc เป็น Bloc ที่จัดการเรื่อง Authentication
      create: (_) =>
          Modular.get<
            AuthBloc
          >(), // instance ของ AuthBloc ที่ถูกลงทะเบียนไว้แล้วมาใช้งาน
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: Modular.routerConfig,
      ),
    );
  }
}
//เป็นหน้าหลักของแอป