import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    // Load notifications on page open
    context.read<NotificationBloc>().add(LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notifications',
      currentIndex: -1,
      showAvatar: false,
      backgroundColor: color.AppColors.background,
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            final hasUnread =
                state is NotificationLoaded && state.unreadCount > 0;
            if (!hasUnread) return const SizedBox.shrink();
            return TextButton(
              onPressed: () {
                context.read<NotificationBloc>().add(
                  MarkAllNotificationsRead(),
                );
              },
              child: Text(
                'Read All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color.AppColors.primary,
                ),
              ),
            );
          },
        ),
      ],
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(LoadNotifications());
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final item = state.notifications[index];
                  return _NotificationTile(
                    item: item,
                    onTap: () {
                      if (item.isUnread) {
                        context.read<NotificationBloc>().add(
                          MarkNotificationRead(item.id),
                        );
                      }
                    },
                  );
                },
              ),
            );
          }

          if (state is NotificationError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color.AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: color.AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () {
                        context.read<NotificationBloc>().add(
                          LoadNotifications(),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up. New notifications\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: color.AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// Notification Tile Widget
// ========================================
class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.isUnread
          ? color.AppColors.primary.withOpacity(0.04)
          : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon / Avatar
              _buildLeading(),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getTitle(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: color.AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (item.isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: color.AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Body text
                    if (_getBody().isNotEmpty)
                      Text(
                        _getBody(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: color.AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Timestamp
                    Text(
                      _formatTime(item.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    final sender = item.notifiable?.sender;

    if (sender != null &&
        sender.avatarUrl != null &&
        sender.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(sender.avatarUrl!),
        onBackgroundImageError: (_, _) {},
      );
    }

    // Fallback icon based on type
    final iconData = _getIconForType(item.type);
    final iconColor = _getColorForType(item.type);

    return CircleAvatar(
      radius: 22,
      backgroundColor: iconColor.withOpacity(0.12),
      child: Icon(iconData, size: 22, color: iconColor),
    );
  }

  String _getTitle() {
    final sender = item.notifiable?.sender;
    switch (item.type) {
      case 'new_message':
        return sender?.name ?? 'New Message';
      case 'new_connection':
        return sender?.name ?? 'New Connection';
      case 'schedule_reminder':
        return 'Schedule Reminder';
      default:
        return item.typeLabel;
    }
  }

  String _getBody() {
    switch (item.type) {
      case 'new_message':
        final content = item.notifiable?.content ?? '';
        return content.isNotEmpty ? content : 'Sent you a message';
      case 'new_connection':
        return 'Wants to connect with you';
      case 'schedule_reminder':
        return item.notifiable?.content ?? 'You have an upcoming schedule';
      default:
        return item.notifiable?.content ?? '';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'new_connection':
        return Icons.person_add_outlined;
      case 'schedule_reminder':
        return Icons.schedule_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'new_message':
        return color.AppColors.primary;
      case 'new_connection':
        return color.AppColors.secondary;
      case 'schedule_reminder':
        return color.AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    try {
      return timeago.format(dateTime);
    } catch (_) {
      return '';
    }
  }
}
