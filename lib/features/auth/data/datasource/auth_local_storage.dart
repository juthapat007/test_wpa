import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthLocalStorage {
  final FlutterSecureStorage storage;
  AuthLocalStorage(this.storage);

  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    await storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: _tokenKey);
  }

  Future<void> clearTokens() async {
    await storage.delete(key: _tokenKey);
  }
}
