import 'package:flutter/material.dart';
import 'package:test_wpa/app/app_module.dart';
import 'package:test_wpa/app/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/network/dio_client.dart';
import 'package:test_wpa/services/deep_link_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test_wpa/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final deepLinkService = DeepLinkService();
  deepLinkService.init();

  await DioClient().init();

  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
