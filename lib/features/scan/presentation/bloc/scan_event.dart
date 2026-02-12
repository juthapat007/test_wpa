part of 'scan_bloc.dart';

@immutable
sealed class ScanEvent {}

/// Event สำหรับโหลด QR Code
final class LoadQrCode extends ScanEvent {
  final String delegateId;

  LoadQrCode(this.delegateId);
}

/// Event สำหรับ refresh QR Code
final class RefreshQrCode extends ScanEvent {
  final String delegateId;

  RefreshQrCode(this.delegateId);
}
