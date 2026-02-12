// lib/features/scan/presentation/bloc/scan_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/features/scan/domain/repositories/qr_repository.dart';

part 'scan_event.dart';
part 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final QrRepository qrRepository;

  ScanBloc({required this.qrRepository}) : super(ScanInitial()) {
    on<LoadQrCode>(_onLoadQrCode);
    on<RefreshQrCode>(_onRefreshQrCode);
  }

  /// Handler สำหรับโหลด QR Code
  Future<void> _onLoadQrCode(LoadQrCode event, Emitter<ScanState> emit) async {
    emit(ScanLoading());

    try {
      final qrCode = await qrRepository.getQrCode(event.delegateId);
      emit(ScanLoaded(qrCode));
    } catch (e) {
      emit(ScanError('ไม่สามารถโหลด QR Code ได้: ${e.toString()}'));
    }
  }

  /// Handler สำหรับ refresh QR Code
  Future<void> _onRefreshQrCode(
    RefreshQrCode event,
    Emitter<ScanState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;

    try {
      final qrCode = await qrRepository.getQrCode(event.delegateId);
      emit(ScanLoaded(qrCode));
    } catch (e) {
      // If refresh fails, keep showing old data with error message
      if (currentState is ScanLoaded) {
        emit(currentState);
      } else {
        emit(ScanError('ไม่สามารถ refresh QR Code ได้'));
      }
    }
  }
}
