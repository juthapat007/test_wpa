// lib/features/search/widgets/delegate_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/features/search/domain/entities/delegate.dart';

class DelegateCard extends StatelessWidget {
  final Delegate delegate;

  const DelegateCard({super.key, required this.delegate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        onTap: () {
          Modular.to.pushNamed(
            '/other_profile',
            arguments: {'delegate_id': delegate.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar ────────────────────────────────────────────────
              CircleAvatar(
                radius: 26,
                backgroundImage: delegate.avatarUrl.isNotEmpty
                    ? NetworkImage(delegate.avatarUrl)
                    : null,
                backgroundColor: const Color(0xFF4A90D9).withOpacity(0.15),
                child: delegate.avatarUrl.isEmpty
                    ? Text(
                        delegate.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90D9),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // ── Name + title + company ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delegate.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340),
                      ),
                    ),
                    if (delegate.title.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        delegate.title,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      delegate.companyName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Connection status badge ────────────────────────────────
              _buildStatusBadge(delegate.connectionStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'connected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF5DC98A).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Connected',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5DC98A),
            ),
          ),
        );
      case 'requested_by_me':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        );
      case 'requested_to_me':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD4A843).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Respond',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD4A843),
            ),
          ),
        );
      default: // none
        return const Icon(
          Icons.chevron_right,
          color: Color(0xFF8A94A6),
          size: 20,
        );
    }
  }
}