import 'package:flutter/material.dart';
import 'package:test_wpa/app/app_module.dart';
import 'package:test_wpa/app/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DioClient().init();

  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
