import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/constants/set_space.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/data/models/chat_message.dart';
import 'package:test_wpa/features/chat/data/models/chat_room.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/chat/presentation/widgets/chat_input_field.dart';
import 'package:test_wpa/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:test_wpa/features/chat/presentation/widgets/empty_state_widget.dart';

class ChatConversationView extends StatefulWidget {
  const ChatConversationView({super.key});

  @override
  State<ChatConversationView> createState() => _ChatConversationViewState();
}

class _ChatConversationViewState extends State<ChatConversationView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Timer? _typingTimer;
  // bool _isTyping = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // _typingTimer?.cancel();
    super.dispose();
  }

  // ─── Typing indicator ─────────────────────────────────────────────────────

  // void _onTextChanged() {
  //   final text = _messageController.text.trim();
  //   final room = _extractRoom(context.read<ChatBloc>().state);
  //   if (room == null) return;

  //   if (text.isNotEmpty && !_isTyping) {
  //     _isTyping = true;
  //     context.read<ChatBloc>().add(
  //       SendTypingIndicator(recipientId: room.participantId, isTyping: true),
  //     );
  //   } else if (text.isEmpty && _isTyping) {
  //     _stopTyping();
  //     return;
  //   }

  //   // reset auto-stop timer ทุกครั้งที่พิมพ์
  //   if (_isTyping) {
  //     _typingTimer?.cancel();
  //     _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  //   }
  // }

  // void _stopTyping() {
  //   if (!_isTyping) return;
  //   _isTyping = false;
  //   _typingTimer?.cancel();

  //   final room = _extractRoom(context.read<ChatBloc>().state);
  //   if (room == null) return;

  //   context.read<ChatBloc>().add(
  //     SendTypingIndicator(recipientId: room.participantId, isTyping: false),
  //   );
  // }

  // ─── Scroll / Load More ───────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;

    // reverse list: maxScrollExtent คือด้านบนสุด (ข้อความเก่า)
    final atTop =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;

    if (!atTop) return;

    final state = context.read<ChatBloc>().state;

    // ✅ FIX: ดึง room/page/hasMore จาก state ทุก type ที่เกี่ยวข้อง
    final room = _extractRoom(state);
    final hasMore = _extractHasMore(state);
    final currentPage = _extractCurrentPage(state);

    if (room != null && hasMore) {
      _isLoadingMore = true;
      context.read<ChatBloc>().add(
        LoadMoreMessages(roomId: room.id, page: currentPage + 1),
      );
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Send Message ─────────────────────────────────────────────────────────

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // _stopTyping();

    final room = _extractRoom(context.read<ChatBloc>().state);
    if (room == null) return;

    context.read<ChatBloc>().add(
      SendMessage(roomId: room.id, content: content),
    );
    _messageController.clear();
    _scrollToBottom();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      // ✅ FIX: listenWhen — handle scroll และ loading เฉพาะ state ที่เกี่ยวข้อง
      listenWhen: (_, curr) =>
          curr is ChatRoomSelected ||
          curr is NewMessageReceived ||
          curr is MessageSent ||
          curr is MessageSending,
      listener: (context, state) {
        // reset flag เมื่อ load more เสร็จ
        if (state is ChatRoomSelected) _isLoadingMore = false;

        // scroll to bottom เมื่อมีข้อความใหม่หรือส่งข้อความ
        if (state is NewMessageReceived ||
            state is MessageSent ||
            state is MessageSending) {
          _scrollToBottom();
        }
      },
      // ✅ FIX: buildWhen — rebuild เฉพาะ state ที่มี messages/room
      // ChatRoomsLoaded ไม่ควรมา rebuild หน้านี้
      buildWhen: (_, curr) =>
          curr is ChatLoading ||
          curr is ChatRoomSelected ||
          // curr is LoadingMoreMessages ||
          curr is MessageSending ||
          curr is MessageSent ||
          curr is NewMessageReceived ||
          curr is ChatError,
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ChatError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      context.read<ChatBloc>().add(LoadChatRooms()),
                  child: const Text('Back to chats'),
                ),
              ],
            ),
          );
        }

        // ✅ FIX: ดึงข้อมูลจาก state ด้วย type-safe helpers
        final room = _extractRoom(state);
        final messages = _extractMessages(state);
        // final isTyping = _extractIsTyping(state);
        // final isLoadingMoreState = state is LoadingMoreMessages;

        if (room == null) {
          return const EmptyStateWidget(
            icon: Icons.chat_outlined,
            title: 'No chat selected',
          );
        }

        final currentUserId = context.read<ChatBloc>().currentUserId;

        return Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.chat_outlined,
                      title: 'No messages yet',
                      message: 'Start the conversation!',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        // Loading indicator ที่ด้านบน (index สุดท้ายของ reverse list)
                        // final totalExtra =
                        // (isTyping ? 1 : 0) + (isLoadingMoreState ? 1 : 0);
                        // if (index >= messages.length) {
                        //   final extraIndex = index - messages.length;
                        //   if (isLoadingMoreState && extraIndex == 0) {
                        //     return const Padding(
                        //       padding: EdgeInsets.all(16),
                        //       child: Center(
                        //         child: SizedBox(
                        //           width: 24,
                        //           height: 24,
                        //           child: CircularProgressIndicator(
                        //             strokeWidth: 2,
                        //           ),
                        //         ),
                        //       ),
                        //     );
                        //   }
                        //   if (isTyping) {
                        //     return TypingIndicator(
                        //       userName: room.participantName,
                        //     );
                        //   }
                        // }

                        // // typing indicator ที่ index 0 (ข้อความล่าสุด)
                        // if (index == 0 && isTyping && !isLoadingMoreState) {
                        //   return TypingIndicator(
                        //     userName: room.participantName,
                        //   );
                        // }

                        final messageIndex = index;
                        if (messageIndex < 0 ||
                            messageIndex >= messages.length) {
                          return const SizedBox.shrink();
                        }

                        final reversedIndex =
                            messages.length - 1 - messageIndex;
                        final message = messages[reversedIndex];
                        final isMe = message.senderId == currentUserId;

                        return ChatMessageBubble(
                          message: message,
                          isMe: isMe,
                          onEdit: isMe
                              ? (newContent) => context.read<ChatBloc>().add(
                                  UpdateMessageLocal(
                                    messageId: message.id,
                                    newContent: newContent,
                                  ),
                                )
                              : null,
                          onDelete: isMe
                              ? () => context.read<ChatBloc>().add(
                                  DeleteMessageLocal(message.id),
                                )
                              : null,
                        );
                      },
                    ),
            ),
            ChatInputField(
              controller: _messageController,
              onSend: _sendMessage,
            ),
            SizedBox(height: height.l),
          ],
        );
      },
    );
  }

  // ─── Type-safe State Helpers ──────────────────────────────────────────────

  /// ✅ ดึง room จาก state อย่าง type-safe — ไม่ใช้ dynamic แล้ว
  ChatRoom? _extractRoom(ChatState state) => switch (state) {
    ChatRoomSelected(:final room) => room,
    LoadingMoreMessages(:final room) => room,
    MessageSending(:final room) => room,
    MessageSent(:final room) => room,
    NewMessageReceived(:final room) => room,
    _ => null,
  };

  List<ChatMessage> _extractMessages(ChatState state) => switch (state) {
    ChatRoomSelected(:final messages) => messages,
    LoadingMoreMessages(:final messages) => messages,
    MessageSending(:final messages) => messages,
    MessageSent(:final messages) => messages,
    NewMessageReceived(:final messages) => messages,
    _ => [],
  };

  // bool _extractIsTyping(ChatState state) => switch (state) {
  //   ChatRoomSelected(:final isTyping) => isTyping,
  //   LoadingMoreMessages(:final isTyping) => isTyping,
  //   _ => false,
  // };

  bool _extractHasMore(ChatState state) => switch (state) {
    ChatRoomSelected(:final hasMoreMessages) => hasMoreMessages,
    LoadingMoreMessages() => true,
    _ => false,
  };

  int _extractCurrentPage(ChatState state) => switch (state) {
    ChatRoomSelected(:final currentPage) => currentPage,
    LoadingMoreMessages(:final currentPage) => currentPage,
    _ => 1,
  };
}
