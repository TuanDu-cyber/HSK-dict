import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_decorative_background.dart';
import '../../repositories/notification_repository.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _loginError;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.background,
      body: AppDecorativeBackground(
        useSafeArea: true,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPadding,
            AppTheme.spacing20,
            AppTheme.screenPadding,
            AppTheme.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LoginBrandHeader(),
              const SizedBox(height: AppTheme.spacing20),
              const _LoginWelcomeText(),
              const SizedBox(height: AppTheme.spacing20),
              Center(
                child: Image.asset(
                  'assets/images/avatar_default.png',
                  width: MediaQuery.of(context).size.width * 0.62,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const _HeroFallback(),
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              _LoginFormCard(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                emailFocusNode: _emailFocusNode,
                passwordFocusNode: _passwordFocusNode,
                obscurePassword: _obscurePassword,
                rememberMe: _rememberMe,
                isLoading: authState.isLoading,
                canSubmit: true,
                loginError: _loginError,
                emailValidator: _validateEmail,
                passwordValidator: _validatePassword,
                onFieldChanged: _clearLoginError,
                onTogglePassword: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onToggleRemember: () {
                  setState(() {
                    _rememberMe = !_rememberMe;
                  });
                },
                onLogin: _handleLogin,
                onGoogleLogin: _handleLoginWithGoogle,
                onResetPassword: _handleResetPassword,
              ),
              const SizedBox(height: AppTheme.spacing24),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 17,
                      ),
                    ),
                    GestureDetector(
                      onTap: authState.isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: Text(
                        'Đăng ký',
                        style: AppTheme.bodyBold.copyWith(
                          color: AppTheme.primary,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    _clearLoginError();
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final didLogin = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (didLogin && mounted) {
      await ref
          .read(notificationRepositoryProvider)
          .scheduleDailyStreakReminder();
      if (!mounted) return;
      context.go(AppRoutes.home);
      return;
    }

    if (!didLogin && mounted) {
      final message =
          ref.read(authProvider).error ?? 'Email hoặc mật khẩu không đúng.';
      setState(() {
        _loginError = message;
      });
    }
  }

  Future<void> _handleLoginWithGoogle() async {
    final didLogin = await ref.read(authProvider.notifier).loginWithGoogle();

    if (didLogin && mounted) {
      await ref
          .read(notificationRepositoryProvider)
          .scheduleDailyStreakReminder();
      if (!mounted) return;
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleResetPassword() async {
    await _showResetPasswordDialog(_emailController.text.trim());
  }

  Future<void> _showResetPasswordDialog(String initialEmail) {
    final dialogFormKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: initialEmail);
    var isSending = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: !isSending,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.cardLargeRadius,
              ),
              title: const Text('Quên mật khẩu?'),
              content: Form(
                key: dialogFormKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextFormField(
                  controller: emailController,
                  enabled: !isSending,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: _validateResetEmail,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  onFieldSubmitted: (_) {
                    _submitResetEmail(
                      dialogContext,
                      dialogFormKey,
                      emailController,
                      setDialogState,
                      (value) => isSending = value,
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () {
                          _submitResetEmail(
                            dialogContext,
                            dialogFormKey,
                            emailController,
                            setDialogState,
                            (value) => isSending = value,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(emailController.dispose);
  }

  Future<void> _submitResetEmail(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    TextEditingController emailController,
    StateSetter setDialogState,
    ValueChanged<bool> setSending,
  ) async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setDialogState(() {
      setSending(true);
    });

    final error = await ref
        .read(authProvider.notifier)
        .resetPassword(emailController.text.trim());

    if (!dialogContext.mounted) return;
    Navigator.of(dialogContext).pop();

    if (!mounted) return;

    if (error != null) {
      await _showResetPasswordResultDialog(
        title: 'Không gửi được email',
        message: error,
      );
      return;
    }

    await _showResetPasswordResultDialog(
      title: 'Kiểm tra hộp thư',
      message:
          'Nếu email đã được đăng ký, liên kết đặt lại mật khẩu sẽ được gửi đến hộp thư của bạn.',
    );
  }

  Future<void> _showResetPasswordResultDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.cardLargeRadius),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  String? _validateResetEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Vui lòng nhập email.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email không hợp lệ.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Vui lòng nhập mật khẩu.';
    return null;
  }

  void _clearLoginError() {
    if (_loginError == null) return;

    setState(() {
      _loginError = null;
    });
  }
}

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '汉',
            style: AppTheme.hanziSmall.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: AppTheme.spacing20),
        Text(
          'HSK Dict',
          style: AppTheme.headingXLarge.copyWith(
            color: AppTheme.primary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LoginWelcomeText extends StatelessWidget {
  const _LoginWelcomeText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chào mừng quay lại',
          style: AppTheme.headingLarge.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Text(
          'Đăng nhập để tiếp tục học\ncùng HSK Dict.',
          style: AppTheme.body.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 20,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.rememberMe,
    required this.isLoading,
    required this.canSubmit,
    required this.loginError,
    required this.emailValidator,
    required this.passwordValidator,
    required this.onFieldChanged,
    required this.onTogglePassword,
    required this.onToggleRemember,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onResetPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final bool rememberMe;
  final bool isLoading;
  final bool canSubmit;
  final String? loginError;
  final FormFieldValidator<String> emailValidator;
  final FormFieldValidator<String> passwordValidator;
  final VoidCallback onFieldChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleRemember;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        borderRadius: AppTheme.cardLargeRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            _AuthInputField(
              controller: emailController,
              focusNode: emailFocusNode,
              hintText: 'Email',
              icon: Icons.mail_outline,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              validator: emailValidator,
              textInputAction: TextInputAction.next,
              onChanged: (_) => onFieldChanged(),
              onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _AuthInputField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              hintText: 'Mật khẩu',
              icon: Icons.lock_outline,
              enabled: !isLoading,
              obscureText: obscurePassword,
              validator: passwordValidator,
              textInputAction: TextInputAction.done,
              onChanged: (_) => onFieldChanged(),
              onFieldSubmitted: (_) => onLogin(),
              suffixIcon: IconButton(
                onPressed: isLoading ? null : onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                  size: 28,
                ),
              ),
            ),
            if (loginError != null) ...[
              const SizedBox(height: AppTheme.spacing12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loginError!,
                  style: AppTheme.subtitle.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacing14),
            Row(
              children: [
                GestureDetector(
                  onTap: isLoading ? null : onToggleRemember,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: rememberMe ? AppTheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: rememberMe ? AppTheme.primary : AppTheme.border,
                        width: 1.4,
                      ),
                    ),
                    child: rememberMe
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing10),
                Expanded(
                  child: Text(
                    'Ghi nhớ đăng nhập',
                    style: AppTheme.body.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isLoading ? null : onResetPassword,
                  child: Text(
                    'Quên mật khẩu?',
                    style: AppTheme.bodyBold.copyWith(
                      color: AppTheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            _PrimaryAuthButton(
              label: 'Đăng nhập',
              isLoading: isLoading,
              isEnabled: canSubmit,
              onTap: onLogin,
            ),
            const SizedBox(height: AppTheme.spacing16),
            _GoogleButton(
              label: 'Đăng nhập với Google',
              isLoading: isLoading,
              onTap: onGoogleLogin,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Text(
        '汉',
        style: AppTheme.hanziLarge.copyWith(
          fontSize: 82,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

class _AuthInputField extends StatelessWidget {
  const _AuthInputField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTheme.body.copyWith(fontSize: 18),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTheme.body.copyWith(
          color: AppTheme.textSecondary,
          fontSize: 18,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacing16,
            right: AppTheme.spacing10,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 28),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 60),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: AppTheme.inputRadius,
          borderSide: BorderSide(color: AppTheme.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.inputRadius,
          borderSide: BorderSide(color: AppTheme.borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.inputRadius,
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
        ),
        errorMaxLines: 2,
        errorStyle: AppTheme.subtitle.copyWith(color: AppTheme.primary),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.label,
    required this.isLoading,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: AppTheme.primary.withValues(alpha: 0.32),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        ),
        onPressed: isLoading || !isEnabled ? null : onTap,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(label, style: AppTheme.button.copyWith(fontSize: 22)),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.primary, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        ),
        onPressed: isLoading ? null : onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'G',
              style: AppTheme.headingMedium.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: AppTheme.spacing14),
            Text(
              label,
              style: AppTheme.bodyBold.copyWith(
                color: AppTheme.primary,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
