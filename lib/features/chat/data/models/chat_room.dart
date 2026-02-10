import 'package:test_wpa/features/chat/data/models/chat_message.dart';

class ChatRoom {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime? lastActiveAt;

  ChatRoom({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastActiveAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id']?.toString() ?? '',
      participantId:
          json['participant_id']?.toString() ??
          json['participantId']?.toString() ??
          '',
      participantName:
          json['participant_name'] ?? json['participantName'] ?? 'Unknown',
      participantAvatar:
          json['participant_avatar'] ?? json['participantAvatar'],
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'])
          : json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'participant_id': participantId,
    'participant_name': participantName,
    'participant_avatar': participantAvatar,
    'last_message': lastMessage?.toJson(),
    'unread_count': unreadCount,
    'last_active_at': lastActiveAt?.toIso8601String(),
  };

  ChatRoom copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantAvatar,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? lastActiveAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
