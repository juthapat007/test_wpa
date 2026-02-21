import 'package:app_links/app_links.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DeepLinkService {
  final _appLinks = AppLinks();

  void init() {
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleLink(uri);
      }
    });

    _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    print('Deep link received: $uri');
    print('Path: ${uri.path}');
    print('Query params: ${uri.queryParameters}');

    if (uri.path == '/deeplink-reset-password') {
      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        print('Reset token found: $token');
        Modular.to.navigate('/reset_password', arguments: token);
      } else {
        print('Token not found in deep link');
      }
    }
  }
}