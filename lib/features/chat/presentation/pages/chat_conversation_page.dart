import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/views/chat_conversation_view.dart';
import 'package:intl/intl.dart';

class ChatConversationPage extends StatelessWidget {
  const ChatConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ReadContext(context).read<ChatBloc>().add(BackToRoomList());
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: const ChatConversationView(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          ReadContext(context).read<ChatBloc>().add(BackToRoomList());
          Navigator.of(context).pop();
        },
      ),
      title: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final room = _getRoom(state);

          if (room == null) {
            return const Text('Chat');
          }

          // ✅ กดที่ชื่อ/รูป profile → ไปหน้า OtherProfilePage
          return GestureDetector(
            onTap: () {
              final participantId = int.tryParse(room.participantId);
              if (participantId != null) {
                Modular.to.pushNamed('/other-profile/$participantId');
              }
            },
            child: Row(
              children: [
                // Avatar (กดได้)
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage:
                      room.participantAvatar != null &&
                          room.participantAvatar!.isNotEmpty
                      ? NetworkImage(room.participantAvatar!)
                      : null,
                  child:
                      room.participantAvatar == null ||
                          room.participantAvatar!.isEmpty
                      ? Text(
                          _getInitials(room.participantName),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // ชื่อ + Online status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              room.participantName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ✅ ไอคอน chevron เล็กๆ บอกว่ากดได้
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      if (room.lastActiveAt != null &&
                          DateTime.now()
                                  .difference(room.lastActiveAt!)
                                  .inMinutes <
                              5)
                        const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  dynamic _getRoom(ChatState state) {
    if (state is ChatRoomSelected) return state.room;
    if (state is LoadingMoreMessages) return state.room;
    if (state is MessageSending) return state.room;
    if (state is MessageSent) return state.room;
    if (state is NewMessageReceived) return state.room;
    return null;
  }
}
