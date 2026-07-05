import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_decorative_background.dart';
import '../../core/widgets/bottom_nav.dart';

import '../auth/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static const String _defaultAvatarAsset = 'assets/images/avatar_default.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

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
      backgroundColor: AppTheme.background,
      body: AppDecorativeBackground(
        useSafeArea: true,
        child: authState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.screenPadding,
                        AppTheme.spacing24,
                        AppTheme.screenPadding,
                        AppTheme.spacing32,
                      ),
                      child: Column(
                        children: [
                          const _AccountHeaderTitle(),
                          const SizedBox(height: AppTheme.spacing20),
                          _AvatarSection(
                            avatarUrl: user?.avatarUrl,
                            defaultAvatarAsset: _defaultAvatarAsset,
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          _ProfileInfo(
                            name: user?.name ?? 'Learner',
                            email: user?.email ?? 'Chưa đăng nhập',
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          _AccountMenuCard(
                            name: user?.name ?? 'Learner',
                            email: user?.email ?? '',
                          ),
                        ],
                      ),
                    ),
                  ),
                  BottomNav(
                    currentIndex: 3,
                    onTap: (index) {
                      switch (index) {
                        case 0:
                          context.go(AppRoutes.home);
                          break;
                        case 1:
                          context.go(AppRoutes.search);
                          break;
                        case 2:
                          context.go(AppRoutes.gameTopics);
                          break;
                        case 3:
                          context.go(AppRoutes.account);
                          break;
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _AccountHeaderTitle extends StatelessWidget {
  const _AccountHeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Tài khoản',
        style: AppTheme.headingLarge.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AvatarSection extends ConsumerWidget {
  const _AvatarSection({
    required this.avatarUrl,
    required this.defaultAvatarAsset,
  });

  final String? avatarUrl;
  final String defaultAvatarAsset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 155,
            height: 155,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              boxShadow: AppTheme.cardShadow,
            ),
            child: ClipOval(
              child: _AvatarImage(
                avatarUrl: avatarUrl,
                defaultAvatarAsset: defaultAvatarAsset,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 12,
            child: Material(
              color: AppTheme.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  final didUpdate = await ref
                      .read(authProvider.notifier)
                      .updateAvatarFromGallery();

                  if (!context.mounted || !didUpdate) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật ảnh đại diện'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
                child: const SizedBox(
                  width: 58,
                  height: 58,
                  child: Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.avatarUrl,
    required this.defaultAvatarAsset,
  });

  final String? avatarUrl;
  final String defaultAvatarAsset;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _DefaultAvatar(defaultAvatarAsset: defaultAvatarAsset);
        },
      );
    }

    return _DefaultAvatar(defaultAvatarAsset: defaultAvatarAsset);
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.defaultAvatarAsset});

  final String defaultAvatarAsset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      defaultAvatarAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return Container(
          color: AppTheme.tagBg,
          child: const Icon(Icons.person, size: 70, color: AppTheme.primary),
        );
      },
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final emailText = email.trim().isEmpty ? 'Chưa đăng nhập' : email;

    return Column(
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: AppTheme.headingLarge.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing20,
            vertical: AppTheme.spacing12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.tagBg.withValues(alpha: 0.75),
            borderRadius: AppTheme.buttonRadius,
            border: Border.all(
              color: AppTheme.primaryLight.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mail_outline, color: AppTheme.primary, size: 22),
              const SizedBox(width: AppTheme.spacing10),
              Flexible(
                child: Text(
                  emailText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _AccountMenuCard extends ConsumerWidget {
  const _AccountMenuCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _AccountMenuItem(
            icon: Icons.edit_note_outlined,
            title: 'Sửa hồ sơ',
            onTap: () {
              _showEditProfileSheet(context, ref);
            },
          ),
          const _MenuDivider(),
          _AccountMenuItem(
            icon: Icons.bookmark_border,
            title: 'Từ vựng đã sao lưu',
            onTap: () {
              context.push(AppRoutes.favorites);
            },
          ),
          const _MenuDivider(),
          _AccountMenuItem(
            icon: Icons.logout,
            title: 'Đăng xuất',
            isDanger: true,
            onTap: authState.isLoading
                ? null
                : () {
                    _showLogoutDialog(context, ref);
                  },
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: name);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusCardLarge),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacing24,
            right: AppTheme.spacing24,
            top: AppTheme.spacing24,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sửa hồ sơ', style: AppTheme.headingMedium),
              const SizedBox(height: AppTheme.spacing20),
              _EditTextField(
                controller: nameController,
                label: 'Tên',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Email đăng nhập không sửa ở đây. Email được quản lý bởi Firebase Auth.',
                style: AppTheme.subtitle.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.buttonRadius,
                    ),
                  ),
                  onPressed: () {
                    _showChangePasswordDialog(context, ref);
                  },
                  icon: const Icon(Icons.lock_reset_outlined),
                  label: const Text('Đổi mật khẩu'),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.buttonRadius,
                    ),
                  ),
                  onPressed: () async {
                    await ref
                        .read(authProvider.notifier)
                        .updateProfile(name: nameController.text);

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Lưu thay đổi', style: AppTheme.button),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    if (!ref.read(authProvider.notifier).canChangePassword) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
            title: Text('Đổi mật khẩu', style: AppTheme.headingMedium),
            content: const Text(
              'Tài khoản Google không đổi mật khẩu trong app. Vui lòng quản lý mật khẩu bằng Google.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    var isLoading = false;
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (isLoading) return;

              final isValid = formKey.currentState?.validate() ?? false;
              if (!isValid) return;

              setDialogState(() {
                isLoading = true;
              });

              final error = await ref
                  .read(authProvider.notifier)
                  .changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Đổi mật khẩu thành công'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
              title: Text('Đổi mật khẩu', style: AppTheme.headingMedium),
              content: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PasswordTextField(
                        controller: currentPasswordController,
                        label: 'Mật khẩu hiện tại',
                        obscureText: obscureCurrent,
                        enabled: !isLoading,
                        validator: _validateCurrentPassword,
                        onToggle: () {
                          setDialogState(() {
                            obscureCurrent = !obscureCurrent;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing14),
                      _PasswordTextField(
                        controller: newPasswordController,
                        label: 'Mật khẩu mới',
                        obscureText: obscureNew,
                        enabled: !isLoading,
                        validator: _validateNewPassword,
                        onToggle: () {
                          setDialogState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing14),
                      _PasswordTextField(
                        controller: confirmPasswordController,
                        label: 'Xác nhận mật khẩu mới',
                        obscureText: obscureConfirm,
                        enabled: !isLoading,
                        validator: (value) => _validateConfirmPassword(
                          value,
                          newPasswordController.text,
                        ),
                        onToggle: () {
                          setDialogState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.buttonSmallRadius,
                    ),
                  ),
                  onPressed: isLoading ? null : submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Cập nhật'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  String? _validateCurrentPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại';
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) return 'Vui lòng nhập mật khẩu mới';
    if (password.length < 8) return 'Mật khẩu mới cần ít nhất 8 ký tự';
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(password)) {
      return 'Mật khẩu mới nên có cả chữ và số';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value, String password) {
    final confirm = value ?? '';

    if (confirm.isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
    if (confirm != password) return 'Mật khẩu xác nhận không trùng';

    return null;
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isLoggingOut = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
              title: Text('Đăng xuất', style: AppTheme.headingMedium),
              content: Text(
                'Bạn có chắc muốn đăng xuất?',
                style: AppTheme.body,
              ),
              actions: [
                TextButton(
                  onPressed: isLoggingOut
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text('Hủy', style: AppTheme.pinyin),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.buttonSmallRadius,
                    ),
                  ),
                  onPressed: isLoggingOut
                      ? null
                      : () async {
                          setDialogState(() {
                            isLoggingOut = true;
                          });

                          final didLogout = await ref
                              .read(authProvider.notifier)
                              .logout();

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (!context.mounted) return;

                          if (didLogout) {
                            context.go(AppRoutes.authGate);
                          }
                        },
                  child: isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Đăng xuất'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EditTextField extends StatelessWidget {
  const _EditTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTheme.body,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(
          borderRadius: AppTheme.inputRadius,
          borderSide: BorderSide(
            color: AppTheme.primaryLight.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.inputRadius,
          borderSide: BorderSide(
            color: AppTheme.primaryLight.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.inputRadius,
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _PasswordTextField extends StatelessWidget {
  const _PasswordTextField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.enabled,
    required this.validator,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool enabled;
  final FormFieldValidator<String> validator;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      validator: validator,
      style: AppTheme.body,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
        suffixIcon: IconButton(
          onPressed: enabled ? onToggle : null,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppTheme.textSecondary,
          ),
        ),
        filled: true,
        fillColor: AppTheme.background,
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: AppTheme.inputRadius,
          borderSide: BorderSide(
            color: AppTheme.primaryLight.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.inputRadius,
          borderSide: BorderSide(
            color: AppTheme.primaryLight.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.inputRadius,
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppTheme.primary : AppTheme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.cardLargeRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing24,
            vertical: AppTheme.spacing24,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 32),
              const SizedBox(width: AppTheme.spacing20),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.headingMedium.copyWith(
                    color: color,
                    fontSize: 22,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 76, right: AppTheme.spacing24),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.primaryLight.withValues(alpha: 0.22),
      ),
    );
  }
}
