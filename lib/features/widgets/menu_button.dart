import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';

class MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDanger;
  final VoidCallback onTap;

  const MenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isDanger
        ? Colors.red
        : isSelected
        ? Colors.blue
        : Colors.white;

    final Color foregroundColor = isDanger || isSelected
        ? Colors.white
        : Colors.black;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        // elevation: isDanger ? 6 : (isSelected ? 4 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          SizedBox(width: space.s),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
