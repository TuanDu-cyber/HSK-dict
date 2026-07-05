import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({
    super.key,
    required this.child,
    this.showCherry = true,
    this.opacity = 0.8,
    this.useSafeArea = true,
  });

  final Widget child;
  final bool showCherry;
  final double opacity;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppTheme.background)),
        if (showCherry)
          Positioned(
            right: -24,
            top: 110,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity * 0.16,
                child: CustomPaint(
                  size: const Size(180, 140),
                  painter: _CherryPetalPainter(),
                ),
              ),
            ),
          ),
        Positioned.fill(child: useSafeArea ? SafeArea(child: child) : child),
      ],
    );
  }
}

class _CherryPetalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final branchPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.14)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final petalPaint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final branch = Path()
      ..moveTo(size.width * 0.1, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.38,
        size.width * 0.92,
        size.height * 0.2,
      );
    canvas.drawPath(branch, branchPaint);

    _drawFlower(
      canvas,
      Offset(size.width * 0.34, size.height * 0.55),
      11,
      petalPaint,
      centerPaint,
    );
    _drawFlower(
      canvas,
      Offset(size.width * 0.58, size.height * 0.36),
      13,
      petalPaint,
      centerPaint,
    );
    _drawFlower(
      canvas,
      Offset(size.width * 0.76, size.height * 0.26),
      10,
      petalPaint,
      centerPaint,
    );
  }

  void _drawFlower(
    Canvas canvas,
    Offset center,
    double radius,
    Paint petalPaint,
    Paint centerPaint,
  ) {
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * 1.256);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -radius * 0.72),
          width: radius * 0.9,
          height: radius * 1.35,
        ),
        petalPaint,
      );
      canvas.restore();
    }

    canvas.drawCircle(center, radius * 0.22, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _CherryPetalPainter oldDelegate) {
    return false;
  }
}
