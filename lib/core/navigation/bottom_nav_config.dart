import 'package:flutter/material.dart';
import 'bottom_nav_item.dart';

const List<BottomNavItem> bottomNavItems = [
  BottomNavItem(label: 'meeting', icon: Icons.event_seat, route: '/meeting'),
  BottomNavItem(label: 'search', icon: Icons.search, route: '/search'),
  BottomNavItem(label: 'scan', icon: Icons.qr_code_scanner, route: '/scan'),
  BottomNavItem(label: 'chat', icon: Icons.chat_bubble, route: '/chat'),
  BottomNavItem(label: 'schedule', icon: Icons.event_sharp, route: '/schedule'),
];
//แทนที่จะใช้ switch case เปลี่ยนมาใช้เป็น tap และลำดับแทน
