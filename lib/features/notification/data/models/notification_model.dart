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
  final NotificationSenderModel? sender; // requester (คนส่ง request)
  final NotificationSenderModel? target; // target (คนรับ)
  final String? content;
  final String? status;

  NotificationNotifiableModel({
    required this.type,
    required this.id,
    this.sender,
    this.target,
    this.content,
    this.status,
  });

  factory NotificationNotifiableModel.fromJson(Map<String, dynamic> json) {
    return NotificationNotifiableModel(
      type: json['type'] ?? '',
      id: json['id'] ?? 0,
      // ✅ รองรับทั้ง 'sender', 'requester' field จาก backend
      sender: json['sender'] != null
          ? NotificationSenderModel.fromJson(json['sender'])
          : json['requester'] != null
          ? NotificationSenderModel.fromJson(json['requester'])
          : null,
      target: json['target'] != null
          ? NotificationSenderModel.fromJson(json['target'])
          : null,
      content: json['content'],
      status: json['status'],
    );
  }

  NotificationNotifiable toEntity() {
    return NotificationNotifiable(
      type: type,
      id: id,
      content: content,
      status: status,
      // ✅ ส่ง sender/requester/target ออกไปด้วย — ไม่ทิ้งข้อมูลแล้ว
      requester: sender?.toEntity(),
      target: target?.toEntity(),
    );
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
    return NotificationSenderModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      avatarUrl: _resolveUrl(json['avatar_url'] as String?),
    );
  }

  static String? _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return 'https://wpa-docker.onrender.com$url';
  }

  NotificationSender toEntity() {
    return NotificationSender(id: id, name: name, avatarUrl: avatarUrl);
  }
}
