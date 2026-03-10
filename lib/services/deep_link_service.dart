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
  final pathSegments = uri.pathSegments;
  if (pathSegments.length >= 2 && pathSegments[0] == 'other_profile') {
    final delegateId = int.tryParse(pathSegments[1]);
    if (delegateId != null) {
      print('Navigate to other_profile: $delegateId');
      Modular.to.navigate('/other_profile', arguments: {'delegate_id': delegateId});
    }
  }
}
}