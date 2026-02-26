// lib/features/meeting/widgets/table_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/widgets/delegate_list_tile.dart';

class TableDetailSheet extends StatelessWidget {
  final TableInfo table;
  final bool isMyTable;

  const TableDetailSheet({
    super.key,
    required this.table,
    required this.isMyTable,
  });
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          // ลบ mainAxisSize: MainAxisSize.min ออก (หรือเปลี่ยนเป็น max)
          children: [
            // Handle bar อยู่นอก scroll
            const SizedBox(height: 12),
            _buildHandle(),
            const SizedBox(height: 16),
            // ส่วนที่ scroll ได้
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // DelegateListTile(
                    //   delegate: delegate, // ✅ required
                    //   tableNumber: table.tableNumber,
                    // ),
                    _buildDelegatesList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: color.AppColors.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildDelegatesList() {
    if (table.delegates.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delegates (${table.delegates.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: table.delegates.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) => DelegateListTile(
            delegate: table.delegates[index], // ✅ ตรงนี้แหละที่ขาดไป
            tableNumber: table.tableNumber,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Table Available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
