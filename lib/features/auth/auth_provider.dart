import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/avatar_repository.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    avatarRepository: ref.watch(avatarRepositoryProvider),
  );

  ref.onDispose(notifier.dispose);

  return notifier..listenAuthChanges();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required AuthRepository repository,
    required AvatarRepository avatarRepository,
  }) : _repository = repository,
       _avatarRepository = avatarRepository,
       super(const AuthState(isLoading: true));

  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';

  final AuthRepository _repository;
  final AvatarRepository _avatarRepository;

  StreamSubscription? _authSubscription;

  bool get canChangePassword => _repository.canChangePassword;

  Future<void> listenAuthChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_hasSeenOnboardingKey) ?? false;

    state = state.copyWith(
      isLoading: true,
      hasSeenOnboarding: hasSeenOnboarding,
      clearError: true,
    );

    _authSubscription?.cancel();

    _authSubscription = _repository.authStateChanges().listen((
      firebaseUser,
    ) async {
      if (firebaseUser == null) {
        state = state.copyWith(
          isLoading: false,
          clearUser: true,
          hasSeenOnboarding: hasSeenOnboarding,
          clearError: true,
        );
        return;
      }

      try {
        final profile = await _repository.getCurrentUserProfile();

        if (profile == null) {
          state = state.copyWith(
            isLoading: false,
            clearUser: true,
            error: 'Không tìm thấy hồ sơ người dùng.',
          );
          return;
        }

        state = state.copyWith(
          isLoading: false,
          user: profile,
          hasSeenOnboarding: hasSeenOnboarding,
          clearError: true,
        );
      } catch (_) {
        state = state.copyWith(
          isLoading: false,
          error: 'Không thể tải tài khoản.',
        );
      }
    });
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);

    state = state.copyWith(hasSeenOnboarding: true, clearError: true);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    XFile? avatarImage,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      var user = await _repository.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );

      if (avatarImage != null) {
        final avatarUrl = await _avatarRepository.uploadAvatar(
          uid: user.uid,
          image: avatarImage,
        );
        await _repository.updateUserProfile(
          uid: user.uid,
          avatarUrl: avatarUrl,
        );
        user = user.copyWith(avatarUrl: avatarUrl);
      }

      state = state.copyWith(
        isLoading: false,
        user: user,
        hasSeenOnboarding: true,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final user = await _repository.loginWithEmail(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        user: user,
        hasSeenOnboarding: true,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final user = await _repository.signInWithGoogle();

      state = state.copyWith(
        isLoading: false,
        user: user,
        hasSeenOnboarding: true,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _repository.logout();

      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        clearError: true,
      );
      return true;
    } catch (e) {
      if (_repository.currentFirebaseUser == null) {
        state = state.copyWith(
          isLoading: false,
          clearUser: true,
          clearError: true,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Đăng xuất thất bại, vui lòng thử lại.',
      );
      return false;
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _repository.sendPasswordResetEmail(email);

      state = state.copyWith(isLoading: false, clearError: true);
      return null;
    } catch (e) {
      final message = _cleanError(e);
      state = state.copyWith(isLoading: false, clearError: true);
      return message;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = state.copyWith(isLoading: false, clearError: true);
      return null;
    } catch (e) {
      final message = _cleanError(e);
      state = state.copyWith(isLoading: false, clearError: true);
      return message;
    }
  }

  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    final currentUser = state.user;

    if (currentUser == null) {
      state = state.copyWith(error: 'Bạn chưa đăng nhập.');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _repository.updateUserProfile(
        uid: currentUser.uid,
        name: name,
        avatarUrl: avatarUrl,
      );

      final updatedUser = currentUser.copyWith(
        name: name?.trim().isNotEmpty == true ? name!.trim() : currentUser.name,
        avatarUrl: avatarUrl ?? currentUser.avatarUrl,
      );

      state = state.copyWith(
        isLoading: false,
        user: updatedUser,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
    }
  }

  Future<XFile?> pickAvatarFromGallery() {
    return _avatarRepository.pickAvatarFromGallery();
  }

  Future<bool> updateAvatarFromGallery() async {
    final currentUser = state.user;

    if (currentUser == null) {
      state = state.copyWith(error: 'Bạn chưa đăng nhập.');
      return false;
    }

    try {
      final image = await _avatarRepository.pickAvatarFromGallery();

      if (image == null) {
        return false;
      }

      state = state.copyWith(isLoading: true, clearError: true);

      final avatarUrl = await _avatarRepository.uploadAvatar(
        uid: currentUser.uid,
        image: image,
      );

      await _repository.updateUserProfile(
        uid: currentUser.uid,
        avatarUrl: avatarUrl,
      );

      state = state.copyWith(
        isLoading: false,
        user: currentUser.copyWith(avatarUrl: avatarUrl),
        clearError: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
