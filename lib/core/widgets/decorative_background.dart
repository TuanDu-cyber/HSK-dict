import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({
    super.key,
    required this.child,
    this.cherryBlossomAsset,
    this.lanternAsset,
    this.cloudAsset,
    this.mountainAsset,
    this.showCherry = true,
    this.showLantern = false,
    this.showCloud = true,
    this.showMountain = true,
    this.opacity = 0.8,
    this.useSafeArea = true,
  });

  final Widget child;

  /// Ví dụ:
  /// assets/images/cherry_blossom.png
  final String? cherryBlossomAsset;

  /// Ví dụ:
  /// assets/images/lantern.png
  final String? lanternAsset;

  /// Ví dụ:
  /// assets/images/cloud.png
  final String? cloudAsset;

  /// Ví dụ:
  /// assets/images/mountain.png
  final String? mountainAsset;

  final bool showCherry;
  final bool showLantern;
  final bool showCloud;
  final bool showMountain;
  final double opacity;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: AppTheme.background)),
        if (showMountain && mountainAsset != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.14,
                child: Image.asset(
                  mountainAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        if (showCloud && cloudAsset != null)
          Positioned(
            left: -20,
            top: 150,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  cloudAsset!,
                  width: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        if (showLantern && lanternAsset != null)
          Positioned(
            right: 76,
            top: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  lanternAsset!,
                  width: 58,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        if (showCherry && cherryBlossomAsset != null)
          Positioned(
            right: -24,
            top: 110,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  cherryBlossomAsset!,
                  width: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        Positioned.fill(child: useSafeArea ? SafeArea(child: child) : child),
      ],
    );

    return content;
  }
}
