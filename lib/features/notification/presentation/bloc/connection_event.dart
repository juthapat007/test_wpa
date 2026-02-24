part of 'connection_bloc.dart';

@immutable
sealed class ConnectionEvent {}

class LoadConnectionRequests extends ConnectionEvent {}

class AcceptConnectionRequest extends ConnectionEvent {
  final int id;
  AcceptConnectionRequest(this.id);
}

class RejectConnectionRequest extends ConnectionEvent {
  final int id;
  RejectConnectionRequest(this.id);
}

class WsFriendRequestReceived extends ConnectionEvent {
  final WsEvent event;
  WsFriendRequestReceived(this.event);
}
