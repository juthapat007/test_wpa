// lib/features/other_profile/presentation/pages/other_profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_bloc.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_event.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_state.dart';
import 'package:test_wpa/features/schedules/domain/entities/schedule.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_event_card.dart';
import 'package:test_wpa/features/schedules/utils/schedule_card_helper.dart';
import 'package:test_wpa/features/widgets/app_button.dart';

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
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProfileDetailBloc, ProfileDetailState>(
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
          ),
          BlocListener<ChatBloc, ChatState>(
            listener: (context, state) {
              if (state is ChatRoomSelected) {
                Modular.to.pushNamed('/chat/room');
              } else if (state is ChatError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<ProfileDetailBloc, ProfileDetailState>(
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
              final profile = state is ProfileDetailLoaded
                  ? state.profile
                  : null;
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
                Expanded(child: _buildProfileInfo(profile)),
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

  Widget _buildProfileInfo(ProfileDetail profile) {
    return Column(
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
        if (profile.title != null && profile.title!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            profile.title!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          profile.companyName,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
        ),
      ],
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
        WatchContext(context).watch<ProfileDetailBloc>().state
            is FriendRequestSending;

    return Row(
      children: [
        Expanded(child: _buildConnectButton(profile, context, isSending)),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            text: 'Chat',
            backgroundColor: const Color(0xFF4A90D9),
            textColor: Colors.white,
            // onPressed: () {
            //   ReadContext(
            //     context,
            //   ).read<ChatBloc>().add(CreateChatRoom(profile.id.toString()),);
            // },
            onPressed: () {
              ReadContext(context).read<ChatBloc>().add(
                CreateChatRoom(profile.id.toString(), profile.name),
              );
            },
          ),
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
        return AppButton(
          text: 'Add Friend',
          backgroundColor: const Color(0xFF4A90D9),
          textColor: Colors.white,
          isLoading: isSending,
          onPressed: isSending
              ? null
              : () => ReadContext(
                  context,
                ).read<ProfileDetailBloc>().add(SendFriendRequest(profile.id)),
        );
      case ConnectionStatus.requestedByMe:
        return AppButton(
          text: 'Pending',
          backgroundColor: const Color(0xFF8A94A6),
          textColor: Colors.white,
          onPressed: null,
        );
      case ConnectionStatus.requestedToMe:
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Accept',
                backgroundColor: const Color(0xFF5DC98A),
                textColor: Colors.white,
                onPressed: () => ReadContext(
                  context,
                ).read<ProfileDetailBloc>().add(SendFriendRequest(profile.id)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: AppButton(
                text: 'Reject',
                backgroundColor: Colors.white,
                textColor: const Color(0xFFE05454),
                onPressed: () {},
              ),
            ),
          ],
        );
      case ConnectionStatus.connected:
        return AppButton(
          text: 'Connected',
          backgroundColor: const Color(0xFF5DC98A),
          textColor: Colors.white,
          onPressed: null,
        );
    }
  }

  // ─────────────── Event Section ───────────────
  Widget _buildEventSection(List<Schedule> schedules) {
    final grouped = _groupByDate(schedules);

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
            child: Text(
              'Event Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2340),
              ),
            ),
          ),
          ...grouped.entries.map((e) => _buildDateGroup(e.key, e.value)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Map<String, List<Schedule>> _groupByDate(List<Schedule> schedules) {
    final formatter = DateFormat('d MMMM yyyy');
    final grouped = <String, List<Schedule>>{};
    for (final s in schedules) {
      grouped.putIfAbsent(formatter.format(s.startAt), () => []).add(s);
    }
    return grouped;
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: items
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ScheduleEventCard(
                      schedule: s,
                      type: ScheduleCardHelper.resolveCardType(s),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
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
            onPressed: () => ReadContext(context).read<ProfileDetailBloc>().add(
              LoadProfileDetail(widget.delegateId),
            ),
            child: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }
}
