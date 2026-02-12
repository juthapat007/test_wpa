import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/navigation/bottom_nav_config.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';

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
        final route = bottomNavItems[index].route;

        // ถ้ากดหน้าเดิมที่อยู่อยู่แล้ว ให้ popAndPushNamed เพื่อ refresh
        if (index == currentIndex) {
          Modular.to.popAndPushNamed(route);
        } else {
          Modular.to.navigate(route);
        }
      },
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      items: bottomNavItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        // 💬 ถ้าเป็น Chat tab ให้ wrap ด้วย Badge
        if (item.route == '/chat') {
          return BottomNavigationBarItem(
            icon: _buildChatIconWithBadge(context, item.icon),
            activeIcon: _buildChatIconWithBadge(
              context,
              item.icon,
              isActive: true,
            ),
            label: item.label,
          );
        }

        // ปกติ
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }

  Widget _buildChatIconWithBadge(
    BuildContext context,
    IconData icon, {
    bool isActive = false,
  }) {
    // ใช้ BlocBuilder จาก context โดยตรง (ChatBloc provide ที่ AppWidget level)
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        // ดึง unread count จาก ChatBloc internal state ผ่าน rooms
        final chatBloc = ModularWatchExtension(context).read<ChatBloc>();
        final totalUnread = chatBloc.totalUnreadCount;

        // ถ้าไม่มี unread แสดง icon ธรรมดา
        if (totalUnread == 0) {
          return Icon(icon);
        }

        // ถ้ามี unread แสดง badge
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon),
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    totalUnread > 99 ? '99+' : totalUnread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
