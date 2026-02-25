import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
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
          const Tab(text: 'EVENT PLAN'),
          const Tab(text: 'ATTENDANCE STATUS'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('FRIENDS REQUESTS'),
                const SizedBox(width: 4),
                _PendingBadgeDot(),
              ],
            ),
          ),
        ],
      ),
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
// Tab 1: System Notifications
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
        NotificationLoaded(notifications: final items) => RefreshIndicator(
          onRefresh: () async => ReadContext(
            context,
          ).read<NotificationBloc>().add(LoadNotifications(type: 'system')),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) => _NotificationTile(
              item: items[index],
              onTap: () {
                final item = items[index];
                if (item.isUnread) {
                  ReadContext(
                    context,
                  ).read<NotificationBloc>().add(MarkNotificationRead(item.id));
                }
              },
            ),
          ),
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
// Notification Tile
// ═══════════════════════════════════════════════════════════════════════════

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
                    Text(
                      timeago.format(item.createdAt),
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

  Widget _buildAvatar() {
    final avatarUrl = item.notifiable?.requester?.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: _tileColor.withOpacity(0.12),
      child: Icon(_tileIcon, size: 22, color: _tileColor),
    );
  }

  String get _title => switch (item.type) {
    'connection_request' => item.notifiable?.requester?.name ?? 'Someone',
    'connection_accepted' => item.notifiable?.target?.name ?? 'Someone',
    _ => item.typeLabel,
  };

  String get _body => switch (item.type) {
    'connection_request' => switch (item.notifiable?.status) {
      'accepted' => 'Accepted your friend request',
      'rejected' => 'Declined your friend request',
      _ => 'Sent you a friend request',
    },
    'connection_accepted' => 'Accepted your friend request ✓',
    _ => item.notifiable?.content ?? '',
  };

  IconData get _tileIcon => switch (item.type) {
    'new_message' => Icons.chat_bubble_outline,
    'new_connection' => Icons.person_add_outlined,
    'schedule_reminder' => Icons.schedule_outlined,
    _ => Icons.notifications_outlined,
  };

  Color get _tileColor => switch (item.type) {
    'new_message' => color.AppColors.primary,
    'new_connection' => color.AppColors.secondary,
    'schedule_reminder' => color.AppColors.warning,
    _ => Colors.grey,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Friend Request Card — ใช้ style เดียวกับ DelegateCard
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar ────────────────────────────────────────────────
              CircleAvatar(
                radius: 26,
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                backgroundColor: const Color(0xFF4A90D9).withOpacity(0.15),
                child: avatarUrl.isEmpty
                    ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90D9),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // ── Name + title + company ────────────────────────────────
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
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                    if (sender?.companyName?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        sender!.companyName!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Buttons — ป้องกัน tap bubble ขึ้นการ์ด ───────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      label: 'Reject',
                      onTap: onNotNow,
                      filled: false,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Accept',
                      onTap: onConfirm,
                      filled: true,
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
          color: filled
              ? color
                    .AppColors
                    .primary // ปุ่ม Confirm
              : color.AppColors.warning, // ปุ่ม Not Now (เปลี่ยนสีตามต้องการ)
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white, // 👈 ตัวอักษรขาวทั้งคู่
          ),
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
