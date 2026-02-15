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
    _tabController = TabController(length: 2, vsync: this);

    // Load initial data
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
    return AppScaffold(
      title: 'Notifications',
      currentIndex: -1,
      showAvatar: false,
      backgroundColor: color.AppColors.background,
      actions: [_buildMarkAllReadButton()],
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSystemNotificationsTab(),
                _buildConnectionRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: color.AppColors.primary,
        unselectedLabelColor: color.AppColors.textSecondary,
        indicatorColor: color.AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        onTap: (index) {
          // Reload data when switching tabs
          if (index == 0) {
            ReadContext(
              context,
            ).read<NotificationBloc>().add(LoadNotifications(type: 'system'));
          } else {
            ReadContext(
              context,
            ).read<ConnectionBloc>().add(LoadConnectionRequests());
          }
        },
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('System'),
                const SizedBox(width: 6),
                _buildSystemBadge(),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Connections'),
                const SizedBox(width: 6),
                _buildConnectionBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemBadge() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationLoaded) {
          unreadCount = state.notifications.where((n) => n.isUnread).length;
        }

        if (unreadCount == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.AppColors.error,
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(minWidth: 20),
          child: Text(
            unreadCount > 99 ? '99+' : '$unreadCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildConnectionBadge() {
    return BlocBuilder<ConnectionBloc, ConnectionRequestState>(
      builder: (context, state) {
        int pendingCount = 0;
        if (state is ConnectionRequestLoaded) {
          pendingCount = state.requests.where((r) => r.isPending).length;
        }

        if (pendingCount == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.AppColors.error,
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(minWidth: 20),
          child: Text(
            pendingCount > 99 ? '99+' : '$pendingCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildMarkAllReadButton() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        // Only show for system notifications tab
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

  // System Notifications Tab
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
            onRetry: () {
              ReadContext(
                context,
              ).read<NotificationBloc>().add(LoadNotifications(type: 'system'));
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // Connection Requests Tab
  Widget _buildConnectionRequestsTab() {
    return BlocConsumer<ConnectionBloc, ConnectionRequestState>(
      listener: (context, state) {
        if (state is ConnectionRequestActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: color.AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        if (state is ConnectionRequestError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: color.AppColors.error,
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
              title: 'No Connection Requests',
              message: 'You don\'t have any pending\nconnection requests.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ReadContext(
                context,
              ).read<ConnectionBloc>().add(LoadConnectionRequests());
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pendingRequests.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                return _ConnectionRequestTile(
                  request: request,
                  onAccept: () {
                    ReadContext(context).read<ConnectionBloc>().add(
                      AcceptConnectionRequest(request.id),
                    );
                  },
                  onReject: () {
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
            onRetry: () {
              ReadContext(
                context,
              ).read<ConnectionBloc>().add(LoadConnectionRequests());
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

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
    final sender = item.notifiable?.sender;

    if (sender != null &&
        sender.avatarUrl != null &&
        sender.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(sender.avatarUrl!),
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

// ========================================
// Connection Request Tile Widget
// ========================================
class _ConnectionRequestTile extends StatelessWidget {
  final ConnectionRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ConnectionRequestTile({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final sender = request.sender;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundImage:
                sender?.avatarUrl != null && sender!.avatarUrl!.isNotEmpty
                ? NetworkImage(sender.avatarUrl!)
                : const AssetImage('assets/images/empty_state.png')
                      as ImageProvider,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender?.name ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color.AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (sender?.title != null)
                  Text(
                    sender!.title!,
                    style: TextStyle(
                      fontSize: 13,
                      color: color.AppColors.textSecondary,
                    ),
                  ),
                if (sender?.companyName != null)
                  Text(
                    sender!.companyName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color.AppColors.textSecondary,
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color.AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
