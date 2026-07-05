import '../../models/app_user_model.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.hasSeenOnboarding = false,
  });

  final bool isLoading;
  final AppUserModel? user;
  final String? error;
  final bool hasSeenOnboarding;

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    bool? isLoading,
    AppUserModel? user,
    bool clearUser = false,
    String? error,
    bool clearError = false,
    bool? hasSeenOnboarding,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      error: clearError ? null : error ?? this.error,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}