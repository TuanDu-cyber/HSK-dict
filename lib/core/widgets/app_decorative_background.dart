import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppDecorativeBackground extends StatelessWidget {
  const AppDecorativeBackground({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.showCherry = true,
  });

  final Widget child;
  final bool useSafeArea;
  final bool showCherry;

  @override
  Widget build(BuildContext context) {
    final content = useSafeArea ? SafeArea(child: child) : child;

    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppTheme.background)),
        IgnorePointer(
          child: Stack(
            children: [
              if (showCherry)
                Positioned(
                  top: 44,
                  right: -58,
                  child: Opacity(
                    opacity: 0.12,
                    child: CustomPaint(
                      size: const Size(220, 170),
                      painter: _CherryPetalPainter(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned.fill(child: content),
      ],
    );
  }
}

class _CherryPetalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final branchPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.14)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final petalPaint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final branch = Path()
      ..moveTo(size.width * 0.12, size.height * 0.74)
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
      13,
      petalPaint,
      centerPaint,
    );
    _drawFlower(
      canvas,
      Offset(size.width * 0.56, size.height * 0.36),
      15,
      petalPaint,
      centerPaint,
    );
    _drawFlower(
      canvas,
      Offset(size.width * 0.76, size.height * 0.25),
      12,
      petalPaint,
      centerPaint,
    );
    _drawFlower(
      canvas,
      Offset(size.width * 0.46, size.height * 0.68),
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
