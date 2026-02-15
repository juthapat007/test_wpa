import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/auth/presentation/bloc/auth_bloc.dart';

void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // ✅ ปิด dialog ก่อน
            Navigator.pop(context);

            try {
              // ✅ ส่ง logout event
              final authBloc = Modular.get<AuthBloc>();
              authBloc.add(AuthLogout());

              // ✅ รอสักครู่ให้ logout เสร็จ
              await Future.delayed(const Duration(milliseconds: 300));

              // ✅ Navigate ไปหน้า login และ clear stack
              Modular.to.navigate('/');
            } catch (e) {
              print('❌ Logout error: $e');
              // ถ้า error ให้ navigate อยู่ดี
              Modular.to.navigate('/');
            }
          },
          child: const Text('Log Out', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
