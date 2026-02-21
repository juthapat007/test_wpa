import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart';

class TableLegend extends StatelessWidget {
  final bool showLeave;

  const TableLegend({super.key, this.showLeave = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const _LegendItem(color: AppColors.primary, label: 'Your Table'),
        const _LegendItem(
          color: Color(0xFFF0FDF4),
          label: 'Occupied',
          borderColor: AppColors.success,
        ),
        const _LegendItem(color: Colors.white, label: 'Available'),
        if (showLeave)
          _LegendItem(
            color: AppColors.error.withOpacity(0.08),
            borderColor: AppColors.error,
            label: 'On Leave',
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor ?? AppColors.border),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
