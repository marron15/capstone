import 'package:flutter/material.dart';

import '../services/landing_visit_service.dart';

/// Shared sizing with hero [OutlinedButton] / [ElevatedButton] CTAs on the landing page.
class HeroCtaStyle {
  HeroCtaStyle._();

  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(4));
  static const BorderSide outlinedBorder = BorderSide(
    color: Colors.white,
    width: 2,
  );
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 32,
    vertical: 20,
  );
  static const TextStyle labelStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle visitLabelStyle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle visitCountStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );
}

class EyeOutlineIcon extends StatelessWidget {
  final Color color;
  final double size;

  const EyeOutlineIcon({super.key, required this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EyeOutlinePainter(color)),
    );
  }
}

class _EyeOutlinePainter extends CustomPainter {
  final Color color;

  _EyeOutlinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double shortestSide = size.shortestSide;
    final Paint outlinePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = shortestSide * 0.12
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final Paint pupilPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double eyeWidth = size.width * 0.86;
    final double eyeHeight = size.height * 0.46;
    final Rect eyeBounds = Rect.fromCenter(
      center: center,
      width: eyeWidth,
      height: eyeHeight,
    );

    final Path eyePath =
        Path()
          ..moveTo(eyeBounds.left, center.dy)
          ..quadraticBezierTo(
            eyeBounds.left + eyeWidth * 0.22,
            eyeBounds.top,
            center.dx,
            eyeBounds.top,
          )
          ..quadraticBezierTo(
            eyeBounds.right - eyeWidth * 0.22,
            eyeBounds.top,
            eyeBounds.right,
            center.dy,
          )
          ..quadraticBezierTo(
            eyeBounds.right - eyeWidth * 0.22,
            eyeBounds.bottom,
            center.dx,
            eyeBounds.bottom,
          )
          ..quadraticBezierTo(
            eyeBounds.left + eyeWidth * 0.22,
            eyeBounds.bottom,
            eyeBounds.left,
            center.dy,
          );

    canvas.drawPath(eyePath, outlinePaint);
    canvas.drawCircle(center, shortestSide * 0.14, pupilPaint);
  }

  @override
  bool shouldRepaint(covariant _EyeOutlinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Compact visit counter for the hero row (right of Register Now).
class HeroVisitCountBadge extends StatefulWidget {
  const HeroVisitCountBadge({super.key});

  @override
  State<HeroVisitCountBadge> createState() => _HeroVisitCountBadgeState();
}

class _HeroVisitCountBadgeState extends State<HeroVisitCountBadge> {
  LandingVisitStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats =
        await LandingVisitService.recordVisit() ??
        await LandingVisitService.fetchStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  String _formatCount(int count) {
    final String digits = count.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: HeroCtaStyle.padding,
      child:
          _isLoading
              ? const SizedBox(
                width: 120,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                ),
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EyeOutlineIcon(color: Color(0xFFFF8C00)),
                  const SizedBox(width: 10),
                  const Text(
                    'Visit count: ',
                    style: HeroCtaStyle.visitLabelStyle,
                  ),
                  Text(
                    _formatCount(_stats?.visitCount ?? 0),
                    style: HeroCtaStyle.visitCountStyle,
                  ),
                ],
              ),
    );
  }
}
