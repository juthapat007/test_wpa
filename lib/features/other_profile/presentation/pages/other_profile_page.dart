import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/other_profile/domain/entities/profile_detail.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_bloc.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_event.dart';
import 'package:test_wpa/features/other_profile/presentation/bloc/profile_detail_state.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/schedule_event_card.dart';
import 'package:test_wpa/features/schedules/presentation/widgets/timeline_row.dart';
import 'package:test_wpa/features/schedules/utils/schedule_card_helper.dart';
import 'package:test_wpa/features/widgets/add_button_outline.dart';
import 'package:test_wpa/features/widgets/app_bar_back.dart';
import 'package:test_wpa/features/widgets/app_button.dart';
import 'package:test_wpa/features/widgets/app_dialog.dart';
import 'package:test_wpa/features/widgets/date_tab_bar.dart';

class OtherProfilePage extends StatefulWidget {
  final int delegateId;
  const OtherProfilePage({super.key, required this.delegateId});

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  ProfileDetailLoaded? _lastLoaded;
  static const double timelineOffset = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarBack(title: 'Profile Overview'),

      body: MultiBlocListener(
        listeners: [
          BlocListener<ProfileDetailBloc, ProfileDetailState>(
            listener: _onProfileStateChanged,
          ),
          BlocListener<ChatBloc, ChatState>(listener: _onChatStateChanged),
        ],
        child: BlocBuilder<ProfileDetailBloc, ProfileDetailState>(
          builder: (context, state) {
            if (state is ProfileDetailLoaded) _lastLoaded = state;
            final loaded = _lastLoaded;

            if (state is ProfileDetailLoading && loaded == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
              );
            }
            if (state is ProfileDetailError && loaded == null) {
              return _buildErrorView(context, state.message);
            }
            if (loaded == null)
              return const Center(child: CircularProgressIndicator());

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildProfileCard(
                    loaded.profile,
                    context,
                    state is FriendRequestSending,
                  ),
                  const SizedBox(height: 16),
                  _buildEventSection(loaded, context),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Listeners ────────────────────────────────────────────────────────────

  void _onProfileStateChanged(BuildContext context, ProfileDetailState state) {
    if (state is ProfileDetailLoaded) {
      _lastLoaded = state;
    } else if (state is FriendRequestSuccess) {
      showDialog(
        context: context,
        builder: (_) => AppDialog(
          icon: Icons.check_circle_outline,
          iconColor: const Color(0xFF5DC98A),
          title: 'Success',
          description: state.message,
          actions: [
            AppDialogAction(
              label: 'OK',
              isPrimary: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else if (state is FriendRequestFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onChatStateChanged(BuildContext context, ChatState state) {
    if (state is ChatRoomSelected) {
      Modular.to.pushNamed('/chat/room');
    } else if (state is ChatError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  // ─── Profile Card ─────────────────────────────────────────────────────────

  Widget _buildProfileCard(
    ProfileDetail profile,
    BuildContext context,
    bool isSending,
  ) {
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
                if (profile.connectionStatus == ConnectionStatus.connected)
                  _buildMoreMenu(profile, context),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F2F5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: _buildActionButtons(profile, context, isSending),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSection(ProfileDetailLoaded state, BuildContext context) {
    if (state.isScheduleLoading && state.availableDates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.availableDates.isEmpty) return const SizedBox.shrink();

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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Event Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2340),
              ),
            ),
          ),
          DateTabBar(
            availableDates: state.availableDates,
            selectedDate: state.selectedDate,
            onDateSelected: (date) => ReadContext(context)
                .read<ProfileDetailBloc>()
                .add(LoadScheduleOthers(widget.delegateId, date: date)),
          ),
          if (state.isScheduleLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.schedules?.isEmpty ?? true)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No events on this day',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Stack(
                children: [
                  // Timeline vertical line
                  Positioned(
                    left: timelineOffset,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 1, color: Colors.grey[200]),
                  ),
                  Column(
                    children: state.schedules!
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TimelineRow(
                              schedule: s,
                              cardType: ScheduleCardHelper.resolveCardType(s),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons(
    ProfileDetail profile,
    BuildContext context,
    bool isSending,
  ) {
    return Row(
      children: [
        Expanded(child: _buildConnectButton(profile, context, isSending)),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            text: 'Chat',
            backgroundColor: const Color(0xFF4A90D9),
            textColor: Colors.white,
            onPressed: () => ReadContext(context).read<ChatBloc>().add(
              CreateChatRoom(profile.id.toString(), profile.name),
            ),
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
          text: isSending ? 'Cancelling...' : 'Requested',
          backgroundColor: const Color(0xFFFF9800),
          textColor: Colors.white,
          isLoading: isSending,
          onPressed: isSending
              ? null
              : () => _showCancelRequestDialog(context, profile),
        );

      case ConnectionStatus.requestedToMe:
        final requestId = profile.connectionRequestId;
        if (requestId == null) {
          return AppButton(
            text: 'Loading...',
            backgroundColor: Colors.grey[300]!,
            textColor: Colors.grey,
            onPressed: null,
          );
        }
        return Row(
          children: [
            Expanded(
              //ค่อยมาแก้
              child: AddButtonOutline(
                text: 'Accept',
                icon: Icons.check,
                color: AppColors.primary,
                isLoading: isSending,
                onPressed: isSending
                    ? null
                    : () => ReadContext(context).read<ProfileDetailBloc>().add(
                        AcceptFriendRequest(requestId),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: AddButtonOutline(
                text: 'Reject',
                icon: Icons.close,
                color: AppColors.warning,

                isLoading: isSending,
                onPressed: isSending
                    ? null
                    : () => ReadContext(context).read<ProfileDetailBloc>().add(
                        RejectFriendRequest(requestId),
                      ),
              ),
            ),
          ],
        );

      case ConnectionStatus.connected:
        return AppButton(
          text: 'Connected ✓',
          backgroundColor: const Color(0xFF5DC98A),
          textColor: Colors.white,
          onPressed: null,
        );
    }
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  void _showUnfriendDialog(BuildContext context, ProfileDetail profile) {
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        icon: Icons.person_remove_outlined,
        iconColor: const Color(0xFFE05454),
        title: 'Unfriend',
        description: 'Remove ${profile.name} from your connections?',
        actions: [
          AppDialogAction(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppDialogAction(
            label: 'Unfriend',
            isPrimary: true,
            backgroundColor: const Color(0xFFE05454),
            onPressed: () {
              Navigator.of(context).pop();
              ReadContext(
                context,
              ).read<ProfileDetailBloc>().add(UnfriendRequest(profile.id));
            },
          ),
        ],
      ),
    );
  }

  void _showCancelRequestDialog(BuildContext context, ProfileDetail profile) {
    showDialog(
      context: context,
      builder: (_) => AppDialog(
        icon: Icons.cancel_outlined,
        iconColor: const Color(0xFFFF9800),
        title: 'Cancel Request',
        description: 'Cancel your friend request to ${profile.name}?',
        actions: [
          AppDialogAction(
            label: 'Keep',
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.grey[100],
          ),
          AppDialogAction(
            label: 'Yes, Cancel',
            isPrimary: true,
            backgroundColor: const Color(0xFFFF9800),
            onPressed: () {
              Navigator.of(context).pop();
              ReadContext(
                context,
              ).read<ProfileDetailBloc>().add(CancelFriendRequest(profile.id));
            },
          ),
        ],
      ),
    );
  }

  // ─── Profile UI Helpers ───────────────────────────────────────────────────

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
        if (profile.title?.isNotEmpty ?? false) ...[
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

  Widget _buildMoreMenu(ProfileDetail profile, BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Color(0xFF8A94A6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'unfriend') _showUnfriendDialog(context, profile);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'unfriend',
          child: Row(
            children: [
              Icon(
                Icons.person_remove_outlined,
                color: Color(0xFFE05454),
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                'Unfriend',
                style: TextStyle(
                  color: Color(0xFFE05454),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
