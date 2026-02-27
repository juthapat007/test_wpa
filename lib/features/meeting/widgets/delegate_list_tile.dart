import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';

class DelegateListTile extends StatelessWidget {
  final TableDelegate delegate;
  final String? tableNumber; // ถ้าไม่ส่งมา = ไม่แสดง trailing

  const DelegateListTile({super.key, required this.delegate, this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Modular.to.pushNamed(
        '/other_profile',
        arguments: {'delegate_id': delegate.delegateId},
      ),
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
  backgroundColor: color.AppColors.primary.withOpacity(0.1),
  foregroundImage: delegate.avatarUrl.isNotEmpty
      ? NetworkImage(delegate.avatarUrl)
      : null,
  onForegroundImageError: delegate.avatarUrl.isNotEmpty
      ? (_, __) {} // ← กัน exception ไม่ให้ throw
      : null,
  child: Text(
    delegate.delegateName.isNotEmpty
        ? delegate.delegateName[0].toUpperCase()
        : '?',
    style: const TextStyle(
      color: color.AppColors.primary,
      fontWeight: FontWeight.w600,
    ),
  ),
),
      title: Text(
        delegate.delegateName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (delegate.title?.isNotEmpty ?? false)
            Text(delegate.title!, style: const TextStyle(fontSize: 12)),
          Text(
            delegate.company,
            style: const TextStyle(
              fontSize: 12,
              color: color.AppColors.textSecondary,
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Table ${tableNumber}', // ✅ ใช้จาก table โดยตรง
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color.AppColors.primary,
          ),
        ),
      ),
    );
  }
}
