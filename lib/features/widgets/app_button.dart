import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double width;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,

    this.textColor,
    this.borderRadius = 12,
    this.width = double.infinity,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    return SizedBox(
      height: height.m,
      width: width,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor?.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? const Color.fromARGB(255, 150, 134, 134),
                  ),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
