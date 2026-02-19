class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String receiverId;
  final int chatRoomId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final MessageType type;
  final DateTime? editedAt;
  final bool isDeleted;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.chatRoomId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.type = MessageType.text,
    this.editedAt,
    this.isDeleted = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId:
          json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      senderName: json['sender_name'] ?? json['senderName'] ?? '',
      senderAvatar: json['sender_avatar'] ?? json['senderAvatar'],
      receiverId:
          json['receiver_id']?.toString() ??
          json['receiverId']?.toString() ??
          '',
      chatRoomId: json['chat_room_id'] as int,
      content: json['content'] ?? json['message'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      type: _parseMessageType(json['type']),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'sender_name': senderName,
    'sender_avatar': senderAvatar,
    'receiver_id': receiverId,
    'chat_room_id': chatRoomId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'type': type.name,
    'edited_at': editedAt?.toIso8601String(),
    'is_deleted': isDeleted,
  };

  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    if (type is MessageType) return type;

    switch (type.toString().toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? receiverId,
    int? chatRoomId,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    MessageType? type,
    DateTime? editedAt,
    bool? isDeleted,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      receiverId: receiverId ?? this.receiverId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

enum MessageType { text, image, file }
