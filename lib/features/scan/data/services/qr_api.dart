// lib/features/scan/data/services/qr_api.dart

import 'package:dio/dio.dart';

class QrApi {
  final Dio _dio;

  QrApi(this._dio);

  /// ดึง QR Code ของ delegate
  Future<String> getQrCode(String delegateId) async {
    try {
      final response = await _dio.get('/delegates/$delegateId/qr_code');

      if (response.statusCode == 200) {
        final data = response.data;
        return data['qr_code'] ?? '';
      } else {
        throw Exception('Failed to fetch QR code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
