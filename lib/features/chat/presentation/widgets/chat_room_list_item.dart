import 'package:flutter/material.dart';
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
      child: Stack(
        children: [
          // Layer 1: InkWell ทั้งใบ → เปิด chat
          Positioned.fill(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // Layer 2: content row (ไม่มี onTap)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar — กดแยก ไป profile
                // GestureDetector(onTap: onProfileTap, child: _buildAvatar()),
                MouseRegion(
                  child: GestureDetector(
                    onTap: onProfileTap,
                    behavior: HitTestBehavior.opaque,
                    child: _buildAvatar(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
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
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage:
              room.participantAvatar != null &&
                  room.participantAvatar!.isNotEmpty
              ? NetworkImage(room.participantAvatar!)
              : null,
          child:
              room.participantAvatar == null || room.participantAvatar!.isEmpty
              ? Text(
                  _getInitials(room.participantName),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
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
