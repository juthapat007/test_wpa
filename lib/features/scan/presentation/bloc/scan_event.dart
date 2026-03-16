part of 'scan_bloc.dart';

@immutable
sealed class ScanEvent {}

/// Event สำหรับโหลด QR Code
final class LoadQrCode extends ScanEvent {
  final String delegateId;

  LoadQrCode(this.delegateId);
}

