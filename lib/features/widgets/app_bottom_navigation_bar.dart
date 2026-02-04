import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/navigation/bottom_nav_config.dart';
import 'package:test_wpa/core/theme/app_colors.dart';

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
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      items: bottomNavItems
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
