import 'package:app_links/app_links.dart';

class DeepLinkService {
  final _appLinks = AppLinks();

  void init() {
    // รับ link ตอนเปิด app จาก terminated state
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleLink(uri);
      }
    });

    // รับ link ตอน app รันอยู่
    _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    print(' Deep link received: $uri');
    print(' Path: ${uri.path}');
    print(' Query params: ${uri.queryParameters}');

    // จัดการ reset-password
    if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'];
      
      if (token != null && token.isNotEmpty) {
        print('✅ Reset token found: $token');
        
        // TODO: นำทางไปหน้า reset password
        // ถ้าใช้ flutter_modular:
        // Modular.to.pushNamed('/reset-password', arguments: {'token': token});
        
        // ถ้าใช้ Navigator ธรรมดา:
        // navigatorKey.currentState?.pushNamed('/reset-password', arguments: {'token': token});
        
        // ถ้าใช้ GoRouter:
        // context.go('/reset-password?token=$token');
        
      } else {
        print('❌ Token not found in deep link');
      }
    }
  }
}