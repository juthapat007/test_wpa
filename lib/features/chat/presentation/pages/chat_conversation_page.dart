import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/views/chat_conversation_view.dart';

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
        // ✅ buildWhen: rebuild เฉพาะเมื่อ room หรือ connection เปลี่ยน
        buildWhen: (prev, curr) {
          final prevRoom = _extractRoom(prev);
          final currRoom = _extractRoom(curr);
          return prevRoom?.participantId != currRoom?.participantId ||
              prevRoom?.participantAvatar != currRoom?.participantAvatar ||
              prevRoom?.lastActiveAt != currRoom?.lastActiveAt;
        },
        builder: (context, state) {
          final room = _extractRoom(state);
          if (room == null) return const Text('Chat');
          return _AppBarTitle(room: room);
        },
      ),
    );
  }

  /// ✅ FIX: ดึง room จาก state อย่างปลอดภัย — ไม่ return dynamic แล้ว
  ChatRoom? _extractRoom(ChatState state) => switch (state) {
    ChatRoomSelected(:final room) => room,
    LoadingMoreMessages(:final room) => room,
    MessageSending(:final room) => room,
    MessageSent(:final room) => room,
    NewMessageReceived(:final room) => room,
    _ => null,
  };
}

class _AppBarTitle extends StatelessWidget {
  final ChatRoom room;

  const _AppBarTitle({required this.room});

  @override
  Widget build(BuildContext context) {
    final isOnline =
        room.lastActiveAt != null &&
        DateTime.now().difference(room.lastActiveAt!).inMinutes < 5;

    return GestureDetector(
      onTap: () {
        final participantId = int.tryParse(room.participantId);
        if (participantId != null) {
          Modular.to.pushNamed(
            '/other_profile/$participantId',
            arguments: participantId,
          );
        }
      },
      child: Row(
        children: [
          _ParticipantAvatar(room: room),
          const SizedBox(width: 12),
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
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                if (isOnline)
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ FIX: Avatar widget แยกออกมา จัดการ null / error URL ได้ครบ
class _ParticipantAvatar extends StatelessWidget {
  final ChatRoom room;

  const _ParticipantAvatar({required this.room});

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        room.participantAvatar != null && room.participantAvatar!.isNotEmpty;

    if (!hasAvatar) return _buildFallback();

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: ClipOval(
        child: Image.network(
          room.participantAvatar!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          // ✅ ถ้าโหลดภาพไม่ได้ (404 / expired) → แสดง initials แทน
          errorBuilder: (_, __, ___) => _buildFallbackChild(),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return const CircularProgressIndicator(strokeWidth: 1.5);
          },
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: _buildFallbackChild(),
    );
  }

  Widget _buildFallbackChild() {
    return Text(
      _getInitials(room.participantName),
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
