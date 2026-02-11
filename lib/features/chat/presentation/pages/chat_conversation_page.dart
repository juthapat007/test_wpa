import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  // ✨ เพิ่ม flag เพื่อป้องกันการโหลดซ้ำ
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // ✨ เพิ่ม listener สำหรับ infinite scroll
    _scrollController.addListener(_onScroll);

    print('✅ ChatConversationPage initialized with scroll listener');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ✨ Infinite scroll logic
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // เมื่อเลื่อนถึงจุดบนสุด (reverse: true ทำให้ maxScrollExtent คือด้านบน)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Debug log (comment out ถ้าไม่ต้องการ log เยอะ)
    // print('📊 Scroll: $currentScroll / $maxScroll');

    // ถ้าเลื่อนใกล้ถึงจุดบนสุดแล้ว (เหลือ 200 pixels)
    if (currentScroll >= maxScroll - 200 && !_isLoadingMore) {
      final state = context.read<ChatBloc>().state;

      print('🔍 State: ${state.runtimeType}');

      if (state is ChatRoomSelected && state.hasMoreMessages) {
        final room = state.room;
        final nextPage = state.currentPage + 1;

        print(
          '🔄 Loading page $nextPage (current: ${state.currentPage}, total messages: ${state.messages.length})',
        );

        // ตั้ง flag ป้องกันโหลดซ้ำ
        _isLoadingMore = true;

        context.read<ChatBloc>().add(
          LoadMoreMessages(roomId: room.id, page: nextPage),
        );
      } else if (state is ChatRoomSelected && !state.hasMoreMessages) {
        print('⚠️ No more messages to load');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
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

    final room = _getRoom(state);
    if (room == null) return;

    bloc.add(SendMessage(roomId: room.id, content: content));
    _messageController.clear();

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // ✨ Reset page เมื่อ back
        print('⬅️ Back pressed - resetting pagination');
        context.read<ChatBloc>().add(BackToRoomList());
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            // ✨ รีเซ็ต loading flag เมื่อโหลดเสร็จ
            if (state is ChatRoomSelected) {
              _isLoadingMore = false;
              print(
                '✅ Loading complete. Has more: ${state.hasMoreMessages}, Page: ${state.currentPage}',
              );
            }

            // Scroll to bottom เมื่อมีข้อความใหม่
            if (state is NewMessageReceived ||
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
                state is LoadingMoreMessages ||
                state is MessageSending ||
                state is MessageSent ||
                state is NewMessageReceived) {
              final room = _getRoom(state);
              final messages = _getMessages(state);
              final currentUserId = context.read<ChatBloc>().currentUserId;

              // ✨ เช็คว่ากำลังโหลดข้อความเพิ่มหรือไม่
              final isLoadingMore = state is LoadingMoreMessages;

              print(
                '🎨 Building chat UI: ${messages.length} messages, isLoadingMore: $isLoadingMore',
              );

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
                        : Stack(
                            children: [
                              ListView.builder(
                                controller: _scrollController,
                                reverse: true, // ข้อความใหม่อยู่ด้านล่าง
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final reversedIndex =
                                      messages.length - 1 - index;
                                  final message = messages[reversedIndex];
                                  final isMe =
                                      message.senderId == currentUserId;

                                  return ChatMessageBubble(
                                    message: message,
                                    isMe: isMe,
                                  );
                                },
                              ),

                              // ✨ Loading indicator ตอนโหลดข้อความเพิ่ม
                              if (isLoadingMore)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.background.withOpacity(
                                        0.9,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Loading more messages...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
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
          // ✨ Reset page เมื่อกด back
          print('⬅️ Back button pressed - resetting pagination');
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
    if (state is LoadingMoreMessages) return state.room;
    if (state is MessageSending) return state.room;
    if (state is MessageSent) return state.room;
    if (state is NewMessageReceived) return state.room;
    return null;
  }

  List _getMessages(ChatState state) {
    if (state is ChatRoomSelected) return state.messages;
    if (state is LoadingMoreMessages) return state.messages;
    if (state is MessageSending) return state.messages;
    if (state is MessageSent) return state.messages;
    if (state is NewMessageReceived) return state.messages;
    return [];
  }
}
