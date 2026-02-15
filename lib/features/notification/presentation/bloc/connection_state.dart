part of 'connection_bloc.dart';

@immutable
sealed class ConnectionRequestState {}

final class ConnectionRequestInitial extends ConnectionRequestState {}

final class ConnectionRequestLoading extends ConnectionRequestState {}

final class ConnectionRequestLoaded extends ConnectionRequestState {
  final List<ConnectionRequest> requests;

  ConnectionRequestLoaded({required this.requests});
}

final class ConnectionRequestError extends ConnectionRequestState {
  final String message;
  ConnectionRequestError(this.message);
}

final class ConnectionRequestActionSuccess extends ConnectionRequestState {
  final String message;
  ConnectionRequestActionSuccess(this.message);
}