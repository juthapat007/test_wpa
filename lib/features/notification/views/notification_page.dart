import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';
import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';
import 'package:test_wpa/features/notification/presentation/bloc/connection_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/widgets/app_bar_back.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    ReadContext(
      context,
    ).read<NotificationBloc>().add(LoadNotifications(type: 'system'));
    ReadContext(context).read<ConnectionBloc>().add(LoadConnectionRequests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarBack(title: 'Notifications'),
      body: Column(
        children: [
          _TabBar(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SystemNotificationsTab(),
                _AttendanceTab(),
                _FriendRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab Bar
// ═══════════════════════════════════════════════════════════════════════════

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: TabBar(
        isScrollable: true,
        controller: controller,
        labelColor: const Color(0xFF1A3A6B),
        unselectedLabelColor: Colors.grey[400],
        indicatorColor: const Color(0xFF1A3A6B),
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        onTap: (index) {
          if (index == 0) {
            ReadContext(
              context,
            ).read<NotificationBloc>().add(LoadNotifications(type: 'system'));
          } else if (index == 2) {
            ReadContext(
              context,
            ).read<ConnectionBloc>().add(LoadConnectionRequests());
          }
        },
        tabs: [
          // ✅ Badge dot บน EVENT PLAN tab
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('EVENT PLAN'),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: _UnreadBadgeDot(),
                ),
              ],
            ),
          ),
          const Tab(text: 'ATTENDANCE STATUS'),

          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('FRIENDS REQUESTS'),
                const SizedBox(width: 4),
                _PendingBadgeDot(),
                // Padding(
                //   padding: const EdgeInsets.only(bottom: 15),
                //   child: _PendingBadgeDot(),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadgeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final hasUnread = state is NotificationLoaded && state.unreadCount > 0;
        if (!hasUnread) return const SizedBox.shrink();
        return Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _PendingBadgeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionBloc, ConnectionRequestState>(
      builder: (context, state) {
        final hasPending =
            state is ConnectionRequestLoaded &&
            state.requests.any((r) => r.isPending);
        if (!hasPending) return const SizedBox.shrink();
        return Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 1: System / Event Notifications
// ═══════════════════════════════════════════════════════════════════════════

class _SystemNotificationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) => switch (state) {
        NotificationLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        NotificationLoaded(notifications: final items) when items.isEmpty =>
          const _EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No Notifications',
            message:
                'You\'re all caught up.\nNew notifications will appear here.',
          ),
        NotificationLoaded(notifications: final items) => Column(
          children: [
            // ✅ แถบสรุป unread count + ปุ่ม mark all
            _NotificationHeader(
              unreadCount: (state as NotificationLoaded).unreadCount,
            ),
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
        ),
        NotificationError(message: final msg) => _ErrorState(
          message: msg,
          onRetry: () => ReadContext(
            context,
          ).read<NotificationBloc>().add(LoadNotifications(type: 'system')),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  void _handleTap(BuildContext context, NotificationItem item) {
    // ✅ mark as read เมื่อกด
    if (item.isUnread) {
      ReadContext(
        context,
      ).read<NotificationBloc>().add(MarkNotificationRead(item.id));
    }
    // ✅ เปิด detail sheet เพื่ออ่านเนื้อหาเต็ม (โดยเฉพาะ admin message)
    _showDetailSheet(context, item);
  }

  void _showDetailSheet(BuildContext context, NotificationItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationDetailSheet(item: item),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _NotificationHeader extends StatelessWidget {
  final int unreadCount;
  const _NotificationHeader({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          if (unreadCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.AppColors.primary.withOpacity(0.1),
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
          ],
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

// ─── Notification Tile ────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.isUnread
          ? color.AppColors.primary.withOpacity(0.05)
          : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ แถบสีซ้ายแสดง unread
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
                        // ✅ dot สีน้ำเงินขวา
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
                              color: color.AppColors.primary.withOpacity(0.7),
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
    final avatarUrl = item.notifiable?.requester?.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    // ✅ icon ตาม type
    return CircleAvatar(
      radius: 22,
      backgroundColor: _tileColor.withOpacity(0.12),
      child: Icon(_tileIcon, size: 22, color: _tileColor),
    );
  }

  String get _title => switch (item.type) {
    'connection_request' => item.notifiable?.requester?.name ?? 'Someone',
    'connection_accepted' =>
      item.notifiable?.requester?.name ??
          item.notifiable?.target?.name ??
          'Someone',
    _ => item.typeLabel,
  };

  String get _body => switch (item.type) {
    'connection_request' => 'Sent you a friend request',
    'connection_accepted' => 'Accepted your friend request ✓',
    _ => item.notifiable?.content ?? '',
  };

  IconData get _tileIcon => switch (item.type) {
    'new_message' => Icons.chat_bubble_outline,
    'connection_request' => Icons.person_add_outlined,
    'connection_accepted' => Icons.people_outline,
    'schedule_reminder' => Icons.schedule_outlined,
    _ => Icons.notifications_outlined,
  };

  Color get _tileColor => switch (item.type) {
    'connection_request' || 'connection_accepted' => color.AppColors.secondary,
    'schedule_reminder' => color.AppColors.warning,
    _ => color.AppColors.primary,
  };
}

// ─── Detail Bottom Sheet ──────────────────────────────────────────────────

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationItem item;
  const _NotificationDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = item.notifiable?.requester?.avatarUrl;
    final senderName = item.notifiable?.requester?.name;
    final content = item.notifiable?.content;
    final isConnectionType =
        item.type == 'connection_request' || item.type == 'connection_accepted';

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
            // Handle
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
                            backgroundColor: color.AppColors.primary
                                .withOpacity(0.12),
                            child: Icon(
                              isConnectionType
                                  ? Icons.person_outline
                                  : Icons.notifications_outlined,
                              size: 28,
                              color: color.AppColors.primary,
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnectionType
                                    ? (senderName ?? 'Someone')
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
                    if (isConnectionType) ...[
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
                      if (senderName != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.person_outline,
                          label: 'From',
                          value: senderName,
                        ),
                      ],
                    ] else if (content != null && content.isNotEmpty) ...[
                      // ✅ แสดง content เต็มจาก Admin
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
                          content,
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

                    // ✅ ถ้าเป็น friend request ให้กดไปหน้า profile ได้
                    if (isConnectionType &&
                        item.notifiable?.id != null &&
                        item.notifiable!.id > 0) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Modular.to.pushNamed(
                              '/other_profile',
                              arguments: {'delegate_id': item.notifiable!.id},
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

// ═══════════════════════════════════════════════════════════════════════════
// Tab 2: Attendance
// ═══════════════════════════════════════════════════════════════════════════

class _AttendanceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const _EmptyState(
    icon: Icons.how_to_reg_outlined,
    title: 'Attendance Status',
    message: 'Your attendance records\nwill appear here.',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 3: Friend Requests
// ═══════════════════════════════════════════════════════════════════════════

class _FriendRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectionBloc, ConnectionRequestState>(
      listener: (context, state) {
        final msg = switch (state) {
          ConnectionRequestActionSuccess(message: final m) => (m, Colors.green),
          ConnectionRequestError(message: final m) => (m, Colors.red),
          _ => null,
        };
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg.$1),
              backgroundColor: msg.$2,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) => switch (state) {
        ConnectionRequestLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        ConnectionRequestLoaded(requests: final reqs) => _buildList(
          context,
          reqs.where((r) => r.isPending).toList(),
        ),
        ConnectionRequestError(message: final msg) => _ErrorState(
          message: msg,
          onRetry: () => ReadContext(
            context,
          ).read<ConnectionBloc>().add(LoadConnectionRequests()),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildList(BuildContext context, List<ConnectionRequest> pending) {
    if (pending.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline,
        title: 'No Friend Requests',
        message: 'You don\'t have any pending\nfriend requests.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ReadContext(
        context,
      ).read<ConnectionBloc>().add(LoadConnectionRequests()),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          final request = pending[index];
          return _FriendRequestCard(
            request: request,
            onConfirm: () => ReadContext(
              context,
            ).read<ConnectionBloc>().add(AcceptConnectionRequest(request.id)),
            onNotNow: () => ReadContext(
              context,
            ).read<ConnectionBloc>().add(RejectConnectionRequest(request.id)),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Friend Request Card
// ═══════════════════════════════════════════════════════════════════════════

class _FriendRequestCard extends StatelessWidget {
  final ConnectionRequest request;
  final VoidCallback onConfirm;
  final VoidCallback onNotNow;

  const _FriendRequestCard({
    required this.request,
    required this.onConfirm,
    required this.onNotNow,
  });

  @override
  Widget build(BuildContext context) {
    final sender = request.sender;
    final avatarUrl = sender?.avatarUrl ?? '';
    final name = sender?.name ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: () => Modular.to.pushNamed(
          '/other_profile',
          arguments: {'delegate_id': request.senderId},
        ),
        borderRadius: BorderRadius.circular(12),

        // _FriendRequestCard — เปลี่ยน child ของ Card เป็น Column แทน Row
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── avatar + ชื่อ ──────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    backgroundColor: const Color(0xFF4A90D9).withOpacity(0.15),
                    child: avatarUrl.isEmpty
                        ? Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A90D9),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2340),
                          ),
                        ),
                        if (sender?.title?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            sender!.title!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (sender?.companyName?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            sender!.companyName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // ── ล่าง: ปุ่ม Accept / Reject ────────────────────────
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onNotNow,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color.AppColors.warning,
                        side: BorderSide(color: color.AppColors.warning),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color.AppColors.primary : color.AppColors.warning,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis, // ✅ เพิ่ม
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
          ), // ลด 14 → 13
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color.AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: color.AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
