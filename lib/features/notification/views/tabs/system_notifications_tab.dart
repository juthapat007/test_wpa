import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/notification/cards/notification_shared_widgets.dart';
import 'package:timeago/timeago.dart' as timeago;

/// type ที่แสดงใน EVENT PLAN tab
const _systemTypes = {'admin_announce', 'leave_reported'};

// ═══════════════════════════════════════════════════════════════════════════
// Tab
// ═══════════════════════════════════════════════════════════════════════════

class SystemNotificationsTab extends StatelessWidget {
  const SystemNotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) => switch (state) {
        NotificationLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        NotificationLoaded(notifications: final allItems) => Builder(
          builder: (context) {
            final items = allItems
                .where((n) => _systemTypes.contains(n.type))
                .toList();

            if (items.isEmpty) {
              return const NotificationEmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'No Notifications',
                message:
                    'You\'re all caught up.\nNew notifications will appear here.',
              );
            }

            final filteredUnread = items.where((n) => n.isUnread).length;

            return Column(
              children: [
                _SystemNotificationHeader(unreadCount: filteredUnread),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) => _NotificationTile(
                      item: items[index],
                      onTap: () => _handleTap(context, items[index]),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        NotificationError(message: final msg) => NotificationErrorState(
          message: msg,
          onRetry: () => ReadContext(
            context,
          ).read<NotificationBloc>().add(LoadNotifications()),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  void _handleTap(BuildContext context, NotificationItem item) {
    if (item.isUnread) {
      ReadContext(
        context,
      ).read<NotificationBloc>().add(MarkNotificationRead(item.id));
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationDetailSheet(item: item),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

class _SystemNotificationHeader extends StatelessWidget {
  final int unreadCount;
  const _SystemNotificationHeader({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount unread',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.AppColors.primary,
                ),
              ),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => ReadContext(
              context,
            ).read<NotificationBloc>().add(MarkAllNotificationsRead()),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Mark all as read'),
            style: TextButton.styleFrom(
              foregroundColor: color.AppColors.primary,
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tile
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.isUnread
          ? color.AppColors.primary.withValues(alpha: 0.05)
          : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.isUnread)
                Container(
                  width: 3,
                  height: 48,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: color.AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 13),
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _title,
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
                    if (_body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: color.AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 11,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          timeago.format(item.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        if (item.isUnread) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• Tap to read',
                            style: TextStyle(
                              fontSize: 11,
                              color: color.AppColors.primary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildAvatar() {
    if (item.type == 'admin_announce') {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFF1A3A6B).withValues(alpha: 0.12),
        child: const Icon(
          Icons.campaign_outlined,
          size: 22,
          color: Color(0xFF1A3A6B),
        ),
      );
    }

    final avatarUrl = item.type == 'leave_reported'
        ? item.notifiable?.reporter?.avatarUrl
        : item.notifiable?.requester?.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: _tileColor.withValues(alpha: 0.12),
      child: Icon(_tileIcon, size: 22, color: _tileColor),
    );
  }

  String get _title => switch (item.type) {
    'connection_request' => item.notifiable?.requester?.name ?? 'Someone',
    'connection_accepted' =>
      item.notifiable?.requester?.name ??
          item.notifiable?.target?.name ??
          'Someone',
    'leave_reported' => item.notifiable?.reporter?.name ?? 'Someone',
    'admin_announce' => 'Announcement',
    _ => item.typeLabel,
  };

  String get _body => switch (item.type) {
    'connection_accepted' => 'Accepted your friend request',
    'leave_reported' =>
      item.notifiable?.scheduleId != null
          ? 'ยื่นใบลา • Schedule #${item.notifiable!.scheduleId}'
          : 'ยื่นใบลา',
    'admin_announce' => item.notifiable?.content ?? '',
    _ => item.notifiable?.content ?? '',
  };

  IconData get _tileIcon => switch (item.type) {
    'new_message' => Icons.chat_bubble_outline,
    'connection_request' => Icons.person_add_outlined,
    'connection_accepted' => Icons.people_outline,
    'schedule_reminder' => Icons.schedule_outlined,
    'leave_reported' => Icons.event_busy_outlined,
    'admin_announce' => Icons.campaign_outlined,
    _ => Icons.notifications_outlined,
  };

  Color get _tileColor => switch (item.type) {
    'connection_request' || 'connection_accepted' => color.AppColors.secondary,
    'schedule_reminder' => color.AppColors.warning,
    'leave_reported' => const Color(0xFFE67E22),
    'admin_announce' => const Color(0xFF1A3A6B),
    _ => color.AppColors.primary,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Detail Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationItem item;
  const _NotificationDetailSheet({required this.item});

  bool get _isLeave => item.type == 'leave_reported';
  bool get _isConnectionType =>
      item.type == 'connection_request' || item.type == 'connection_accepted';
  bool get _isAnnounce => item.type == 'admin_announce';

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl;
    final String? displayName;

    if (_isAnnounce) {
      avatarUrl = null;
      displayName = null;
    } else if (_isLeave) {
      avatarUrl = item.notifiable?.reporter?.avatarUrl;
      displayName = item.notifiable?.reporter?.name;
    } else if (_isConnectionType) {
      avatarUrl = item.notifiable?.requester?.avatarUrl;
      displayName = item.notifiable?.requester?.name;
    } else {
      avatarUrl = null;
      displayName = null;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      children: [
                        if (avatarUrl != null && avatarUrl.isNotEmpty)
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(avatarUrl),
                          )
                        else
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: color.AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              _isAnnounce
                                  ? Icons.campaign_outlined
                                  : _isLeave
                                  ? Icons.event_busy_outlined
                                  : _isConnectionType
                                  ? Icons.person_outline
                                  : Icons.notifications_outlined,
                              size: 28,
                              color: _isAnnounce
                                  ? const Color(0xFF1A3A6B)
                                  : _isLeave
                                  ? const Color(0xFFE67E22)
                                  : color.AppColors.primary,
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAnnounce
                                    ? 'Announcement'
                                    : _isLeave || _isConnectionType
                                    ? (displayName ?? 'Someone')
                                    : item.typeLabel,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A2340),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeago.format(item.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 16),

                    // ── Content ──────────────────────────────────────────
                    if (_isAnnounce) ...[
                      Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1A3A6B,
                          ).withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFF1A3A6B,
                            ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          item.notifiable?.content ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xFF1A2340),
                          ),
                        ),
                      ),
                    ] else if (_isLeave) ...[
                      _DetailRow(
                        icon: Icons.event_busy_outlined,
                        label: 'Type',
                        value: 'Leave Request',
                      ),
                      if (displayName != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.person_outline,
                          label: 'Reported by',
                          value: displayName,
                        ),
                      ],
                      if (item.notifiable?.scheduleId != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Schedule ID',
                          value: '#${item.notifiable!.scheduleId}',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // TODO: Modular.to.pushNamed('/schedule/${item.notifiable!.scheduleId}');
                            },
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('View Schedule'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE67E22),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ] else if (_isConnectionType) ...[
                      _DetailRow(
                        icon: Icons.info_outline,
                        label: 'Status',
                        value: switch (item.type) {
                          'connection_request' => 'Sent you a friend request',
                          'connection_accepted' =>
                            'Accepted your friend request',
                          _ => '',
                        },
                      ),
                      if (displayName != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.person_outline,
                          label: 'From',
                          value: displayName,
                        ),
                      ],
                      if (item.notifiable?.id != null &&
                          item.notifiable!.id > 0) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Modular.to.pushNamed(
                                '/other_profile/${item.notifiable!.id}',
                              );
                            },
                            icon: const Icon(Icons.person),
                            label: const Text('View Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color.AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ] else if (item.notifiable?.content?.isNotEmpty ==
                        true) ...[
                      Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          item.notifiable!.content!,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xFF1A2340),
                          ),
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: Text(
                          'No additional details',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                letterSpacing: 0.3,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A2340),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
