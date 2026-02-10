class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.type = MessageType.text,
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
      content: json['content'] ?? json['message'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      type: _parseMessageType(json['type']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender_id': senderId,
    'sender_name': senderName,
    'sender_avatar': senderAvatar,
    'receiver_id': receiverId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'type': type.name,
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
    String? content,
    DateTime? createdAt,
    bool? isRead,
    MessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}

enum MessageType { text, image, file }
