import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';

class AddButtonOutline extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const AddButtonOutline({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.color = Colors.blue, // default color
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(vertical: space.m),
    required bool isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding,
        ),
      ),
    );
  }
}
