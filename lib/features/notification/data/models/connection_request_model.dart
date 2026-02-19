
import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';

class ConnectionRequestModel {
  final int id;
  final int requesterId; 
  final String createdAt;
  final ConnectionRequestDelegateModel? requester;

  ConnectionRequestModel({
    required this.id,
    required this.requesterId,
    required this.createdAt,
    this.requester,
  });

  factory ConnectionRequestModel.fromJson(Map<String, dynamic> json) {
    final requesterJson = json['requester'] as Map<String, dynamic>?;
    return ConnectionRequestModel(
      id: json['id'],
      requesterId: requesterJson?['id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      requester: requesterJson != null
          ? ConnectionRequestDelegateModel.fromJson(requesterJson)
          : null,
    );
  }

  ConnectionRequest toEntity() {
    return ConnectionRequest(
      id: id,
      senderId: requesterId,       // map requester → sender
      receiverId: 0,               // ไม่มีใน response, ใส่ 0 ไปก่อน
      status: 'pending',           // ทุก record ใน my_received = pending เสมอ
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      sender: requester?.toEntity(),
    );
  }
}

class ConnectionRequestDelegateModel {
  final int id;
  final String name;
  final String? title;
  final String? avatarUrl;
  // ✅ my_received ไม่ส่ง email, company_name มา ใส่ optional
  final String? email;
  final String? companyName;

  ConnectionRequestDelegateModel({
    required this.id,
    required this.name,
    this.title,
    this.avatarUrl,
    this.email,
    this.companyName,
  });

  factory ConnectionRequestDelegateModel.fromJson(Map<String, dynamic> json) {
    return ConnectionRequestDelegateModel(
      id: json['id'],
      name: json['name'] ?? '',
      title: json['title'],
      avatarUrl: json['avatar_url'],
      email: json['email'],
      companyName: json['company_name'],
    );
  }

  ConnectionRequestDelegate toEntity() {
    return ConnectionRequestDelegate(
      id: id,
      name: name,
      email: email ?? '',
      avatarUrl: avatarUrl,
      title: title,
      companyName: companyName,
    );
  }
}