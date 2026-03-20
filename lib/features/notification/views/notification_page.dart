import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/connection_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:test_wpa/features/notification/views/tabs/friend_requests_tab.dart';
import 'package:test_wpa/features/notification/views/tabs/system_notifications_tab.dart';
import 'package:test_wpa/features/widgets/app_bar_back.dart';

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
    ReadContext(context).read<NotificationBloc>().add(LoadNotifications());
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
          _NotificationTabBar(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SystemNotificationsTab(),
                FriendRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab Bar + Badge dots
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationTabBar extends StatelessWidget {
  final TabController controller;
  const _NotificationTabBar({required this.controller});

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
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        onTap: (index) {
          if (index == 0) {
            ReadContext(context)
                .read<NotificationBloc>()
                .add(LoadNotifications());
          } else {
            ReadContext(context)
                .read<ConnectionBloc>()
                .add(LoadConnectionRequests());
          }
        },
        tabs: [
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

class _UnreadBadgeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        if (state is! NotificationLoaded) return const SizedBox.shrink();
        final hasUnread = state.notifications.any(
          (n) =>
              n.isUnread &&
              (n.type == 'admin_announce' || n.type == 'leave_reported'),
        );
        if (!hasUnread) return const SizedBox.shrink();
        return Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
              color: Colors.red, shape: BoxShape.circle),
        );
      },
    );
  }
}

class _PendingBadgeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionBloc, ConnectionRequestState>(
      builder: (context, connState) {
        return BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, notifState) {
            final hasPending = connState is ConnectionRequestLoaded &&
                connState.requests.any((r) => r.isPending);
            final hasAccepted = notifState is NotificationLoaded &&
                notifState.notifications
                    .any((n) => n.type == 'connection_accepted' && n.isUnread);
            if (!hasPending && !hasAccepted) return const SizedBox.shrink();
            return Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
            );
          },
        );
      },
    );
  }
}