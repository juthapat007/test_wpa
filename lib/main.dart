import 'package:flutter/material.dart';
import 'package:test_wpa/app/app_module.dart';
import 'package:test_wpa/app/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
