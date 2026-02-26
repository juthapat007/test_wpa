import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';

// ไม่ต้องเรียก API ใหม่เลย — รับ response จาก TableBloc โดยตรง
class TeamScheduleSheet extends StatelessWidget {
  final TableViewResponse response; // ✅ เปลี่ยนจาก date/time เป็น response

  const TeamScheduleSheet({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    // flatten ทุก table → delegate พร้อม table number
    final entries = <({String tableNumber, TableDelegate delegate})>[];
    for (final table in response.tables) {
      for (final delegate in table.delegates) {
        entries.add((tableNumber: table.tableNumber, delegate: delegate));
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Team at this slot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${entries.length} people',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No delegates assigned'))
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final e = entries[index];
                      return ListTile(
                        onTap: () => Modular.to.pushNamed(
                          // ✅ เพิ่มแค่นี้
                          '/other_profile',
                          arguments: {'delegate_id': e.delegate.delegateId},
                        ),
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: e.delegate.avatarUrl.isNotEmpty
                              ? NetworkImage(e.delegate.avatarUrl)
                              : null,
                          child: e.delegate.avatarUrl.isEmpty
                              ? Text(e.delegate.delegateName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(
                          e.delegate.delegateName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          e.delegate.company,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Table ${e.tableNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: space_bottom.xl),
        ],
      ),
    );
  }
}
