import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Logo ServioRL — hexagon icon + wordmark
/// Bisa dipakai di AppBar atau splash screen
class ServioRLLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const ServioRLLogo({super.key, this.size = 28, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hexagon icon
        CustomPaint(
          size: Size(size, size),
          painter: _HexPainter(),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Servio',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: size * 0.68,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'RL',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: size * 0.68,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Draws the teal hexagon "S" icon
class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w * 0.48;

    // Hexagon path
    final hex = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * (3.14159265 / 180);
      final x = cx + r * Math.cos(angle);
      final y = cy + r * Math.sin(angle);
      if (i == 0) {
        hex.moveTo(x, y);
      } else {
        hex.lineTo(x, y);
      }
    }
    hex.close();

    // Gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF00D4AA),
        const Color(0xFF00A882),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(
      hex,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill,
    );

    // "S" shape — two offset rectangles
    final paint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;

    final rr = w * 0.12;
    final barH = h * 0.14;
    final barW = w * 0.32;

    // Top bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - w * 0.04, cy - h * 0.18),
          width: barW,
          height: barH,
        ),
        Radius.circular(rr),
      ),
      paint,
    );

    // Middle bar (diagonal feel)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: barW * 0.9,
          height: barH,
        ),
        Radius.circular(rr),
      ),
      paint,
    );

    // Bottom bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + w * 0.04, cy + h * 0.18),
          width: barW,
          height: barH,
        ),
        Radius.circular(rr),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// Minimal math helpers (avoid dart:math import bloat)
class Math {
  static double cos(double r) => _cos(r);
  static double sin(double r) => _sin(r);

  static double _cos(double x) {
    double result = 1, term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  static double _sin(double x) {
    double result = x, term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}
