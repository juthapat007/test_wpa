import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/widgets/app_button.dart';

class BottomActionBar extends StatelessWidget {
  final String cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isLoading;

  const BottomActionBar({
    super.key,
    this.cancelText = 'Cancel',
    this.confirmText = 'Confirm',
    required this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: space.m,
        right: space.m,
        top: space.xs, // ✅ ระยะด้านบน
        bottom: 100, // ✅ ระยะด้านล่าง
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2), // ✅ เงาด้านบน
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: cancelText,
                backgroundColor: color.AppColors.background,

                textColor: color.AppColors.textPrimary,
                onPressed: isLoading ? null : onCancel,
              ),
            ),
            SizedBox(width: space.xs),
            Expanded(
              child: AppButton(
                text: isLoading ? 'Submitting...' : confirmText,
                backgroundColor: color.AppColors.primary,
                textColor: color.AppColors.textOnPrimary,
                onPressed: isLoading ? null : onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
