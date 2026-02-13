// lib/features/meeting/widgets/table_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';

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
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              const SizedBox(height: 20),
              _buildTableHeader(),
              const SizedBox(height: 24),
              _buildDelegatesList(),
            ],
          ),
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
          color: color.AppColors.surface,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMyTable ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.table_restaurant,
            color: isMyTable ? Colors.white : Colors.grey[700],
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table ${table.tableNumber}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isMyTable)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.AppColors.info,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Your Table',
                    style: TextStyle(
                      fontSize: 12,
                      color: color.AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDelegatesList() {
    if (table.delegates.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delegates (${table.delegates.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...table.delegates.map(_buildDelegateCard),
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

  Widget _buildDelegateCard(TableDelegate delegate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: delegate.avatarUrl.isNotEmpty
              ? NetworkImage(delegate.avatarUrl)
              : null,
          onBackgroundImageError: (_, _) {},
          child: delegate.avatarUrl.isEmpty
              ? Text(
                  delegate.delegateName.isNotEmpty
                      ? delegate.delegateName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          delegate.delegateName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (delegate.title?.isNotEmpty ?? false)
              Text(delegate.title!, style: const TextStyle(fontSize: 12)),
            Text(
              delegate.company,
              style: TextStyle(color: Colors.blue[700], fontSize: 13),
            ),
          ],
        ),
        isThreeLine: delegate.title?.isNotEmpty ?? false,
      ),
    );
  }
}
