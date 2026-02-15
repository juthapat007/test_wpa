import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 200 && !_isLoadingMore) {
      final state = context.read<ChatBloc>().state;

      if (state is ChatRoomSelected && state.hasMoreMessages) {
        final room = state.room;
        final nextPage = state.currentPage + 1;

        _isLoadingMore = true;

        context.read<ChatBloc>().add(
          LoadMoreMessages(roomId: room.id, page: nextPage),
        );
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
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatRoomSelected) {
          _isLoadingMore = false;
        }

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
          final isLoadingMore = state is LoadingMoreMessages;

          return Column(
            children: [
              // Messages list
              Expanded(
                child: messages.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.chat_outlined,
                        title: 'No messages yet',
                        message: 'Start the conversation!',
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final reversedIndex = messages.length - 1 - index;
                              final message = messages[reversedIndex];
                              final isMe = message.senderId == currentUserId;

                              return ChatMessageBubble(
                                message: message,
                                isMe: isMe,
                              );
                            },
                          ),

                          // Loading indicator
                          // if (isLoadingMore)
                          //   Positioned(
                          //     top: 0,
                          //     left: 0,
                          //     right: 0,
                          //     child: LoadingOverlay(
                          //       message: 'Loading more messages...',
                          //     ),
                          //   ),
                        ],
                      ),
              ),

              // Message input
              ChatInputField(
                controller: _messageController,
                onSend: _sendMessage,
              ),
            ],
          );
        }

        return EmptyStateWidget(
          icon: Icons.chat_outlined,
          title: 'No chat selected',
        );
      },
    );
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
