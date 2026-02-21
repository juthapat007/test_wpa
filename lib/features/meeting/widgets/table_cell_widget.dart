import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/widgets/table_detail_sheet.dart';

class TableCellWidget extends StatelessWidget {
  final TableInfo table;
  final bool isMyTable;
  final bool isSelected;
  final bool isOnLeave;
  final VoidCallback onTap;

  const TableCellWidget({
    super.key,
    required this.table,
    required this.isMyTable,
    required this.isSelected,
    required this.onTap,
    this.isOnLeave = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(
      isMyTable,
      isSelected,
      table.isOccupied,
      isOnLeave,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.border,
            width: isMyTable || isSelected ? 2 : 1,
          ),
          boxShadow: isMyTable || isSelected
              ? [
                  BoxShadow(
                    color: colors.border.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.tableNumber,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 2),
            if (isOnLeave)
              Icon(Icons.event_busy, size: 12, color: colors.text)
            else if (isMyTable)
              Icon(Icons.person_pin, size: 14, color: colors.text)
            else if (table.isOccupied)
              Icon(Icons.people, size: 12, color: colors.text),
          ],
        ),
      ),
    );
  }

  _TableCellColors _getColors(
    bool isMyTable,
    bool isSelected,
    bool isOccupied,
    bool isOnLeave,
  ) {
    if (isOnLeave) {
      return _TableCellColors(
        background: AppColors.error.withOpacity(0.08),
        border: AppColors.error,
        text: AppColors.error,
      );
    }
    if (isMyTable) {
      return _TableCellColors(
        background: AppColors.primary,
        border: AppColors.primaryDark,
        text: AppColors.textOnPrimary,
      );
    }
    if (isSelected) {
      return _TableCellColors(
        background: AppColors.warning,
        border: const Color(0xFFB45309), // amber-700
        text: AppColors.textOnPrimary,
      );
    }
    if (isOccupied) {
      return _TableCellColors(
        background: const Color(0xFFF0FDF4), // green-50
        border: AppColors.success,
        text: const Color(0xFF14532D), // green-900
      );
    }
    return _TableCellColors(
      background: Colors.white,
      border: AppColors.border,
      text: AppColors.textPrimary,
    );
  }
}

class EmptyTableCell extends StatelessWidget {
  final String tableNumber;

  const EmptyTableCell({super.key, required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // grey-100
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          tableNumber,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9CA3AF), // grey-400
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

class _TableCellColors {
  final Color background;
  final Color border;
  final Color text;
  const _TableCellColors({
    required this.background,
    required this.border,
    required this.text,
  });
}
