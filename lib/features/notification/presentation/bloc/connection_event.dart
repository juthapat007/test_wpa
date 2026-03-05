part of 'connection_bloc.dart';

@immutable
sealed class ConnectionEvent {}

class LoadConnectionRequests extends ConnectionEvent {}

// class AcceptConnectionRequest extends ConnectionEvent {
//   final int id;
//   AcceptConnectionRequest(this.id);
// }

class RejectConnectionRequest extends ConnectionEvent {
  final int id;
  RejectConnectionRequest(this.id);
}

class WsFriendRequestReceived extends ConnectionEvent {
  final WsEvent event;
  WsFriendRequestReceived(this.event);
}

class SendConnectionRequest extends ConnectionEvent {
  final int delegateId;
  SendConnectionRequest(this.delegateId);
}

class AcceptConnectionRequest extends ConnectionEvent {
  final int requestId;
  AcceptConnectionRequest(this.requestId);
}

class CancelConnectionRequest extends ConnectionEvent {
  final int delegateId;
  CancelConnectionRequest(this.delegateId);
}
