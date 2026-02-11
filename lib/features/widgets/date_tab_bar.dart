import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/core/theme/app_colors.dart';

/// Horizontal scrollable date tab bar
/// built from available_dates returned by the API.
class DateTabBar extends StatelessWidget {
  final List<String> availableDates; // e.g. ["2025-10-12", "2025-10-13", ...]
  final String selectedDate; // e.g. "2025-10-13"
  final ValueChanged<String> onDateSelected;

  const DateTabBar({
    super.key,
    required this.availableDates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (availableDates.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conference date label
          _buildConferenceLabel(),
          const SizedBox(height: 12),
          // Date chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableDates.map((dateStr) {
                final isSelected = dateStr == selectedDate;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _DateChip(
                    dateString: dateStr,
                    isSelected: isSelected,
                    onTap: () => onDateSelected(dateStr),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConferenceLabel() {
    // Show the full selected date
    final parsed = DateTime.tryParse(selectedDate);
    final display = parsed != null
        ? DateFormat('EEEE, d MMMM yyyy').format(parsed)
        : selectedDate;

    return Text(
      display,
      style: const TextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String dateString;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.dateString,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(dateString);
    final dayName = parsed != null ? DateFormat('EEE').format(parsed) : '?';
    final dayNum = parsed != null ? DateFormat('d').format(parsed) : '?';
    final month = parsed != null ? DateFormat('MMM').format(parsed) : '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayName.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNum,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              month.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
