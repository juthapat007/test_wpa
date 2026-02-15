import 'package:test_wpa/features/notification/data/models/connection_request_model.dart';
import 'package:test_wpa/features/notification/data/services/connection_api.dart';
import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';
import 'package:test_wpa/features/notification/domain/repositories/connection_repository.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  final ConnectionApi api;

  ConnectionRepositoryImpl({required this.api});

  @override
  Future<List<ConnectionRequest>> getReceivedRequests() async {
    try {
      final data = await api.getReceivedRequests();
      return data
          .map(
            (json) => ConnectionRequestModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load connection requests: $e');
    }
  }

  @override
  Future<void> acceptRequest(int id) async {
    try {
      await api.acceptRequest(id);
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  @override
  Future<void> rejectRequest(int id) async {
    try {
      await api.rejectRequest(id);
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }
}
