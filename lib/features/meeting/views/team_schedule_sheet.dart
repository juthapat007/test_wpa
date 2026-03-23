import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/notification/presentation/bloc/friends_cubit.dart';

class TeamScheduleSheet extends StatelessWidget {
  final TableViewResponse response;
  final int myDelegateId;

  const TeamScheduleSheet({
    super.key,
    required this.response,
    required this.myDelegateId,
  });

  @override
  Widget build(BuildContext context) {
    final meetingEntries = <({String tableNumber, TableMeeting meeting})>[];

    for (final table in response.tables) {
      for (final m in table.meetings) {
        meetingEntries.add((tableNumber: table.tableNumber, meeting: m));
      }
    }

    return BlocBuilder<FriendsCubit, FriendsState>(
      builder: (context, friendsState) {
        final friendIds = friendsState is FriendsLoaded
            ? friendsState.friends.map((f) => f.id).toSet()
            : <int>{};

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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${meetingEntries.length} meetings',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: meetingEntries.isEmpty
                    ? const Center(child: Text('No meetings assigned'))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        children: [
                          const Text(
                            'Meetings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...meetingEntries.map(
                            (e) => _buildMeetingCard(
                              e.meeting,
                              e.tableNumber,
                              friendIds,
                            ),
                          ),
                        ],
                      ),
              ),
              SizedBox(height: space_bottom.xl),
            ],
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  _FriendStatus _resolveStatus(int delegateId, Set<int> friendIds) {
    if (delegateId == myDelegateId) return _FriendStatus.self;
    if (friendIds.contains(delegateId)) return _FriendStatus.friend;
    return _FriendStatus.none;
  }
  //เช็ค connection

  // ─── Meeting Card ─────────────────────────────────────────────────────────

  Widget _buildMeetingCard(
    TableMeeting meeting,
    String tableNumber,
    Set<int> friendIds,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Table $tableNumber',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ─── Side A ───────────────────────────────────────────────
            // เปลี่ยนจาก single card เป็น loop members
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
                        status: _resolveStatus(entry.value.id, friendIds),
                        //เอาไว้เช็คความสัมพันธ์
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

            // ─── Side B ───────────────────────────────────────────────
            ...meeting.sideB.members.asMap().entries.map((entry) {
              final isLast = entry.key == meeting.sideB.members.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  // color: Colors.amber.withValues(alpha: 0.05),
                  color: const Color(0xFFFFFBEB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.amberAccent.shade100),
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
                        status: _resolveStatus(entry.value.id, friendIds),
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

  // ─── Side Row (ไม่มี GestureDetector — tap อยู่ที่ InkWell) ──────────────

  Widget _buildSideRow({
    required String avatarUrl,
    required String name,
    required String? title,
    required String company,
    required int delegateId,
    required _FriendStatus status,
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
              if (title != null && title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              Text(
                company,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _FriendStatusBadge(status: status),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
} // ← ปิด TeamScheduleSheet

// ─── Friend Status (อยู่นอก class ถูกต้อง) ───────────────────────────────────

enum _FriendStatus { self, friend, none }

class _FriendStatusBadge extends StatelessWidget {
  final _FriendStatus status;
  final bool mini;

  const _FriendStatusBadge({required this.status, this.mini = false});

  @override
  Widget build(BuildContext context) {
    if (status == _FriendStatus.none) return const SizedBox.shrink();

    final (icon, bg, fg, label) = switch (status) {
      _FriendStatus.self => (
        Icons.person,
        AppColors.primary,
        Colors.white,
        'You',
      ),
      _FriendStatus.friend => (
        Icons.people,
        AppColors.success,
        Colors.white,
        'Friends',
      ),
      _FriendStatus.none => (
        Icons.person_outline,
        AppColors.border,
        AppColors.textSecondary,
        '',
      ),
    };

    if (mini) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 10, color: fg),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: bg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: bg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
