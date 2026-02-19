import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';

abstract class ConnectionRepository {
  Future<List<ConnectionRequest>> getReceivedRequests();
  Future<void> acceptRequest(int id);
  Future<void> rejectRequest(int id);
  Future<void> sendRequest(int delegateId);
  Future<void> unfriend(int delegateId);
}
