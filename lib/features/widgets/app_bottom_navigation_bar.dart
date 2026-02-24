import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/navigation/bottom_nav_config.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/notification_bloc.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigationBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final validIndex = currentIndex >= 0 && currentIndex < bottomNavItems.length
        ? currentIndex
        : 0;

    return BottomNavigationBar(
      currentIndex: validIndex,
      onTap: (index) {
        Modular.to.navigate(bottomNavItems[index].route);
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      items: bottomNavItems.map((item) {
        // ─── Connection tab → badge จำนวน unread chat ───────────────────
        if (item.route == '/chat') {
          return BottomNavigationBarItem(
            icon: _ChatBadgeIcon(icon: item.icon, isActive: false),
            activeIcon: _ChatBadgeIcon(icon: item.icon, isActive: true),
            label: item.label,
          );
        }

        // ─── ไอคอนปกติ ────────────────────────────────────────────────
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }
}

// ─── Chat/Connection badge ───────────────────────────────────────────────────

class _ChatBadgeIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _ChatBadgeIcon({required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      // ✅ rebuild เฉพาะเมื่อ rooms เปลี่ยน (unread count อาจเปลี่ยน)
      buildWhen: (prev, curr) =>
          curr is ChatRoomsLoaded ||
          curr is ChatInitial ||
          curr is NewMessageReceived,
      builder: (context, state) {
        // ดึง total unread จาก ChatBloc
        int totalUnread = 0;
        try {
          totalUnread = ModularWatchExtension(
            context,
          ).read<ChatBloc>().totalUnreadCount;
        } catch (_) {}

        if (totalUnread == 0) return Icon(icon);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon),
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  totalUnread > 99 ? '99+' : totalUnread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Notification badge icon (ใช้ใน AppScaffold AppBar) ─────────────────────
//
// เรียกใช้แบบนี้ใน AppBar ของ AppScaffold:
//
//   actions: [
//     NotificationBellIcon(onTap: () => Modular.to.pushNamed('/notification')),
//   ]

class NotificationBellIcon extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationBellIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unread = 0;
        if (state is NotificationLoaded) unread = state.unreadCount;
        if (state is UnreadCountLoaded) unread = state.count;

        return IconButton(
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined),
              if (unread > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
