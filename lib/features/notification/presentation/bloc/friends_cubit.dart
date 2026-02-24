// lib/features/chat/presentation/bloc/friends_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_wpa/features/search/domain/entities/delegate.dart';
import 'package:test_wpa/features/search/domain/repositories/delegate_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────
sealed class FriendsState {}

final class FriendsInitial extends FriendsState {}

final class FriendsLoading extends FriendsState {}

final class FriendsLoaded extends FriendsState {
  final List<Delegate> friends;
  FriendsLoaded(this.friends);
}

final class FriendsError extends FriendsState {
  final String message;
  FriendsError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class FriendsCubit extends Cubit<FriendsState> {
  final DelegateRepository delegateRepository;

  FriendsCubit({required this.delegateRepository}) : super(FriendsInitial());

  Future<void> loadFriends() async {
    emit(FriendsLoading());
    try {
      final response = await delegateRepository.searchDelegates(
        friendsOnly: true,
        perPage: 100, // ดึงทั้งหมด friends ไม่น่าเยอะ
      );
      emit(FriendsLoaded(response.delegates));
    } catch (e) {
      emit(FriendsError(e.toString()));
    }
  }
}
