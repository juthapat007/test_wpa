// lib/features/meeting/widgets/table_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
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
                  children: [const SizedBox(height: 24), _buildDelegatesList()],
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
        // ✅ แสดง meetings ถ้ามี
        if (table.meetings.isNotEmpty) ...[
          const Text(
            'Meetings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...table.meetings.map((m) => _buildMeetingCard(m)),
          const SizedBox(height: 20),
        ],
        // delegates เดิม
        if (table.delegates.isNotEmpty) ...[
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
              delegate: table.delegates[index],
              tableNumber: table.tableNumber,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMeetingCard(TableMeeting meeting) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSideRow(
              avatarUrl: meeting.sideA.avatarUrl,
              name: meeting.sideA.name,
              subtitle: meeting.sideA.title ?? meeting.sideA.company,
              delegateId: meeting.sideA.delegateId,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.swap_vert,
                      size: 16,
                      color: color.AppColors.textSecondary,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            ...meeting.sideB.members.asMap().entries.map((entry) {
              final isLast = entry.key == meeting.sideB.members.length - 1;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: isLast ? 0 : 8,
                ), // ✅ ไม่เว้นหลังตัวสุดท้าย
                child: _buildSideRow(
                  avatarUrl: entry.value.avatarUrl,
                  name: entry.value.name,
                  subtitle: meeting.sideB.company,
                  delegateId: entry.value.id,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSideRow({
    required String avatarUrl,
    required String name,
    required String subtitle,
    required int delegateId,
  }) {
    return GestureDetector(
      onTap: () => Modular.to.pushNamed(
        '/other_profile',
        arguments: {'delegate_id': delegateId},
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            foregroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: color.AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 16,
            color: color.AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
        ],
      ),
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
