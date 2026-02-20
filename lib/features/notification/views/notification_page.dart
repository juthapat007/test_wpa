import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';
import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';
import 'package:test_wpa/features/notification/presentation/bloc/connection_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/widgets/app_scaffold.dart';
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
    return Container(
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSystemNotificationsTab(),
                _buildAttendanceTab(),
                _buildConnectionRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: TabBar(
        isScrollable: true,
        controller: _tabController,
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
                const Text('FRIENDS REQUETS'),
                const SizedBox(width: 4),
                _buildConnectionBadgeDot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // จุดแดงเล็กๆ แบบในรูป
  Widget _buildConnectionBadgeDot() {
    return BlocBuilder<ConnectionBloc, ConnectionRequestState>(
      builder: (context, state) {
        int pendingCount = 0;
        if (state is ConnectionRequestLoaded) {
          pendingCount = state.requests.where((r) => r.isPending).length;
        }
        if (pendingCount == 0) return const SizedBox.shrink();
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

  Widget _buildMarkAllReadButton() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (_tabController.index != 0) return const SizedBox.shrink();
        final hasUnread =
            state is NotificationLoaded &&
            state.notifications.any((n) => n.isUnread);
        if (!hasUnread) return const SizedBox.shrink();
        return TextButton(
          onPressed: () {
            ReadContext(context).read<NotificationBloc>().add(
              MarkAllNotificationsRead(type: 'system'),
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
    );
  }

  // ─── Tab 1: Event Plan / System ──────────────────────────────────────────
  Widget _buildSystemNotificationsTab() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is NotificationLoaded) {
          if (state.notifications.isEmpty) {
            return _buildEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Notifications',
              message:
                  'You\'re all caught up. New notifications\nwill appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ReadContext(
                context,
              ).read<NotificationBloc>().add(LoadNotifications(type: 'system'));
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final item = state.notifications[index];
                return _NotificationTile(
                  item: item,
                  onTap: () {
                    if (item.isUnread) {
                      ReadContext(context).read<NotificationBloc>().add(
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
          return _buildErrorState(
            message: state.message,
            onRetry: () => ReadContext(
              context,
            ).read<NotificationBloc>().add(LoadNotifications(type: 'system')),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ─── Tab 2: Attendance Status ────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    return _buildEmptyState(
      icon: Icons.how_to_reg_outlined,
      title: 'Attendance Status',
      message: 'Your attendance records\nwill appear here.',
    );
  }

  // ─── Tab 3: Friends Requests ─────────────────────────────────────────────
  Widget _buildConnectionRequestsTab() {
    return BlocConsumer<ConnectionBloc, ConnectionRequestState>(
      listener: (context, state) {
        if (state is ConnectionRequestActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        if (state is ConnectionRequestError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ConnectionRequestLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ConnectionRequestLoaded) {
          final pendingRequests = state.requests
              .where((r) => r.isPending)
              .toList();

          if (pendingRequests.isEmpty) {
            return _buildEmptyState(
              icon: Icons.people_outline,
              title: 'No Friend Requests',
              message: 'You don\'t have any pending\nfriend requests.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ReadContext(
                context,
              ).read<ConnectionBloc>().add(LoadConnectionRequests());
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: pendingRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                return _FriendRequestCard(
                  request: request,
                  onConfirm: () {
                    ReadContext(context).read<ConnectionBloc>().add(
                      AcceptConnectionRequest(request.id),
                    );
                  },
                  onNotNow: () {
                    ReadContext(context).read<ConnectionBloc>().add(
                      RejectConnectionRequest(request.id),
                    );
                  },
                );
              },
            ),
          );
        }

        if (state is ConnectionRequestError) {
          return _buildErrorState(
            message: state.message,
            onRetry: () => ReadContext(
              context,
            ).read<ConnectionBloc>().add(LoadConnectionRequests()),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ─── Shared helpers ──────────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
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

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
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

// ═══════════════════════════════════════════════════════════════════════════
// Notification Tile (System tab)
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
              _buildLeading(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
    final requester = item.notifiable?.requester;
    if (requester != null &&
        requester.avatarUrl != null &&
        requester.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(requester.avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }
    final iconData = _getIconForType(item.type);
    final iconColor = _getColorForType(item.type);
    return CircleAvatar(
      radius: 22,
      backgroundColor: iconColor.withOpacity(0.12),
      child: Icon(iconData, size: 22, color: iconColor),
    );
  }

  String _getTitle() {
    final requester = item.notifiable?.requester;
    switch (item.type) {
      case 'connection_request':
        return requester?.name ?? 'Someone';
      case 'connection_accepted':
        final target = item.notifiable?.target;
        return target?.name ?? 'Someone';
      default:
        return item.typeLabel;
    }
  }

  String _getBody() {
    switch (item.type) {
      case 'connection_request':
        final status = item.notifiable?.status;
        if (status == 'accepted') return 'Accepted your friend request';
        if (status == 'rejected') return 'Declined your friend request';
        return 'Sent you a friend request';
      case 'connection_accepted':
        return 'Accepted your friend request ✓';
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

// ═══════════════════════════════════════════════════════════════════════════
// Friend Request Card — ตรงกับ UI ในรูป
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────────────
          _buildAvatar(sender),
          const SizedBox(width: 14),

          // ── Name + Company • Title ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender?.name ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 3),
                if (_buildSubtitle(sender).isNotEmpty)
                  Text(
                    _buildSubtitle(sender),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Buttons ──────────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(label: 'Not Now', onTap: onNotNow, isFilled: false),
              const SizedBox(width: 8),
              _ActionButton(label: 'Confirm', onTap: onConfirm, isFilled: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ConnectionRequestDelegate? sender) {
    final hasAvatar =
        sender?.avatarUrl != null && sender!.avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: 26,
      backgroundImage: hasAvatar ? NetworkImage(sender!.avatarUrl!) : null,
      backgroundColor: const Color(0xFFE0B89A).withOpacity(0.35),
      child: !hasAvatar
          ? Text(
              (sender?.name ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC47F4F),
              ),
            )
          : null,
    );
  }

  String _buildSubtitle(ConnectionRequestDelegate? sender) {
    final parts = <String>[];
    if (sender?.companyName != null && sender!.companyName!.isNotEmpty) {
      parts.add(sender.companyName!);
    }
    if (sender?.title != null && sender!.title!.isNotEmpty) {
      parts.add(sender.title!);
    }
    return parts.join(' • ');
  }
}

// ─── ปุ่ม Not Now / Confirm ──────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isFilled; // true = Confirm (golden), false = Not Now (outline)

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // Confirm = สีทอง amber, Not Now = ขอบฟ้าใส
          color: isFilled ? const Color(0xFFD4A843) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isFilled
              ? null
              : Border.all(color: const Color(0xFF4A90D9), width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isFilled ? Colors.white : const Color(0xFF4A90D9),
          ),
        ),
      ),
    );
  }
}
