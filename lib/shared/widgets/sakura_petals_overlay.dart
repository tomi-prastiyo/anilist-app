import 'dart:math' as math;
import 'package:flutter/material.dart';

class _SakuraPetal {
  final double xFraction;
  final double yOffset;
  final double size;
  final double speed;
  final double swayAmplitude;
  final double swayPhase;
  final double rotationSpeed;
  final double alpha;
  final Path path;

  _SakuraPetal({
    required this.xFraction,
    required this.yOffset,
    required this.size,
    required this.speed,
    required this.swayAmplitude,
    required this.swayPhase,
    required this.rotationSpeed,
    required this.alpha,
  }) : path = _buildPetalPath(size);

  static Path _buildPetalPath(double size) {
    return Path()
      ..moveTo(0, -size)
      ..quadraticBezierTo(size * 0.85, -size * 0.2, size * 0.45, size * 0.75)
      ..lineTo(0, size * 0.42)
      ..lineTo(-size * 0.45, size * 0.75)
      ..quadraticBezierTo(-size * 0.85, -size * 0.2, 0, -size)
      ..close();
  }
}

/// Lightweight 60fps drifting sakura petals overlay for the YuYuYu theme.
class SakuraPetalsOverlay extends StatefulWidget {
  final Color petalColor;

  const SakuraPetalsOverlay({
    super.key,
    this.petalColor = const Color(0xFFF472B6),
  });

  @override
  State<SakuraPetalsOverlay> createState() => _SakuraPetalsOverlayState();
}

class _SakuraPetalsOverlayState extends State<SakuraPetalsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SakuraPetal> _petals;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    final rng = math.Random(20800);
    _petals = List.generate(14, (_) {
      return _SakuraPetal(
        xFraction: rng.nextDouble(),
        yOffset: rng.nextDouble(),
        size: 5.5 + rng.nextDouble() * 5.0,
        speed: 0.7 + rng.nextDouble() * 0.65,
        swayAmplitude: 14.0 + rng.nextDouble() * 18.0,
        swayPhase: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextBool() ? 1 : -1) * (1.2 + rng.nextDouble() * 2.0),
        alpha: 0.16 + rng.nextDouble() * 0.22,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SakuraPainter(
            animation: _controller,
            petals: _petals,
            baseColor: widget.petalColor,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SakuraPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_SakuraPetal> petals;
  final Color baseColor;
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  _SakuraPainter({
    required this.animation,
    required this.petals,
    required this.baseColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    for (final p in petals) {
      final t = (progress * p.speed + p.yOffset) % 1.0;
      final y = t * (size.height + 40) - 20;
      final sway = math.sin(progress * math.pi * 2 * p.speed + p.swayPhase) * p.swayAmplitude;
      final x = p.xFraction * size.width + sway;
      final angle = progress * math.pi * 2 * p.rotationSpeed + p.swayPhase;

      _paint.color = baseColor.withValues(alpha: p.alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawPath(p.path, _paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SakuraPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor || oldDelegate.petals != petals;
}
