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
    // ─── Flatten people จาก delegates + meetings ──────────────────────────
    final peopleEntries =
        <
          ({
            String tableNumber,
            int delegateId,
            String name,
            String subtitle,
            String avatarUrl,
          })
        >[];

    final meetingEntries = <({String tableNumber, TableMeeting meeting})>[];

    for (final table in response.tables) {
      for (final d in table.delegates) {
        peopleEntries.add((
          tableNumber: table.tableNumber,
          delegateId: d.delegateId,
          name: d.delegateName,
          subtitle: d.title ?? d.company,
          avatarUrl: d.avatarUrl,
        ));
      }
      for (final m in table.meetings) {
        meetingEntries.add((tableNumber: table.tableNumber, meeting: m));
        peopleEntries.add((
          tableNumber: table.tableNumber,
          delegateId: m.sideA.delegateId,
          name: m.sideA.name,
          subtitle: m.sideA.title ?? m.sideA.company,
          avatarUrl: m.sideA.avatarUrl,
        ));
        for (final member in m.sideB.members) {
          peopleEntries.add((
            tableNumber: table.tableNumber,
            delegateId: member.id,
            name: member.name,
            subtitle: m.sideB.company,
            avatarUrl: member.avatarUrl,
          ));
        }
      }
    }

    // ─── กัน duplicate ────────────────────────────────────────────────────
    final seen = <int>{};
    final uniquePeople = peopleEntries
        .where((e) => seen.add(e.delegateId))
        .toList();

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
                      '${uniquePeople.length} people',
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
                child: uniquePeople.isEmpty && meetingEntries.isEmpty
                    ? const Center(child: Text('No delegates assigned'))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
                        children: [
                          // ─── People Section ───────────────────────

                          // ─── Meetings Section ─────────────────────
                          if (meetingEntries.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Meetings',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...meetingEntries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: _buildMeetingCard(
                                  e.meeting,
                                  e.tableNumber,
                                  friendIds,
                                ),
                              ),
                            ),
                          ],
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
            _buildSideRow(
              avatarUrl: meeting.sideA.avatarUrl,
              name: meeting.sideA.name,
              subtitle: meeting.sideA.title ?? meeting.sideA.company,
              delegateId: meeting.sideA.delegateId,
              status: _resolveStatus(meeting.sideA.delegateId, friendIds),
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
            ...meeting.sideB.members.asMap().entries.map((entry) {
              final isLast = entry.key == meeting.sideB.members.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: _buildSideRow(
                  avatarUrl: entry.value.avatarUrl,
                  name: entry.value.name,
                  subtitle: meeting.sideB.company,
                  delegateId: entry.value.id,
                  status: _resolveStatus(entry.value.id, friendIds),
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
    required String subtitle,
    required int delegateId,
    required _FriendStatus status,
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
      ),
    );
  }
}

// ─── Friend Status ────────────────────────────────────────────────────────────

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
