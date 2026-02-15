class ConnectionRequest {
  final int id;
  final int senderId;
  final int receiverId;
  final String status;
  final DateTime createdAt;
  final ConnectionRequestDelegate? sender;

  ConnectionRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.sender,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}

class ConnectionRequestDelegate {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? title;
  final String? companyName;

  ConnectionRequestDelegate({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.title,
    this.companyName,
  });
}
