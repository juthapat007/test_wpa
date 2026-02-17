import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_bloc.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_event.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_state.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_status.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_row.dart';

class OtherProfilePage extends StatefulWidget {
  final int delegateId;
  const OtherProfilePage({super.key, required this.delegateId});

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Color(0xFF4A90D9),
            size: 32,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile Overview',
          style: TextStyle(
            color: Color(0xFF4A90D9),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE8ECF0), height: 1),
        ),
      ),
      body: BlocConsumer<ProfileDetailBloc, ProfileDetailState>(
        listener: (context, state) {
          if (state is FriendRequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is FriendRequestFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
            );
          }
          if (state is ProfileDetailError) {
            return _buildErrorView(context, state.message);
          }
          if (state is ProfileDetailLoaded || state is FriendRequestSending) {
            final profile = state is ProfileDetailLoaded ? state.profile : null;
            if (profile == null) return const Center(child: Text('No data'));
            final schedules = state is ProfileDetailLoaded
                ? state.schedules
                : null;

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildProfileCard(profile, context),
                  const SizedBox(height: 16),
                  if (schedules != null && schedules.isNotEmpty)
                    _buildEventSection(schedules),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ─────────────── Profile Card ───────────────
  Widget _buildProfileCard(ProfileDetail profile, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                _buildAvatar(profile),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2340),
                        ),
                      ),
                      if (profile.title != null &&
                          profile.title!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          profile.title!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        profile.companyName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A94A6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF8A94A6)),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F2F5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: _buildActionButtons(profile, context),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ProfileDetail profile) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 36,
        backgroundImage: profile.avatarUrl.isNotEmpty
            ? NetworkImage(profile.avatarUrl)
            : null,
        backgroundColor: const Color(0xFF4A90D9).withOpacity(0.15),
        child: profile.avatarUrl.isEmpty
            ? Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90D9),
                ),
              )
            : null,
      ),
    );
  }

  // ─────────────── Action Buttons ───────────────
  Widget _buildActionButtons(ProfileDetail profile, BuildContext context) {
    final isSending =
        context.watch<ProfileDetailBloc>().state is FriendRequestSending;

    return Row(
      children: [
        Expanded(child: _buildConnectButton(profile, context, isSending)),
        const SizedBox(width: 10),
        Expanded(
          child: _OutlineButton(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            color: profile.connectionStatus == ConnectionStatus.connected
                ? const Color(0xFF4A90D9)
                : const Color(0xFFBCC5D3),
            onTap: profile.connectionStatus == ConnectionStatus.connected
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat coming soon!')),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _FilledButton(label: 'Event Plan', color: Color(0xFF5DC98A)),
        ),
      ],
    );
  }

  Widget _buildConnectButton(
    ProfileDetail profile,
    BuildContext context,
    bool isSending,
  ) {
    switch (profile.connectionStatus) {
      case ConnectionStatus.none:
        return _OutlineButton(
          label: 'Add Friend',
          color: const Color(0xFF4A90D9),
          onTap: isSending
              ? null
              : () => context.read<ProfileDetailBloc>().add(
                  SendFriendRequest(profile.id),
                ),
        );
      case ConnectionStatus.requestedByMe:
        return const _OutlineButton(
          icon: Icons.access_time,
          label: 'Pending',
          color: Color(0xFF8A94A6),
        );
      case ConnectionStatus.requestedToMe:
        return Row(
          children: [
            Expanded(
              child: _FilledButton(
                label: 'Accept',
                color: const Color(0xFF5DC98A),
                onTap: () => context.read<ProfileDetailBloc>().add(
                  SendFriendRequest(profile.id),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _OutlineButton(
                label: 'Reject',
                color: const Color(0xFFE05454),
                onTap: () {},
              ),
            ),
          ],
        );
      case ConnectionStatus.connected:
        return const _OutlineButton(
          icon: Icons.check,
          label: 'Connected',
          color: Color(0xFF5DC98A),
        );
    }
  }

  // ─────────────── Event Section ───────────────
  Widget _buildEventSection(List<Schedule> schedules) {
    // group by date
    final Map<String, List<Schedule>> grouped = {};
    final dateKey = DateFormat('d MMMM yyyy');
    for (final s in schedules) {
      grouped.putIfAbsent(dateKey.format(s.startAt), () => []).add(s);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Event Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                  ),
                ),
              ],
            ),
          ),
          ...grouped.entries.map((e) => _buildDateGroup(e.key, e.value)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDateGroup(String dateLabel, List<Schedule> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A94A6),
            ),
          ),
        ),
        //เนี่ยแหละ row event แต่ละอัน — ใช้ TimelineRow เลย ไม่ต้องทำใหม่
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: items
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    // ✅ reuse TimelineRow เลย — same widget ที่ใช้ใน schedule page หลัก
                    child: TimelineRow(
                      schedule: s,
                      cardType: _toCardType(s),
                      // isSelectionMode: false  (default)
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  /// map Schedule.type → EventCardType
  /// logic ตรงกับ ScheduleCardHelper ทุกอย่าง
  EventCardType _toCardType(Schedule s) {
    switch (s.type) {
      case 'event':
        return EventCardType.breakTime; // amber card
      case 'nomeeting':
        return EventCardType.empty; // dashed card
      default:
        return EventCardType.meeting; // white card + status badge
    }
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<ProfileDetailBloc>().add(
              LoadProfileDetail(widget.delegateId),
            ),
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Button widgets ───────────────

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const _OutlineButton({
    required this.label,
    this.icon,
    this.color = const Color(0xFF4A90D9),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _FilledButton({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
