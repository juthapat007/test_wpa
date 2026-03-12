import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:meta/meta.dart';
import 'package:test_wpa/core/services/notification_websocket_service.dart';
import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';
import 'package:test_wpa/features/notification/domain/repositories/connection_repository.dart';
import 'package:test_wpa/core/constants/print_logger.dart';
import 'package:test_wpa/features/notification/presentation/bloc/friends_cubit.dart';

part 'connection_event.dart';
part 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionRequestState> {
  final ConnectionRepository connectionRepository;
  StreamSubscription<WsEvent>? _wsSubscription;

  ConnectionBloc({required this.connectionRepository})
    : super(ConnectionRequestInitial()) {
    on<LoadConnectionRequests>(_onLoadRequests);
    on<AcceptConnectionRequest>(_onAcceptRequest);
    on<RejectConnectionRequest>(_onRejectRequest);
    on<WsFriendRequestReceived>(_onWsFriendRequest);
    on<SendConnectionRequest>(_onSendConnectionRequest);

    _listenToWebSocket();
  }
  Future<void> _onSendConnectionRequest(
    SendConnectionRequest event,
    Emitter<ConnectionRequestState> emit,
  ) async {
    try {
      await connectionRepository.sendRequest(event.delegateId);
      // reload friends เพื่ออัพเดต badge
      Modular.get<FriendsCubit>().loadFriends();
    } catch (e) {
      print('⚠️ sendRequest failed: $e');
    }
  }

  // ─── WebSocket listener ────────────────────────────────────────────────────

  void _listenToWebSocket() {
    _wsSubscription = NotificationWebSocketService.instance.events.listen((
      event,
    ) {
      log.i('[ConnectionBloc] WS event=${event.type}'); // เช็คบรรทัดนี้
      if (event.type == WsEventType.friendRequest) {
        add(WsFriendRequestReceived(event));
      }
    });
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _onWsFriendRequest(
    WsFriendRequestReceived event,
    Emitter<ConnectionRequestState> emit,
  ) async {
    // reload requests เพื่อให้ list และ badge dot อัปเดต
    try {
      final requests = await connectionRepository.getReceivedRequests();
      emit(ConnectionRequestLoaded(requests: requests));
    } catch (_) {
      // silently fail
    }
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
      await connectionRepository.acceptRequest(event.requestId);
      final requests = await connectionRepository.getReceivedRequests();
      emit(ConnectionRequestLoaded(requests: requests));
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
      final requests = await connectionRepository.getReceivedRequests();
      emit(ConnectionRequestLoaded(requests: requests));
      emit(ConnectionRequestActionSuccess('Connection rejected'));
      emit(ConnectionRequestLoaded(requests: requests));
    } catch (e) {
      emit(ConnectionRequestError('Failed to reject request: $e'));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
