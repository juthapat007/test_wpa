import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';

class ConnectionRequestModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String status;
  final String createdAt;
  final ConnectionRequestDelegateModel? sender;

  ConnectionRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.sender,
  });

  factory ConnectionRequestModel.fromJson(Map<String, dynamic> json) {
    return ConnectionRequestModel(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      sender: json['sender'] != null
          ? ConnectionRequestDelegateModel.fromJson(json['sender'])
          : null,
    );
  }

  ConnectionRequest toEntity() {
    return ConnectionRequest(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      status: status,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      sender: sender?.toEntity(),
    );
  }
}

class ConnectionRequestDelegateModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? title;
  final String? companyName;

  ConnectionRequestDelegateModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.title,
    this.companyName,
  });

  factory ConnectionRequestDelegateModel.fromJson(Map<String, dynamic> json) {
    return ConnectionRequestDelegateModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      title: json['title'],
      companyName: json['company_name'],
    );
  }

  ConnectionRequestDelegate toEntity() {
    return ConnectionRequestDelegate(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      title: title,
      companyName: companyName,
    );
  }
}
