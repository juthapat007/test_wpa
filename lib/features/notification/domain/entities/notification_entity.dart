class NotificationItem {
  final int id;
  final String type; // "new_message", "new_connection", "schedule_reminder"
  final DateTime? readAt;
  final DateTime createdAt;
  final bool isUnread;
  final NotificationNotifiable? notifiable;

  NotificationItem({
    required this.id,
    required this.type,
    this.readAt,
    required this.createdAt,
    required this.isUnread,
    this.notifiable,
  });

  String get typeLabel {
    switch (type) {
      case 'new_message':
        return 'New Message';
      case 'new_connection':
        return 'New Connection';
      case 'schedule_reminder':
        return 'Schedule Reminder';
      default:
        return 'Notification';
    }
  }
}

class NotificationNotifiable {
  final String type; // "message", "connection", "schedule"
  final int id;
  final String? status; // ✅ เพิ่ม
  final NotificationSender? requester; // ✅ เปลี่ยนจาก sender
  final NotificationSender? target; // ✅ เพิ่ม

  final String? content;

  NotificationNotifiable({
    required this.type,
    required this.id,
    this.content,
    this.status,
    this.requester,
    this.target,
  });
}

class NotificationSender {
  final int id;
  final String name;
  final String? avatarUrl;

  NotificationSender({required this.id, required this.name, this.avatarUrl});
}
