import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_text.dart';
import 'package:test_wpa/features/search/domain/entities/delegate.dart';

class DelegateCard extends StatelessWidget {
  final Delegate delegate;

  const DelegateCard({super.key, required this.delegate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // ✅ ส่ง Delegate object ทั้งก้อนไปเลย
          Modular.to.pushNamed(
            '/someone_profile',
            arguments: {'delegate': delegate},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: delegate.avatarUrl.isNotEmpty
                ? NetworkImage(delegate.avatarUrl)
                : null,
            child: delegate.avatarUrl.isEmpty
                ? Text(
                    delegate.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 20),
                  )
                : null,
          ),
          title: Text(
            delegate.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ title เป็น String (non-nullable) ตามที่ entity กำหนด
              if (delegate.title.isNotEmpty)
                Text(delegate.title, style: TextStyle(color: Colors.grey[600])),
              AppText(delegate.companyName),
              Row(
                children: [
                  const Icon(Icons.email, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      delegate.email,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}
