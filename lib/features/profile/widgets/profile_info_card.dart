import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;

class ProfileInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showBorder;
  final Widget? trailing;
  final bool iconEdit;

  const ProfileInfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.showBorder = true,
    this.trailing,
    this.iconEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: color.AppColors.textPrimary,

                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (iconEdit) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
