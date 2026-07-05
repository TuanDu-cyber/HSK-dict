import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'auth_provider.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Đăng ký lắng nghe biến động trạng thái xác thực từ hệ thống Riverpod
    final state = ref.watch(authProvider);

    /// TH 1: Hệ thống đang tương tác mạng hoặc khởi tạo cache -> Hiển thị màn hình chờ toàn cục
    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // TH 2: Xác thực thành công (Firebase Auth Token hợp lệ) -> Chuyển vào Dashboard
    if (state.isLoggedIn) {
      return const HomeScreen();
    }

    // TH 3: Chưa xác thực và là người dùng mới -> Ép xem slide giới thiệu
    if (!state.hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    // TH 4: Mặc định - Người dùng cũ nhưng chưa đăng nhập hoặc đã đăng xuất -> Trả về màn hình login
    return const LoginScreen();
  }
}