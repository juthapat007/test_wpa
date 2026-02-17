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

    // ✅ Wrap ด้วย Container เพื่อเพิ่ม BoxShadow แบบ BottomActionBar
    return Container(
      //
      child: BottomNavigationBar(
        //BottomNavigationBar ทำงานเมื่อเปลี่ยนหน้า โดยใช้ currentIndex เพื่อเลือกหน้าที่ต้องการ และ
        currentIndex: validIndex,
        onTap: (index) {
          final route = bottomNavItems[index].route;

          // ✅ ถ้ากดหน้า chat ให้ reload rooms ก่อน navigate
          if (route == '/chat') {
            try {
              ModularWatchExtension(
                context,
              ).read<ChatBloc>().add(LoadChatRooms());
            } catch (e) {
              print('ChatBloc not found: $e');
            }
          }

          // ✅ Force refresh ทุกหน้า เพื่อให้ state reset
          Modular.to.navigate(route);

          // ✅ ถ้ากดหน้าเดิม ให้ pop แล้ว push ใหม่เพื่อ rebuild
          if (index == currentIndex) {
            // Delay เล็กน้อยเพื่อให้ navigate เสร็จก่อน
            Future.delayed(const Duration(milliseconds: 50), () {
              Modular.to.navigate(route);
            });
          }
        },
        backgroundColor:
            Colors.transparent, // ✅ ใช้สีโปร่งใส เพราะมี Container ครอบแล้ว
        elevation: 0, // ✅ ปิด elevation เดิมเพราะใช้ BoxShadow แทน
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
            icon: Padding(
              padding: const EdgeInsets.all(8.0), // ✅ เพิ่ม padding รอบๆ
              child: Icon(item.icon),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.all(8.0), // ✅ เพิ่ม padding รอบๆ
              child: Icon(item.icon),
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatIconWithBadge(
    BuildContext context,
    IconData icon, {
    bool isActive = false,
  }) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final chatBloc = ModularWatchExtension(context).read<ChatBloc>();
        final totalUnread = chatBloc.totalUnreadCount;

        if (totalUnread == 0) {
          return Icon(icon);
        }

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
