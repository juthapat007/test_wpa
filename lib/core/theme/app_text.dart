import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const AppText(
    this.text, {
    super.key,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
    );
  }
}
