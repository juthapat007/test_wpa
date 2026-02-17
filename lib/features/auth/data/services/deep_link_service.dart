// lib/core/services/deep_link_service.dart

import 'package:app_links/app_links.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  /// เริ่มฟัง Deep Link
  /// เรียกใน main.dart หรือ app widget
  Future<void> init() async {
    // ✅ กรณี app ปิดอยู่ แล้ว user กด link → app เปิดขึ้นมา
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }

    // ✅ กรณี app เปิดอยู่แล้ว แล้ว user กด link
    _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    print('🔗 Deep link received: $uri');

    // https://wpa-docker.onrender.com/reset-password?token=xxx
    if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        print('🔑 Reset token: $token');

        // นำทางไปหน้า reset password พร้อม token
        Modular.to.pushNamed('/reset_password', arguments: {'token': token});
      } else {
        print('❌ Token not found in deep link');
      }
    }
  }
}
