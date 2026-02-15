import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';
import 'package:test_wpa/features/notification/domain/repositories/connection_repository.dart';

part 'connection_event.dart';
part 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionRequestState> {
  final ConnectionRepository connectionRepository;

  ConnectionBloc({required this.connectionRepository})
    : super(ConnectionRequestInitial()) {
    on<LoadConnectionRequests>(_onLoadRequests);
    on<AcceptConnectionRequest>(_onAcceptRequest);
    on<RejectConnectionRequest>(_onRejectRequest);
  }

  Future<void> _onLoadRequests(
    LoadConnectionRequests event,
    Emitter<ConnectionRequestState> emit,
  ) async {
    emit(ConnectionRequestLoading());
    try {
      final requests = await connectionRepository.getReceivedRequests();
      emit(ConnectionRequestLoaded(requests: requests));
    } catch (e) {
      emit(ConnectionRequestError('Failed to load connection requests: $e'));
    }
  }

  Future<void> _onAcceptRequest(
    AcceptConnectionRequest event,
    Emitter<ConnectionRequestState> emit,
  ) async {
    try {
      await connectionRepository.acceptRequest(event.id);

      // Reload requests after accepting
      final requests = await connectionRepository.getReceivedRequests();
      emit(ConnectionRequestLoaded(requests: requests));

      // Show success message briefly
      emit(ConnectionRequestActionSuccess('Connection accepted'));
      emit(ConnectionRequestLoaded(requests: requests));
    } catch (e) {
      emit(ConnectionRequestError('Failed to accept request: $e'));
    }
  }

  Future<void> _onRejectRequest(
    RejectConnectionRequest event,
    Emitter<ConnectionRequestState> emit,
  ) async {
    try {
      await connectionRepository.rejectRequest(event.id);

      // Reload requests after rejecting
      final requests = await connectionRepository.getReceivedRequests();
      emit(ConnectionRequestLoaded(requests: requests));

      // Show success message briefly
      emit(ConnectionRequestActionSuccess('Connection rejected'));
      emit(ConnectionRequestLoaded(requests: requests));
    } catch (e) {
      emit(ConnectionRequestError('Failed to reject request: $e'));
    }
  }
}
