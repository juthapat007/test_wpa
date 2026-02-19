import 'package:test_wpa/features/auth/data/models/user.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final User? user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'] ?? json['token'];

    if (token == null || token.isEmpty) {
      throw Exception('Access token is missing');
    }

    return LoginResponse(
      accessToken: token,
      refreshToken: json['refreshToken'] ?? '',
      // 👇 ตรงนี้สำคัญ
      user: json['user'] != null
          ? User.fromJson(json['user'])
          : json['delegate'] != null
          ? User.fromJson(json['delegate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': user?.toJson(),
  };
}

// // lib/features/auth/data/models/login_response.dart

// import 'package:test_wpa/features/auth/data/models/user.dart';

// class LoginResponse {
//   final String accessToken;
//   final String refreshToken;
//   final User? user;

//   LoginResponse({
//     required this.accessToken,
//     required this.refreshToken,
//     required this.user,
//   });

//   factory LoginResponse.fromJson(Map<String, dynamic> json) {
//     // API structure: { "success": true, "data": { "token": "...", "delegate": {...} } }
//     final data = json['data'] as Map<String, dynamic>?;

//     final token = data?['token'] ?? data?['accessToken'];

//     if (token == null || (token as String).isEmpty) {
//       throw Exception('Access token is missing');
//     }

//     final userJson = data?['delegate'] ?? data?['user'];

//     return LoginResponse(
//       accessToken: token,
//       refreshToken: data?['refreshToken'] ?? '',
//       user: userJson != null ? User.fromJson(userJson) : null,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'accessToken': accessToken,
//     'refreshToken': refreshToken,
//     'user': user?.toJson(),
//   };
// }
