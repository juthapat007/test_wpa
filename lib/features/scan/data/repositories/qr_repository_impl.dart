// lib/features/scan/data/repository/qr_repository_impl.dart

import 'package:test_wpa/features/scan/data/services/qr_api.dart';
import 'package:test_wpa/features/scan/domain/repositories/qr_repository.dart';

class QrRepositoryImpl implements QrRepository {
  final QrApi api;

  QrRepositoryImpl({required this.api});

  @override
  Future<String> getQrCode(String delegateId) async {
    try {
      return await api.getQrCode(delegateId);
    } catch (e) {
      rethrow;
    }
  }
}