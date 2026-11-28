import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/yuyuyu_assets.dart';

/// Crisp 5-petal Mankai sakura crest with a Shinju-gold stamen center.
class MankaiBlossomGlyph extends StatelessWidget {
  final double size;
  final Color color;
  final Color centerColor;

  const MankaiBlossomGlyph({
    super.key,
    this.size = 14,
    required this.color,
    this.centerColor = YuYuYuAssets.shinjuGold,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _MankaiBlossomPainter(
            petalColor: color,
            centerColor: centerColor,
          ),
        ),
      ),
    );
  }
}

class _MankaiBlossomPainter extends CustomPainter {
  final Color petalColor;
  final Color centerColor;

  const _MankaiBlossomPainter({
    required this.petalColor,
    required this.centerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46;
    final petalPaint = Paint()
      ..color = petalColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final path = Path()
        ..moveTo(0, -radius * 0.14)
        ..cubicTo(
          radius * 0.44,
          -radius * 0.36,
          radius * 0.42,
          -radius * 0.88,
          radius * 0.14,
          -radius * 0.98,
        )
        ..lineTo(0, -radius * 0.80)
        ..lineTo(-radius * 0.14, -radius * 0.98)
        ..cubicTo(
          -radius * 0.42,
          -radius * 0.88,
          -radius * 0.44,
          -radius * 0.36,
          0,
          -radius * 0.14,
        )
        ..close();

      canvas.drawPath(path, petalPaint);
      canvas.restore();
    }

    final centerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius * 0.22, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _MankaiBlossomPainter oldDelegate) =>
      oldDelegate.petalColor != petalColor ||
      oldDelegate.centerColor != centerColor;
}

/// Reusable section header displaying a Mankai blossom glyph + Shinju gold filigree
/// divider in YuYuYu mode, or a crisp minimal dot indicator in Light/Dark mode.
class MankaiSectionHeader extends StatelessWidget {
  final String title;
  final Color dotColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? actionColor;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const MankaiSectionHeader({
    super.key,
    required this.title,
    required this.dotColor,
    this.actionLabel,
    this.onAction,
    this.actionColor,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
  });

  @override
  Widget build(BuildContext context) {
    final isYuYuYu = context.isYuYuYu;
    final resolvedActionColor = actionColor ?? context.appAccent;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (isYuYuYu)
            MankaiBlossomGlyph(size: 13, color: context.appAccent)
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Overpass',
              color: context.appTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: isYuYuYu ? 0.7 : 0.6,
            ),
          ),
          if (isYuYuYu)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      YuYuYuAssets.shinjuGold.withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          if (trailing != null)
            trailing!
          else if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    fontFamily: 'Overpass',
                    color: resolvedActionColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Delicate 1px Shinju-gold & Heroine accent hairline divider for Hero Terminal UI.
class MankaiGoldHairline extends StatelessWidget {
  final double opacity;

  const MankaiGoldHairline({super.key, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            YuYuYuAssets.shinjuGold.withValues(alpha: 0.35 * opacity),
            context.appAccent.withValues(alpha: 0.25 * opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Subtle non-blocking radial Jukai twilight glow + sacred Hero Terminal halo ring.
class MankaiJukaiBackdrop extends StatelessWidget {
  final Color accentColor;

  const MankaiJukaiBackdrop({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _JukaiTerminalPainter(accentColor: accentColor),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _JukaiTerminalPainter extends CustomPainter {
  final Color accentColor;

  const _JukaiTerminalPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final haloCenter = Offset(size.width * 0.92, size.height * 0.10);
    final auraRadius = size.width * 0.72;

    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.08),
          YuYuYuAssets.jukaiGlow.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Rect.fromCircle(center: haloCenter, radius: auraRadius));

    canvas.drawCircle(haloCenter, auraRadius, auraPaint);

    final ringPaint = Paint()
      ..color = YuYuYuAssets.shinjuGold.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    const innerRadius = 92.0;
    const outerRadius = 114.0;
    canvas.drawCircle(haloCenter, innerRadius, ringPaint);
    canvas.drawCircle(haloCenter, outerRadius, ringPaint);

    for (var i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final p1 = Offset(
        haloCenter.dx + math.cos(angle) * innerRadius,
        haloCenter.dy + math.sin(angle) * innerRadius,
      );
      final p2 = Offset(
        haloCenter.dx + math.cos(angle) * (outerRadius + 10),
        haloCenter.dy + math.sin(angle) * (outerRadius + 10),
      );
      canvas.drawLine(p1, p2, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _JukaiTerminalPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
