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
      // ปิด long-press edit สำหรับ image message (ยังไม่รองรับแก้รูป)
      onLongPress:
          isMe &&
              message.type != MessageType.image &&
              onEdit != null &&
              onDelete != null
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
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: message.type == MessageType.image
                    ? EdgeInsets
                          .zero // ไม่มี padding รอบรูป
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: message.type == MessageType.image
                      ? Colors.transparent
                      : (isMe ? AppColors.primary : Colors.grey.shade200),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                  ),
                  boxShadow: message.type == MessageType.image
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: message.type == MessageType.image
                    ? _ImageBubble(
                        imageUrl: message.content,
                        isMe: isMe,
                        message: message,
                      )
                    : _TextBubble(message: message, isMe: isMe),
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
}

// ── Image Bubble ──────────────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isMe;
  final ChatMessage message;

  const _ImageBubble({
    required this.imageUrl,
    required this.isMe,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // รูปภาพ
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          child: GestureDetector(
            onTap: () => _showFullImage(context),
            child: Image.network(
              imageUrl,
              width: 220,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 220,
                  height: 160,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 220,
                height: 120,
                color: Colors.grey.shade200,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Image unavailable',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Timestamp
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead ? AppColors.primary : Colors.grey,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _FullScreenImage(imageUrl: imageUrl)),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays == 0)
      return DateFormat('h:mm a').format(dateTime.toLocal());
    if (diff.inDays == 1)
      return 'Yesterday ${DateFormat('h:mm a').format(dateTime.toLocal())}';
    return DateFormat('MMM dd, h:mm a').format(dateTime.toLocal());
  }
}

// ── Full Screen Image ──────────────────────────────────────────────────────────

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 60),
          ),
        ),
      ),
    );
  }
}

// ── Text Bubble ───────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _TextBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      ? Colors.white.withValues(alpha: 0.7)
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
                      ? Colors.white.withValues(alpha: 0.7)
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
                    ? Colors.white.withValues(alpha: 0.8)
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
                    : Colors.white.withValues(alpha: 0.8),
              ),
              if (message.isRead) ...[
                const SizedBox(width: 3),
                Text(
                  'Seen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays == 0)
      return DateFormat('h:mm a').format(dateTime.toLocal());
    if (diff.inDays == 1)
      return 'Yesterday ${DateFormat('h:mm a').format(dateTime.toLocal())}';
    return DateFormat('MMM dd, h:mm a').format(dateTime.toLocal());
  }
}

// ── Safe Avatar ───────────────────────────────────────────────────────────────

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
