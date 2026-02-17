// lib/features/other_profile/domain/entities/profile_detail.dart

enum ConnectionStatus { none, requestedByMe, requestedToMe, connected }

class ProfileDetail {
  final int id;
  final String name;
  final String? title;
  final String email;
  final String companyName;
  final String avatarUrl;
  final String countryCode;
  final bool isConnected;
  final ConnectionStatus connectionStatus;
  final int? teamId;

  ProfileDetail({
    required this.id,
    required this.name,
    this.title,
    required this.email,
    required this.companyName,
    required this.avatarUrl,
    required this.countryCode,
    required this.isConnected,
    this.connectionStatus = ConnectionStatus.none,
    this.teamId,
  });

  static ConnectionStatus parseConnectionStatus(String? raw) {
    switch (raw) {
      case 'requested_by_me':
        return ConnectionStatus.requestedByMe;
      case 'requested_to_me':
        return ConnectionStatus.requestedToMe;
      case 'connected':
        return ConnectionStatus.connected;
      default:
        return ConnectionStatus.none;
    }
  }
}
