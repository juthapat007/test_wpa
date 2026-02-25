import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:test_wpa/features/chat/presentation/widgets/message_action_widgets.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Function(String)? onEdit;
  final VoidCallback? onDelete;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: isMe && onEdit != null && onDelete != null
          ? () => _showActionMenu(context)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _SafeAvatar(
                imageUrl: message.senderAvatar,
                name: message.senderName,
                radius: 16,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // if (!isMe && message.senderName.isNotEmpty) ...[
                    //   Text(
                    //     message.senderName,
                    //     style: const TextStyle(
                    //       color: AppColors.primary,
                    //       fontSize: 12,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    //   const SizedBox(height: 4),
                    // ],
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.editedAt != null) ...[
                          Text(
                            'Edited',
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : AppColors.textSecondary,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '•',
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            color: isMe
                                ? Colors.white.withOpacity(0.8)
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead
                                ? Colors.lightBlueAccent
                                : Colors.white.withOpacity(0.8),
                          ),
                          if (message.isRead) ...[
                            const SizedBox(width: 3),
                            Text(
                              'Seen',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    MessageActionBottomSheet.show(
      context: context,
      onEdit: () {
        EditMessageDialog.show(
          context: context,
          initialContent: message.content,
          onSave: (newContent) {
            if (onEdit != null) onEdit!(newContent);
          },
        );
      },
      onDelete: () {
        DeleteMessageDialog.show(
          context: context,
          onConfirm: () {
            if (onDelete != null) onDelete!();
          },
        );
      },
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
    if (diff.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    }
    return DateFormat('MMM dd, HH:mm').format(dateTime);
  }
}

/// ✅ Widget Avatar ที่จัดการ 404 / expired URL ได้อย่างปลอดภัย
class _SafeAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const _SafeAvatar({
    required this.imageUrl,
    required this.name,
    required this.radius,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Widget _buildFallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        _getInitials(name),
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    if (!hasUrl) return _buildFallback();

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          // ✅ จัดการ 404 / expired URL → แสดง initials แทน
          errorBuilder: (_, __, ___) => _buildFallback(),
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey.shade200,
            );
          },
        ),
      ),
    );
  }
}
