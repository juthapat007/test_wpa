// lib/features/widgets/app_dialog.dart

import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/widgets/app_button.dart';

class AppDialogAction {
  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.textColor,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? textColor;
  final Color? backgroundColor;
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    required this.description,
    required this.actions,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String description;
  final List<AppDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            actions.length == 1
                ? _buildSingleButton(actions.first)
                : _buildButtonRow(actions),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleButton(AppDialogAction action) {
    return SizedBox(width: double.infinity, child: _buildButton(action));
  }

  Widget _buildButtonRow(List<AppDialogAction> actions) {
    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          Expanded(child: _buildButton(actions[i])),
          if (i < actions.length - 1) SizedBox(width: space.xs),
        ],
      ],
    );
  }

  Widget _buildButton(AppDialogAction action) {
    return AppButton(
      text: action.label,
      backgroundColor:
          action.backgroundColor ??
          (action.isPrimary ? AppColors.primary : Colors.transparent),
      textColor: action.isPrimary
          ? AppColors.textOnPrimary
          : (action.textColor ?? AppColors.primary),
      onPressed: action.onPressed,
    );
  }
}

// Extension ช่วย insert widget ระหว่าง item ใน list
extension _ListInsert<T> on List<T> {
  void insertBetween(T separator) {
    for (var i = length - 1; i > 0; i--) {
      insert(i, separator);
    }
  }
}
