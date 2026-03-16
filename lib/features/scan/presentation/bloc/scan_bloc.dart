import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/features/scan/domain/repositories/qr_repository.dart';

part 'scan_event.dart';
part 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final QrRepository qrRepository;

  ScanBloc({required this.qrRepository}) : super(ScanInitial()) {
    on<LoadQrCode>(_onLoadQrCode);
  }

  /// Handler สำหรับโหลด QR Code
  Future<void> _onLoadQrCode(LoadQrCode event, Emitter<ScanState> emit) async {
    emit(ScanLoading());

    try {
      final qrCode = await qrRepository.getQrCode(event.delegateId);
      emit(ScanLoaded(qrCode));
    } catch (e) {
      emit(ScanError('Unable to load QR Code: ${e.toString()}'));
    }
  }
}
