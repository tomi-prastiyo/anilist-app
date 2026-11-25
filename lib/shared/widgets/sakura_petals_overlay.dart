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

  const _SakuraPetal({
    required this.xFraction,
    required this.yOffset,
    required this.size,
    required this.speed,
    required this.swayAmplitude,
    required this.swayPhase,
    required this.rotationSpeed,
    required this.alpha,
  });
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SakuraPainter(
              progress: _controller.value,
              petals: _petals,
              baseColor: widget.petalColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SakuraPainter extends CustomPainter {
  final double progress;
  final List<_SakuraPetal> petals;
  final Color baseColor;

  _SakuraPainter({
    required this.progress,
    required this.petals,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in petals) {
      final t = (progress * p.speed + p.yOffset) % 1.0;
      final y = t * (size.height + 40) - 20;
      final sway = math.sin(progress * math.pi * 2 * p.speed + p.swayPhase) * p.swayAmplitude;
      final x = p.xFraction * size.width + sway;
      final angle = progress * math.pi * 2 * p.rotationSpeed + p.swayPhase;

      paint.color = baseColor.withValues(alpha: p.alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      // Notched sakura petal silhouette
      final path = Path()
        ..moveTo(0, -p.size)
        ..quadraticBezierTo(p.size * 0.85, -p.size * 0.2, p.size * 0.45, p.size * 0.75)
        ..lineTo(0, p.size * 0.42)
        ..lineTo(-p.size * 0.45, p.size * 0.75)
        ..quadraticBezierTo(-p.size * 0.85, -p.size * 0.2, 0, -p.size)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SakuraPainter oldDelegate) => oldDelegate.progress != progress;
}
