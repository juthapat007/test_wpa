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
  bool _isLoadingMore = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Scroll / Load More ───────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;

    final atTop =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;

    if (!atTop) return;

    final state = context.read<ChatBloc>().state;
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

  // ─── Send Text ────────────────────────────────────────────────────────────

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final room = _extractRoom(context.read<ChatBloc>().state);
    if (room == null) return;

    context.read<ChatBloc>().add(
      SendMessage(roomId: room.id, content: content),
    );
    _messageController.clear();
    _scrollToBottom();
  }
  // ─── Typing Indicator ─────────────────────────────────────────────────────

  void _onTyping() {
    final room = _extractRoom(context.read<ChatBloc>().state);
    if (room == null) return;

    context.read<ChatBloc>().add(
      SendTypingIndicator(recipientId: room.participantId, isTyping: true),
    );

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      context.read<ChatBloc>().add(
        SendTypingIndicator(recipientId: room.participantId, isTyping: false),
      );
    });
  }
  // ─── Send Image ───────────────────────────────────────────────────────────

  void _sendImage(String imageBase64) {
    final room = _extractRoom(context.read<ChatBloc>().state);
    if (room == null) return;

    context.read<ChatBloc>().add(
      SendMessage(
        roomId: room.id,
        type: MessageType.image,
        imageBase64: imageBase64,
      ),
    );
    _scrollToBottom();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listenWhen: (_, curr) =>
          curr is ChatRoomSelected ||
          curr is NewMessageReceived ||
          curr is MessageSent ||
          curr is MessageSending,
      listener: (context, state) {
        if (state is ChatRoomSelected) _isLoadingMore = false;
        if (state is NewMessageReceived ||
            state is MessageSent ||
            state is MessageSending) {
          _scrollToBottom();
        }
      },
      buildWhen: (_, curr) =>
          curr is ChatLoading ||
          curr is ChatRoomSelected ||
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

        final room = _extractRoom(state);
        final messages = _extractMessages(state);

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
                        final reversedIndex = messages.length - 1 - index;
                        if (reversedIndex < 0 ||
                            reversedIndex >= messages.length) {
                          return const SizedBox.shrink();
                        }

                        final message = messages[reversedIndex];
                        final isMe = message.senderId == currentUserId;

                        return ChatMessageBubble(
                          message: message,
                          isMe: isMe,
                          onEdit: isMe && message.type == MessageType.text
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
              onSendImage: _sendImage,
              onChanged: _onTyping,
            ),
            SizedBox(height: space_bottom.l),
          ],
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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
