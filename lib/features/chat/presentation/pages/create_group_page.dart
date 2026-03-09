// lib/features/chat/presentation/pages/create_group_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:test_wpa/core/theme/app_colors.dart';
import 'package:test_wpa/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:test_wpa/features/notification/presentation/bloc/friends_cubit.dart';
import 'package:test_wpa/features/search/domain/entities/delegate.dart';
import 'package:test_wpa/features/search/domain/repositories/delegate_repository.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupNameController = TextEditingController();
  final _selectedMembers = <Delegate>[];

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _toggleMember(Delegate delegate) {
    setState(() {
      if (_selectedMembers.any((m) => m.id == delegate.id)) {
        _selectedMembers.removeWhere((m) => m.id == delegate.id);
      } else {
        _selectedMembers.add(delegate);
      }
    });
  }

  bool _canCreate() =>
      _groupNameController.text.trim().isNotEmpty &&
      _selectedMembers.length >= 2;

  void _createGroup() {
    if (!_canCreate()) return;

    // TODO: เชื่อม API จริงตอน backend พร้อม
    // ตอนนี้แค่ pop กลับไปก่อน
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Group chat coming soon!')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          FriendsCubit(delegateRepository: Modular.get<DelegateRepository>())
            ..loadFriends(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 1,
          title: const Text(
            'New Group',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          actions: [
            // ปุ่ม Create — active เมื่อกรอกชื่อ + เลือกสมาชิก >= 2 คน
            TextButton(
              onPressed: _canCreate() ? _createGroup : null,
              child: Text(
                'Create',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _canCreate()
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── ส่วนกรอกชื่อกลุ่ม ──────────────────────────
            _GroupNameSection(controller: _groupNameController),

            // ── Selected members chips ───────────────────────
            if (_selectedMembers.isNotEmpty)
              _SelectedMembersBar(
                members: _selectedMembers,
                onRemove: _toggleMember,
              ),

            // ── Friends list ─────────────────────────────────
            Expanded(
              child: BlocBuilder<FriendsCubit, FriendsState>(
                builder: (context, state) => switch (state) {
                  FriendsLoading() || FriendsInitial() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  FriendsError(:final message) => Center(child: Text(message)),
                  FriendsLoaded(:final friends) => _FriendSelectList(
                    friends: friends,
                    selectedMembers: _selectedMembers,
                    onToggle: _toggleMember,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Group Name Section ────────────────────────────────────────────────────────

class _GroupNameSection extends StatelessWidget {
  final TextEditingController controller;

  const _GroupNameSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Group icon placeholder
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.group, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: false,
              decoration: const InputDecoration(
                hintText: 'Group name (required)',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              onChanged: (_) => (context as Element).markNeedsBuild(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Selected Members Bar ──────────────────────────────────────────────────────

class _SelectedMembersBar extends StatelessWidget {
  final List<Delegate> members;
  final Function(Delegate) onRemove;

  const _SelectedMembersBar({required this.members, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: member.avatarUrl.isNotEmpty
                          ? NetworkImage(member.avatarUrl)
                          : null,
                      child: member.avatarUrl.isEmpty
                          ? Text(
                              member.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    // ปุ่ม remove
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => onRemove(member),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Friend Select List ────────────────────────────────────────────────────────

class _FriendSelectList extends StatelessWidget {
  final List<Delegate> friends;
  final List<Delegate> selectedMembers;
  final Function(Delegate) onToggle;

  const _FriendSelectList({
    required this.friends,
    required this.selectedMembers,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        final isSelected = selectedMembers.any((m) => m.id == friend.id);

        return ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: friend.avatarUrl.isNotEmpty
                ? NetworkImage(friend.avatarUrl)
                : null,
            child: friend.avatarUrl.isEmpty
                ? Text(
                    friend.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            friend.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          subtitle: friend.title.isNotEmpty
              ? Text(
                  friend.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: isSelected
              ? CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                )
              : CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.border,
                  child: const SizedBox.shrink(),
                ),
          onTap: () => onToggle(friend),
        );
      },
    );
  }
}
