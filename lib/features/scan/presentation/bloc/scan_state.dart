// lib/features/scan/presentation/bloc/scan_state.dart

part of 'scan_bloc.dart';

@immutable
sealed class ScanState {}

/// State เริ่มต้น
final class ScanInitial extends ScanState {}

/// State กำลังโหลด
final class ScanLoading extends ScanState {}

/// State โหลดสำเร็จ
final class ScanLoaded extends ScanState {
  final String qrCodeBase64;

  ScanLoaded(this.qrCodeBase64);
}

/// State เกิดข้อผิดพลาด
final class ScanError extends ScanState {
  final String message;

  ScanError(this.message);
}
