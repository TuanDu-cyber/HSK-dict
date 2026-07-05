import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_decorative_background.dart';
import '../../repositories/notification_repository.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreePolicy = false;
  XFile? _avatarImage;

  bool get _canSubmit => _agreePolicy;

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    });

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
              Text(
                'HSK Dict',
                style: AppTheme.headingXLarge.copyWith(
                  color: AppTheme.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Tạo tài khoản',
                style: AppTheme.headingXLarge.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Đăng ký để bắt đầu\nhành trình học tiếng Trung',
                style: AppTheme.body.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 20,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTheme.spacing14),
              const _FreeBadge(),
              const SizedBox(height: AppTheme.spacing20),
              Center(
                child: _RegisterAvatar(
                  image: _avatarImage,
                  onTap: authState.isLoading ? null : _pickAvatar,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              _RegisterFormCard(
                formKey: _formKey,
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                nameFocusNode: _nameFocusNode,
                emailFocusNode: _emailFocusNode,
                passwordFocusNode: _passwordFocusNode,
                confirmPasswordFocusNode: _confirmPasswordFocusNode,
                obscurePassword: _obscurePassword,
                obscureConfirmPassword: _obscureConfirmPassword,
                agreePolicy: _agreePolicy,
                isLoading: authState.isLoading,
                canSubmit: _canSubmit,
                nameValidator: _validateName,
                emailValidator: _validateEmail,
                passwordValidator: _validatePassword,
                confirmPasswordValidator: _validateConfirmPassword,
                onTogglePassword: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onToggleConfirmPassword: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                onTogglePolicy: () {
                  setState(() {
                    _agreePolicy = !_agreePolicy;
                  });
                },
                onRegister: _handleRegister,
                onGoogleLogin: _handleLoginWithGoogle,
              ),
              const SizedBox(height: AppTheme.spacing20),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 17,
                      ),
                    ),
                    GestureDetector(
                      onTap: authState.isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: Text(
                        'Đăng nhập',
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

  Future<void> _handleRegister() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || !_agreePolicy) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final didRegister = await ref
        .read(authProvider.notifier)
        .register(
          name: name,
          email: email,
          password: password,
          avatarImage: _avatarImage,
        );

    if (didRegister && mounted) {
      await ref
          .read(notificationRepositoryProvider)
          .scheduleDailyStreakReminder();
      if (!mounted) return;
      context.go(AppRoutes.home);
    }
  }

  Future<void> _pickAvatar() async {
    final image = await ref.read(authProvider.notifier).pickAvatarFromGallery();

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _avatarImage = image;
    });
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

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) return 'Vui lòng nhập họ và tên.';
    if (name.length < 2) return 'Tên phải có ít nhất 2 ký tự.';
    if (!RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(name)) {
      return 'Tên cần có chữ cái, không chỉ gồm số/ký tự đặc biệt.';
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
    final password = value ?? '';

    if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (password.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự.';
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Mật khẩu nên có cả chữ và số.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';

    if (confirmPassword.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
    if (confirmPassword != _passwordController.text) {
      return 'Mật khẩu xác nhận không trùng khớp.';
    }

    return null;
  }
}

class _RegisterFormCard extends StatelessWidget {
  const _RegisterFormCard({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nameFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.agreePolicy,
    required this.isLoading,
    required this.canSubmit,
    required this.nameValidator,
    required this.emailValidator,
    required this.passwordValidator,
    required this.confirmPasswordValidator,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onTogglePolicy,
    required this.onRegister,
    required this.onGoogleLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final FocusNode nameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool agreePolicy;
  final bool isLoading;
  final bool canSubmit;
  final FormFieldValidator<String> nameValidator;
  final FormFieldValidator<String> emailValidator;
  final FormFieldValidator<String> passwordValidator;
  final FormFieldValidator<String> confirmPasswordValidator;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onTogglePolicy;
  final VoidCallback onRegister;
  final VoidCallback onGoogleLogin;

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
            _RegisterInputField(
              controller: nameController,
              focusNode: nameFocusNode,
              hintText: 'Họ và tên',
              icon: Icons.person,
              enabled: !isLoading,
              keyboardType: TextInputType.name,
              validator: nameValidator,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => emailFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppTheme.spacing14),
            _RegisterInputField(
              controller: emailController,
              focusNode: emailFocusNode,
              hintText: 'Email',
              icon: Icons.mail,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              validator: emailValidator,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppTheme.spacing14),
            _RegisterInputField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              hintText: 'Mật khẩu',
              icon: Icons.lock,
              enabled: !isLoading,
              obscureText: obscurePassword,
              validator: passwordValidator,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => confirmPasswordFocusNode.requestFocus(),
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
            const SizedBox(height: AppTheme.spacing14),
            _RegisterInputField(
              controller: confirmPasswordController,
              focusNode: confirmPasswordFocusNode,
              hintText: 'Xác nhận mật khẩu',
              icon: Icons.lock,
              enabled: !isLoading,
              obscureText: obscureConfirmPassword,
              validator: confirmPasswordValidator,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onRegister(),
              suffixIcon: IconButton(
                onPressed: isLoading ? null : onToggleConfirmPassword,
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                GestureDetector(
                  onTap: isLoading ? null : onTogglePolicy,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: agreePolicy
                          ? AppTheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: agreePolicy ? AppTheme.primary : AppTheme.border,
                        width: 1.4,
                      ),
                    ),
                    child: agreePolicy
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                      children: [
                        const TextSpan(text: 'Tôi đồng ý với '),
                        TextSpan(
                          text: 'điều khoản và chính sách',
                          style: AppTheme.bodyBold.copyWith(
                            color: AppTheme.primary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing24),
            _PrimaryRegisterButton(
              label: 'Đăng ký',
              isLoading: isLoading,
              isEnabled: canSubmit,
              onTap: onRegister,
            ),
            const SizedBox(height: AppTheme.spacing20),
            _GoogleRegisterButton(isLoading: isLoading, onTap: onGoogleLogin),
          ],
        ),
      ),
    );
  }
}

class _RegisterInputField extends StatelessWidget {
  const _RegisterInputField({
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

class _RegisterAvatar extends StatelessWidget {
  const _RegisterAvatar({required this.image, required this.onTap});

  final XFile? image;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 138,
            height: 138,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: ClipOval(child: _AvatarPreview(image: image)),
          ),
          Positioned(
            right: -2,
            bottom: 6,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: onTap == null
                    ? AppTheme.primary.withValues(alpha: 0.55)
                    : AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_camera,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.image});

  final XFile? image;

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Image.file(
        File(image!.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _DefaultRegisterAvatar(),
      );
    }

    return Image.asset(
      'assets/images/avatar_default.png',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _DefaultRegisterAvatar(),
    );
  }
}

class _DefaultRegisterAvatar extends StatelessWidget {
  const _DefaultRegisterAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.tagBg,
      child: Icon(
        Icons.person,
        color: AppTheme.textSecondary.withValues(alpha: 0.45),
        size: 62,
      ),
    );
  }
}

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.pillBg,
        borderRadius: AppTheme.buttonRadius,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, color: AppTheme.primary, size: 22),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            'Hoàn toàn miễn phí',
            style: AppTheme.bodyBold.copyWith(
              color: AppTheme.primary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryRegisterButton extends StatelessWidget {
  const _PrimaryRegisterButton({
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

class _GoogleRegisterButton extends StatelessWidget {
  const _GoogleRegisterButton({required this.isLoading, required this.onTap});

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
              'Tiếp tục với Google',
              style: AppTheme.bodyBold.copyWith(
                color: AppTheme.textPrimary,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
