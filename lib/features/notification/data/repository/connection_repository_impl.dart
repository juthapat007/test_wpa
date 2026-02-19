// lib/features/notification/data/repositories/connection_repository_impl.dart

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
      throw Exception('Failed to load received requests: $e');
    }
  }

  @override
  Future<List<Friend>> getFriends() async {
    try {
      final data = await api.getFriends();
      return data
          .map((json) => Friend.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load friends: $e');
    }
  }

  @override
  Future<void> sendRequest(int delegateId) async {
    try {
      await api.sendConnectionRequest(delegateId);
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  @override
  Future<void> acceptRequest(int requestId) async {
    try {
      await api.acceptRequest(requestId);
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  @override
  Future<void> rejectRequest(int requestId) async {
    try {
      await api.rejectRequest(requestId);
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  @override
  Future<void> cancelRequest(int targetId) async {
    try {
      await api.cancelRequest(targetId);
    } catch (e) {
      throw Exception('Failed to cancel request: $e');
    }
  }

  @override
  Future<void> unfriend(int delegateId) async {
    try {
      await api.unfriend(delegateId);
    } catch (e) {
      throw Exception('Failed to unfriend: $e');
    }
  }
}
