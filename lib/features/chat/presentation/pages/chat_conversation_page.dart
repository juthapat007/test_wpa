import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_avatar.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/presentation/widgets/chat_message_bubble.dart';

class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({super.key});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        // reverse: true ทำให้ position 0 คือด้านล่างสุด (ข้อความล่าสุด)
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final bloc = context.read<ChatBloc>();
    final state = bloc.state;

    // ดึง room จากทุก state ที่เป็นไปได้ (ไม่ใช่แค่ ChatRoomSelected)
    final room = _getRoom(state);
    if (room == null) return;

    bloc.add(SendMessage(roomId: room.id, content: content));
    _messageController.clear();

    // Scroll to bottom after sending
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // เรียก BackToRoomList ก่อนที่จะ pop
        context.read<ChatBloc>().add(BackToRoomList());
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatRoomSelected ||
                state is NewMessageReceived ||
                state is MessageSent ||
                state is MessageSending) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ChatRoomSelected ||
                state is MessageSending ||
                state is MessageSent ||
                state is NewMessageReceived) {
              final room = _getRoom(state);
              final messages = _getMessages(state);

              // ✅ ใช้ currentUserId จาก ChatBloc แทนการ hardcode
              final currentUserId = context.read<ChatBloc>().currentUserId;

              print('🎨 Building UI:');
              print('   - Current user ID: $currentUserId');
              print('   - Total messages: ${messages.length}');

              return Column(
                children: [
                  // Messages list
                  Expanded(
                    child: messages.isEmpty
                        ? Center(
                            child: Text(
                              'No messages yet\nStart the conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse:
                                true, // แสดงข้อความล่าสุดที่ด้านล่าง (เลื่อนขึ้นดูเก่า)
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              // reverse: true จะแสดง index 0 ที่ด้านล่างสุด
                              // ดังนั้นต้องกลับ index เพื่อให้ข้อความล่าสุดอยู่ล่าง
                              final reversedIndex = messages.length - 1 - index;
                              final message = messages[reversedIndex];

                              // ✅ Check isMe โดยเปรียบเทียบกับ current user ID จริง
                              final isMe = message.senderId == currentUserId;

                              // Debug log
                              if (index < 3) {
                                print(
                                  '   - Message $reversedIndex: sender=${message.senderId}, isMe=$isMe',
                                );
                              }

                              return ChatMessageBubble(
                                message: message,
                                isMe: isMe,
                              );
                            },
                          ),
                  ),

                  // Message input
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text('No chat selected'));
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          context.read<ChatBloc>().add(BackToRoomList());
          Navigator.of(context).pop();
        },
      ),
      title: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final room = _getRoom(state);

          if (room == null) {
            return const Text('Chat');
          }

          return Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      room.participantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
    if (state is MessageSending) return state.room;
    if (state is MessageSent) return state.room;
    if (state is NewMessageReceived) return state.room;
    return null;
  }

  List _getMessages(ChatState state) {
    if (state is ChatRoomSelected) return state.messages;
    if (state is MessageSending) return state.messages;
    if (state is MessageSent) return state.messages;
    if (state is NewMessageReceived) return state.messages;
    return [];
  }
}
