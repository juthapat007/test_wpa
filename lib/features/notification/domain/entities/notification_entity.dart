class NotificationItem {
  final int id;
  final String
  type; // "new_message", "new_connection", "schedule_reminder", "leave_reported"
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
      case 'leave_reported':
        return 'Leave Request';
      case 'admin_announce':
        return 'Announcement';
      default:
        return 'Notification';
    }
  }
}

class NotificationNotifiable {
  final String type;
  final int id;
  final String? status;
  final NotificationSender? requester;
  final NotificationSender? target;
  final String? content;

  final NotificationSender? reporter;

  /// schedule ที่เกี่ยวข้อง (จาก notifiable.schedule_id)
  final int? scheduleId;

  NotificationNotifiable({
    required this.type,
    required this.id,
    this.content,
    this.status,
    this.requester,
    this.target,
    this.reporter,
    this.scheduleId,
  });
}

class NotificationSender {
  final int id;
  final String name;
  final String? avatarUrl;

  NotificationSender({required this.id, required this.name, this.avatarUrl});
}
