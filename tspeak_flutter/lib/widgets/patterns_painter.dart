import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BogolanPainter extends CustomPainter {
  final Color color;
  final double opacity;

  BogolanPainter({
    required this.color,
    this.opacity = 0.03,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    const double spacing = 80.0;
    const double patternSize = 20.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Draw a stylized cross/plus
        final Path path = Path();
        
        // Offset each row for a more organic feel
        double offsetX = (y / spacing) % 2 == 0 ? 0 : spacing / 2;
        double currentX = x + offsetX;

        // Simplified version of the SVG path
        _drawCross(path, currentX, y, patternSize);
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawCross(Path path, double x, double y, double size) {
    double half = size / 2;
    double thickness = size / 4;
    
    // Horizontal bar
    path.addRect(Rect.fromLTWH(x - half, y - thickness / 2, size, thickness));
    // Vertical bar
    path.addRect(Rect.fromLTWH(x - thickness / 2, y - half, thickness, size));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  final bool showPatterns;

  const BackgroundWrapper({
    super.key,
    required this.child,
    this.showPatterns = true,
  });

  @override
  Widget childBuild(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.surface),
        if (showPatterns)
          Positioned.fill(
            child: CustomPaint(
              painter: BogolanPainter(color: AppColors.primary),
            ),
          ),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return childBuild(context);
  }
}
