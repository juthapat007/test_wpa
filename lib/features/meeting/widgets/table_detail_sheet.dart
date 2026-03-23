import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart' as color;
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';

class TableDetailSheet extends StatelessWidget {
  final TableInfo table;
  final bool isMyTable;
  final String meetingsSectionTitle;
  final int myDelegateId;

  const TableDetailSheet({
    super.key,
    required this.table,
    required this.isMyTable,
    this.meetingsSectionTitle = 'Meeting',
    this.myDelegateId = 0,
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
                  children: [const SizedBox(height: 8), _buildDelegatesList()],
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
          // ─── Booth header ──────────────────────────────────────────
          if (table.isBooth && table.boothOwner != null) ...[
            Row(
              children: [
                const Icon(Icons.store, size: 18, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        table.tableNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Owned by: ${table.boothOwner!.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            Text(
              meetingsSectionTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],

          // ─── Meeting cards ─────────────────────────────────────────
          ...table.meetings.map(
            (m) => table.isBooth
                ? _buildBoothMeetingCard(m)
                : _buildNormalMeetingCard(m),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  // ─── Booth Meeting Card ───────────────────────────────────────────────────

  Widget _buildBoothMeetingCard(TableMeeting meeting) {
    final isHosting = meeting.meetingRole == MeetingRole.ownerHosting;
    final isReceiving = meeting.meetingRole == MeetingRole.ownerAsTarget;

    final Color roleColor = isHosting
        ? Colors.green[700]!
        : isReceiving
        ? Colors.blue[700]!
        : Colors.grey[600]!;

    // final String roleLabel = isHosting
    //     ? 'Hosting Guest'
    //     : isReceiving
    //     ? 'Receiving Visitor'
    //     : 'Meeting';

    final bool ownerIsSideA = isHosting
        ? meeting.bookerIsOwner
        : meeting.targetIsOwner;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role badge
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            //   decoration: BoxDecoration(
            //     color: roleColor.withValues(alpha: 0.1),
            //     borderRadius: BorderRadius.circular(8),
            //     border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            //   ),
            //   child: Text(
            //     roleLabel,
            //     style: TextStyle(
            //       fontSize: 12,
            //       fontWeight: FontWeight.w700,
            //       color: roleColor,
            //     ),
            //   ),
            // ),
            const SizedBox(height: 10),

            // ─── Owner side ────────────────────────────────────────────
            _buildBoothSideLabel(
              label: 'Owner',
              company: meeting.ownerCompany ?? '',
              color: Colors.purple,
            ),
            const SizedBox(height: 6),

            if (isHosting) ...[
              ...meeting.sideA.members.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildPersonCard(
                    avatarUrl: m.avatarUrl,
                    name: m.name,
                    title: m.title,
                    company: meeting.sideA.company,
                    delegateId: m.id,
                    bgColor: const Color(0xFFF5F3FF),
                    borderColor: Colors.purple.shade100,
                  ),
                ),
              ),
            ] else ...[
              // owner_as_target → sideB (target) คือ owner
              ...meeting.sideB.members.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildPersonCard(
                    avatarUrl: m.avatarUrl,
                    name: m.name,
                    title: m.title,
                    company: meeting.sideB.company,
                    delegateId: m.id,
                    bgColor: const Color(0xFFF5F3FF),
                    borderColor: Colors.purple.shade100,
                  ),
                ),
              ),
            ],

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      isHosting ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 14,
                      color: roleColor,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),

            // ─── Guest/Visitor side ────────────────────────────────────
            _buildBoothSideLabel(
              label: isHosting ? 'Guest' : 'Visitor',
              company: meeting.guestCompany ?? '',
              color: isHosting ? Colors.green[700]! : Colors.blue[700]!,
            ),
            const SizedBox(height: 6),
            if (isHosting) ...[
              ...meeting.sideA.members.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildPersonCard(
                    avatarUrl: m.avatarUrl,
                    name: m.name,
                    title: m.title,
                    company: meeting.sideA.company,
                    delegateId: m.id,
                    bgColor: const Color(0xFFF5F3FF),
                    borderColor: Colors.purple.shade100,
                  ),
                ),
              ),
            ] else ...[
              ...meeting.sideA.members.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildPersonCard(
                    avatarUrl: m.avatarUrl,
                    name: m.name,
                    title: m.title,
                    company: meeting.sideA.company,
                    delegateId: m.id,
                    bgColor: const Color(0xFFF0F9FF),
                    borderColor: Colors.blue.shade100,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBoothSideLabel({
    required String label,
    required String company,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        if (company.isNotEmpty) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              company,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPersonCard({
    required String avatarUrl,
    required String name,
    required String? title,
    required String company,
    required int delegateId,
    required Color bgColor,
    required Color borderColor,
  }) {
    final isMe = delegateId == myDelegateId;
    return Card(
      margin: EdgeInsets.zero,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: isMe
            ? null
            : () => Modular.to.pushNamed(
                '/other_profile',
                arguments: {'delegate_id': delegateId},
              ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _buildSideRow(
            avatarUrl: avatarUrl,
            name: name,
            title: title,
            company: company,
            delegateId: delegateId,
          ),
        ),
      ),
    );
  }

  // ─── Normal Meeting Card (ไม่ใช่ booth) ──────────────────────────────────

  Widget _buildNormalMeetingCard(TableMeeting meeting) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Side A (loop members) ─────────────────────────────────
            ...meeting.sideA.members.asMap().entries.map((entry) {
              final isLast = entry.key == meeting.sideA.members.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  color: const Color(0xFFF0F9FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.blue.shade100),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () {
                      if (entry.value.id == myDelegateId) return;
                      Modular.to.pushNamed(
                        '/other_profile',
                        arguments: {'delegate_id': entry.value.id},
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _buildSideRow(
                        avatarUrl: entry.value.avatarUrl,
                        name: entry.value.name,
                        title: entry.value.title,
                        company: meeting.sideA.company,
                        delegateId: entry.value.id,
                      ),
                    ),
                  ),
                ),
              );
            }),
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            // ─── Side B (loop members) ─────────────────────────────────
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
                    onTap: () {
                      if (entry.value.id == myDelegateId) return;
                      Modular.to.pushNamed(
                        '/other_profile',
                        arguments: {'delegate_id': entry.value.id},
                      );
                    },
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
  // ─── Side Row ─────────────────────────────────────────────────────────────

  Widget _buildSideRow({
    required String avatarUrl,
    required String name,
    required String? title,
    required String company,
    required int delegateId,
  }) {
    final isMe = delegateId == myDelegateId;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (isMe)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                company,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              if (title != null && title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (!isMe)
          const Icon(
            Icons.chevron_right,
            size: 16,
            color: AppColors.textSecondary,
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
