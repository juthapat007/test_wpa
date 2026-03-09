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
  print('Host: ${uri.host}');
  print('Path: ${uri.path}');
  print('Query params: ${uri.queryParameters}');

  final isHttpsResetLink = uri.scheme == 'https' && uri.path == '/deeplink-reset-password';
  final isCustomSchemeResetLink = uri.scheme == 'wpa' && uri.host == 'reset-password';

  if (isHttpsResetLink || isCustomSchemeResetLink) {
    final token = uri.queryParameters['token'];

    if (token != null && token.isNotEmpty) {
      print('Reset token found: $token');
      Modular.to.navigate('/reset-password?token=$token');
    } else {
      print('Token not found in deep link');
    }
  }
}
}