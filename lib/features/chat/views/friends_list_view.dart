// lib/features/chat/views/friends_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/friends_cubit.dart';
import 'package:test_wpa/features/search/domain/entities/delegate.dart';
import 'package:test_wpa/features/search/domain/repositories/delegate_repository.dart';

class FriendsListView extends StatelessWidget {
  const FriendsListView({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ BlocProvider สร้าง Cubit ใหม่ให้ตัวเอง — ไม่ต้องพึ่ง parent
    return BlocProvider(
      create: (_) =>
          FriendsCubit(delegateRepository: Modular.get<DelegateRepository>())
            ..loadFriends(),
      child: const _FriendsBody(),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _FriendsBody extends StatelessWidget {
  const _FriendsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsCubit, FriendsState>(
      builder: (context, state) => switch (state) {
        FriendsInitial() || FriendsLoading() => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        FriendsError(:final message) => _ErrorView(
          message: message,
          onRetry: () =>
              ReadContext(context).read<FriendsCubit>().loadFriends(),
        ),
        FriendsLoaded(:final friends) =>
          friends.isEmpty ? const _EmptyView() : _FriendList(friends: friends),
      },
    );
  }
}

// ── List ──────────────────────────────────────────────────────────────────────

class _FriendList extends StatelessWidget {
  final List<Delegate> friends;

  const _FriendList({required this.friends});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => ReadContext(context).read<FriendsCubit>().loadFriends(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: friends.length,
        itemBuilder: (context, index) => _FriendCard(delegate: friends[index]),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _FriendCard extends StatelessWidget {
  final Delegate delegate;

  const _FriendCard({required this.delegate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Modular.to.pushNamed(
          '/other_profile',
          arguments: {'delegate_id': delegate.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Avatar(delegate: delegate),
              const SizedBox(width: 12),
              Expanded(child: _Info(delegate: delegate)),
              _ChatButton(delegate: delegate),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Delegate delegate;

  const _Avatar({required this.delegate});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = delegate.avatarUrl.isNotEmpty;
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      backgroundImage: hasAvatar ? NetworkImage(delegate.avatarUrl) : null,
      child: !hasAvatar
          ? Text(
              delegate.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

class _Info extends StatelessWidget {
  final Delegate delegate;

  const _Info({required this.delegate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          delegate.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (delegate.title.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            delegate.title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (delegate.companyName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            delegate.companyName,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChatButton extends StatelessWidget {
  final Delegate delegate;

  const _ChatButton({required this.delegate});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
      tooltip: 'Send message',
      onPressed: () {
        ReadContext(context).read<ChatBloc>().add(
          CreateChatRoom(delegate.id.toString(), delegate.name),
        );
        Modular.to.pushNamed('/chat/room');
      },
    );
  }
}

// ── Empty / Error ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'No friends yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect with other delegates\nto see them here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
