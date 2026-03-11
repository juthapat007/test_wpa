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
  final String meetingsSectionTitle;

  const TableDetailSheet({
    super.key,
    required this.table,
    required this.isMyTable,
    this.meetingsSectionTitle = 'Meeting',
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
          children: [
            const SizedBox(height: 12),
            _buildHandle(),
            const SizedBox(height: 16),
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
          color: color.AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildDelegatesList() {
    if (table.delegates.isEmpty && table.meetings.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (table.meetings.isNotEmpty) ...[
          Text(
            meetingsSectionTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...table.meetings.map((m) => _buildMeetingCard(m)),
          const SizedBox(height: 20),
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
            // ─── Side A ───────────────────────────────────────────────
            Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFFF0F9FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () => Modular.to.pushNamed(
                  '/other_profile',
                  arguments: {'delegate_id': meeting.sideA.delegateId},
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _buildSideRow(
                    avatarUrl: meeting.sideA.avatarUrl,
                    name: meeting.sideA.name,
                    title: meeting.sideA.title,
                    company: meeting.sideA.company,
                    delegateId: meeting.sideA.delegateId,
                  ),
                ),
              ),
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

            // ─── Side B members ───────────────────────────────────────
            ...meeting.sideB.members.asMap().entries.map((entry) {
              final isLast = entry.key == meeting.sideB.members.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  color: const Color(0xFFF0FDF4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.green.shade100),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () => Modular.to.pushNamed(
                      '/other_profile',
                      arguments: {'delegate_id': entry.value.id},
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _buildSideRow(
                        avatarUrl: entry.value.avatarUrl,
                        name: entry.value.name,
                        title: entry.value.title,
                        company: meeting.sideB.company,
                        delegateId: entry.value.id,
                      ),
                    ),
                  ),
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
    required String? title,
    required String company,
    required int delegateId,
  }) {
    return Row(
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
                  fontSize: 16,
                ),
              ),
              Text(
                company,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color.AppColors.textSecondary,
                ),
              ),
              if (title != null && title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
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
