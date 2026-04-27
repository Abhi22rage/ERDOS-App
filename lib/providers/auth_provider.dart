import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'core_providers.dart';

// ─── Auth State Notifier ──────────────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return ref.read(apiServiceProvider).getCurrentUser();
  }

  Future<void> login(String mobile, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(apiServiceProvider).login(mobile, password);
      state = AsyncValue.data(result['user'] as UserModel?);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signup(Map<String, dynamic> userData) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(apiServiceProvider).signup(userData);
      state = AsyncValue.data(result['user'] as UserModel?);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(apiServiceProvider).logout();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = state.value;
    if (user != null) {
      await ref.read(apiServiceProvider).updateUserProfile(user.id, data);
      state = AsyncValue.data(await ref.read(apiServiceProvider).getCurrentUser());
    }
  }

  Future<void> uploadProfilePhoto(Uint8List bytes) async {
    final user = state.value;
    if (user == null) return;
    
    // Use copyWithPrevious to keep the current user data visible while loading
    // ignore: invalid_use_of_internal_member
    state = const AsyncLoading<UserModel?>().copyWithPrevious(state);
    try {
      final url = await ref.read(apiServiceProvider).uploadProfilePhoto(user.id, bytes);
      await updateProfile({'photo_url': url});
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeProfilePhoto() async {
    final user = state.value;
    if (user == null) return;

    // ignore: invalid_use_of_internal_member
    state = const AsyncLoading<UserModel?>().copyWithPrevious(state);
    try {
      await ref.read(apiServiceProvider).removeProfilePhoto(user.id);
      await updateProfile({'photo_url': null});
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);
