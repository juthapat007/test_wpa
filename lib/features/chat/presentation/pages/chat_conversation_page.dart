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
    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (_, curr) => curr is ConversationDeleted,
      listener: (context, state) {
        if (state is ConversationDeleted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conversation cleared (${state.deletedCount} messages)',
              ),
            ),
          );
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          ReadContext(context).read<ChatBloc>().add(BackToRoomList());
          return true;
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context),
          body: const ChatConversationView(),
        ),
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
      actions: [
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final room = _extractRoom(state);
            if (room == null) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) {
                if (val == 'clear') _showClearDialog(context, room);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Clear conversation',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showClearDialog(BuildContext context, ChatRoom room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Clear Conversation',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Delete all messages with ${room.participantName}?\n\n'
          'This action cannot be undone and affects both sides.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ReadContext(
                context,
              ).read<ChatBloc>().add(DeleteConversation(room.participantId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  ChatRoom? _extractRoom(ChatState state) => switch (state) {
    ChatRoomSelected(:final room) => room,
    LoadingMoreMessages(:final room) => room,
    MessageSending(:final room) => room,
    MessageSent(:final room) => room,
    NewMessageReceived(:final room) => room,
    _ => null,
  };
}

enum _MenuAction { clearHistory }

// ── AppBar Title ──────────────────────────────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  final ChatRoom room;
  const _AppBarTitle({required this.room});

  @override
  Widget build(BuildContext context) {
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
            child: Row(
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
          ),
        ],
      ),
    );
  }
}

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
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: ClipOval(
        child: Image.network(
          room.participantAvatar!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
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
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
