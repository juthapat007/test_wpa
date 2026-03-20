import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/notification/domain/entities/connection_request_entity.dart';
import 'package:test_wpa/features/notification/domain/entities/notification_entity.dart';
import 'package:test_wpa/features/notification/presentation/bloc/connection_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/notification/cards/notification_shared_widgets.dart';
import 'package:timeago/timeago.dart' as timeago;

// ═══════════════════════════════════════════════════════════════════════════
// Tab
// ═══════════════════════════════════════════════════════════════════════════

class FriendRequestsTab extends StatelessWidget {
  const FriendRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, notifState) {
        final acceptedNotifs = notifState is NotificationLoaded
            ? notifState.notifications
                  .where((n) => n.type == 'connection_accepted')
                  .toList()
            : <NotificationItem>[];

        return BlocConsumer<ConnectionBloc, ConnectionRequestState>(
          listener: (context, state) {
            final msg = switch (state) {
              ConnectionRequestActionSuccess(message: final m) => (
                m,
                Colors.green,
              ),
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
              acceptedNotifs,
            ),
            ConnectionRequestError(message: final msg) =>
              NotificationErrorState(
                message: msg,
                onRetry: () => ReadContext(
                  context,
                ).read<ConnectionBloc>().add(LoadConnectionRequests()),
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ConnectionRequest> pending,
    List<NotificationItem> accepted,
  ) {
    if (pending.isEmpty && accepted.isEmpty) {
      return const NotificationEmptyState(
        icon: Icons.people_outline,
        title: 'No Friend Requests',
        message: 'You don\'t have any pending\nfriend requests.',
      );
    }

    final unreadAccepted = accepted.where((n) => n.isUnread).length;
    return RefreshIndicator(
      onRefresh: () async {
        ReadContext(
          context,
        ).read<ConnectionBloc>().add(LoadConnectionRequests());
        ReadContext(context).read<NotificationBloc>().add(LoadNotifications());
      },
      child: Column(
        children: [
          _FriendRequestsHeader(unreadCount: unreadAccepted),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (accepted.isNotEmpty) ...[
                  const NotificationSectionLabel(
                    label: 'Accepted Your Request',
                  ),
                  ...accepted.map(
                    (n) => _AcceptedFriendCard(
                      notification: n,
                      onTap: () {
                        if (n.isUnread) {
                          ReadContext(context).read<NotificationBloc>().add(
                            MarkNotificationRead(n.id),
                          );
                        }
                      },
                    ),
                  ),
                  if (pending.isNotEmpty) const SizedBox(height: 8),
                ],
                if (pending.isNotEmpty) ...[
                  const NotificationSectionLabel(label: 'Pending Requests'),
                  ...pending.map(
                    (request) => _FriendRequestCard(
                      request: request,
                      onConfirm: () => ReadContext(context)
                          .read<ConnectionBloc>()
                          .add(AcceptConnectionRequest(request.id)),
                      onNotNow: () => ReadContext(context)
                          .read<ConnectionBloc>()
                          .add(RejectConnectionRequest(request.id)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

class _FriendRequestsHeader extends StatelessWidget {
  final int unreadCount;
  const _FriendRequestsHeader({required this.unreadCount});

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
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () => ReadContext(context)
                  .read<NotificationBloc>()
                  .add(MarkAllNotificationsRead(type: 'connection')),
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
// Accepted Friend Card
// ═══════════════════════════════════════════════════════════════════════════

class _AcceptedFriendCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _AcceptedFriendCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final person =
        notification.notifiable?.target ?? notification.notifiable?.requester;
    final avatarUrl = person?.avatarUrl ?? '';
    final name = person?.name ?? 'Someone';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      color: notification.isUnread
          ? color.AppColors.primary.withValues(alpha: 0.04)
          : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    backgroundColor: const Color(
                      0xFF4CAF50,
                    ).withValues(alpha: 0.15),
                    child: avatarUrl.isEmpty
                        ? Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: notification.isUnread
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: const Color(0xFF1A2340),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Accepted your friend request 🎉',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              if (notification.isUnread)
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
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pending Friend Request Card
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
        onTap: () => Modular.to.pushNamed('/other_profile/${request.senderId}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    backgroundColor: const Color(
                      0xFF4A90D9,
                    ).withValues(alpha: 0.15),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onNotNow,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: color.AppColors.warning,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: OutlinedButton.styleFrom(
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
