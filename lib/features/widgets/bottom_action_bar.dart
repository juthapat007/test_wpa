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
      color: Colors.white, // ✅ ต้องอยู่นอกสุดให้ background เต็มจอ
      child: SafeArea(
        top: false,
        bottom: false, // ✅ ปิด SafeArea ด้านล่าง
        child: Container(
          padding: EdgeInsets.only(
            left: space.m,
            right: space.m,
            top: space.xs,
            bottom:
                space_bottom.xl +
                MediaQuery.of(
                  context,
                ).padding.bottom, // ✅ บวก system inset เข้าไปด้วย
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
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
              const SizedBox(width: space.xs),
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
      ),
    );
  }
}
