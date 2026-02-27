import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';

class ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;
  final VoidCallback? onProfileTap;

  const ChatRoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap, // กดธรรมดา → เปิด chat
        onLongPress: onProfileTap, // กดค้าง → ไป profile
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(), // ไม่ต้องห่ออะไร
              const SizedBox(width: 12),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name & Time
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                room.participantName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: room.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (room.lastMessage != null)
              Text(
                _formatTime(room.lastMessage!.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: room.unreadCount > 0
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: room.unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
          ],
        ),

        const SizedBox(height: 4),

        // Last Message & Unread Badge
        Row(
          children: [
            Expanded(
              child: Text(
                room.lastMessage?.content ?? 'No messages yet',
                style: TextStyle(
                  fontSize: 14,
                  color: room.unreadCount > 0
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: room.unreadCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (room.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  room.unreadCount > 99 ? '99+' : room.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        _AuthenticatedAvatar(
          imageUrl: room.participantAvatar,
          name: room.participantName,
          radius: 28,
        ),
        if (room.lastActiveAt != null &&
            DateTime.now().difference(room.lastActiveAt!).inMinutes < 5)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) return DateFormat('HH:mm').format(dateTime);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dateTime);
    return DateFormat('MMM dd').format(dateTime);
  }
}

class _AuthenticatedAvatar extends StatefulWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const _AuthenticatedAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
  });

  @override
  State<_AuthenticatedAvatar> createState() => _AuthenticatedAvatarState();
}

class _AuthenticatedAvatarState extends State<_AuthenticatedAvatar> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final storage = Modular.get<FlutterSecureStorage>();
    final token = await storage.read(key: 'auth_token');
    if (mounted) setState(() => _token = token);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Widget _buildFallback() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: Text(
        _getInitials(widget.name),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: widget.radius * 0.65,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    // ถ้าเป็น ui-avatars.com หรือ http อื่นๆ ที่ไม่ต้อง auth
    final needsAuth =
        hasUrl && widget.imageUrl!.contains('wpa-docker.onrender.com');

    if (!hasUrl) return _buildFallback();

    // ✅ URL ภายนอก (ui-avatars etc.) โหลดตรงได้เลย
    if (!needsAuth) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: NetworkImage(widget.imageUrl!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    // ✅ URL ของ server ต้องใส่ token
    if (_token == null) return _buildFallback();

    return ClipOval(
      child: SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 2,
        child: Image.network(
          widget.imageUrl!,
          fit: BoxFit.cover,
          headers: {'Authorization': 'Bearer $_token', 'Accept': 'image/*'},
          errorBuilder: (_, __, ___) => _buildFallback(),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _buildFallback();
          },
        ),
      ),
    );
  }
}
