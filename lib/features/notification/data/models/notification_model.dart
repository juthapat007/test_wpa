import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';

class NotificationItemModel {
  final int id;
  final String type;
  final String? readAt;
  final String createdAt;
  final bool isUnread;
  final NotificationNotifiableModel? notifiable;

  NotificationItemModel({
    required this.id,
    required this.type,
    this.readAt,
    required this.createdAt,
    required this.isUnread,
    this.notifiable,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'],
      type: json['type'] ?? '',
      readAt: json['read_at'],
      createdAt: json['created_at'] ?? '',
      // isUnread: json['unread?'] ?? true,
      isUnread: json['is_unread?'] ?? false,
      notifiable: json['notifiable'] != null
          ? NotificationNotifiableModel.fromJson(json['notifiable'])
          : null,
    );
  }

  NotificationItem toEntity() {
    return NotificationItem(
      id: id,
      type: type,
      readAt: readAt != null ? DateTime.tryParse(readAt!) : null,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      isUnread: isUnread,
      notifiable: notifiable?.toEntity(),
    );
  }
}

class NotificationNotifiableModel {
  final String type;
  final int id;
  final NotificationSenderModel? sender;
  final String? content;

  NotificationNotifiableModel({
    required this.type,
    required this.id,
    this.sender,
    this.content,
  });

  factory NotificationNotifiableModel.fromJson(Map<String, dynamic> json) {
    return NotificationNotifiableModel(
      type: json['type'] ?? '',
      id: json['id'] ?? 0,
      sender: json['sender'] != null
          ? NotificationSenderModel.fromJson(json['sender'])
          : null,
      content: json['content'],
    );
  }

  NotificationNotifiable toEntity() {
    return NotificationNotifiable(type: type, id: id, content: content);
  }
}

class NotificationSenderModel {
  final int id;
  final String name;
  final String? avatarUrl;

  NotificationSenderModel({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory NotificationSenderModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['avatar_url'] as String?;
    return NotificationSenderModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      // avatarUrl: json['avatar_url'],
      avatarUrl: _resolveUrl(rawUrl),
    );
  }
  static String? _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url; // ถ้าเป็น full URL แล้ว
    return 'https://wpa-docker.onrender.com$url'; // เติม base URL
  }

  NotificationSender toEntity() {
    return NotificationSender(id: id, name: name, avatarUrl: avatarUrl);
  }
}
