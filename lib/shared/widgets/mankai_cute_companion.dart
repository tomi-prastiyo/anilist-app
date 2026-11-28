import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/yuyuyu_assets.dart';

/// Playful animated YuYuYu chibi/fairy companion with idle bob/sway,
/// interactive hop + sparkle burst on tap, and optional greeting bubble.
class MankaiFloatingMascot extends StatefulWidget {
  final String assetPath;
  final Color accentColor;
  final String? greetingText;
  final double size;
  final bool showGlow;
  final bool interactive;
  final bool showBubbleOnTap;
  final VoidCallback? onTap;

  const MankaiFloatingMascot({
    super.key,
    required this.assetPath,
    required this.accentColor,
    this.greetingText,
    this.size = 96,
    this.showGlow = true,
    this.interactive = true,
    this.showBubbleOnTap = true,
    this.onTap,
  });

  @override
  State<MankaiFloatingMascot> createState() => _MankaiFloatingMascotState();
}

class _MankaiFloatingMascotState extends State<MankaiFloatingMascot>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _hopController;
  Timer? _bubbleTimer;
  bool _showBubble = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _idleController.dispose();
    _hopController.dispose();
    super.dispose();
  }

  void _triggerReaction() {
    HapticFeedback.lightImpact();
    _hopController.forward(from: 0);
    if (widget.showBubbleOnTap && widget.greetingText != null) {
      setState(() => _showBubble = true);
      _bubbleTimer?.cancel();
      _bubbleTimer = Timer(const Duration(milliseconds: 2400), () {
        if (mounted) setState(() => _showBubble = false);
      });
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (widget.showGlow)
          Container(
            width: widget.size * 0.92,
            height: widget.size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.accentColor.withValues(alpha: 0.28),
                  YuYuYuAssets.shinjuGold.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_idleController, _hopController]),
            builder: (context, mascotChild) {
              final idleT = Curves.easeInOutSine.transform(_idleController.value);
              final idleY = (idleT - 0.5) * 6.0;
              final idleRot = (idleT - 0.5) * 0.06;

              final hopV = _hopController.value;
              final hopArc = math.sin(hopV * math.pi);
              final hopY = -hopArc * 13.0;
              final scaleX = 1.0 + (hopV > 0 && hopV < 1 ? hopArc * 0.09 : 0.0);
              final scaleY = 1.0 + (hopV > 0 && hopV < 1 ? hopArc * 0.12 : 0.0);

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, idleY + hopY),
                    child: Transform.rotate(
                      angle: idleRot,
                      child: Transform.scale(
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: mascotChild,
                      ),
                    ),
                  ),
                  if (_hopController.isAnimating)
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size(widget.size * 1.45, widget.size * 1.45),
                        painter: _MascotSparklePainter(
                          progress: _hopController.value,
                          accentColor: widget.accentColor,
                        ),
                      ),
                    ),
                ],
              );
            },
            child: Image.asset(
              widget.assetPath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        if (_showBubble && widget.greetingText != null)
          Positioned(
            bottom: widget.size + 4,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 210),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.appSurface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.65),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                widget.greetingText!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ),
          ),
      ],
    );

    if (!widget.interactive) {
      return SizedBox(width: widget.size, height: widget.size, child: child);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerReaction,
        child: child,
      ),
    );
  }
}

class _MascotSparklePainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  const _MascotSparklePainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.46;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final radiusProgress = Curves.easeOut.transform(progress);

    for (var i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - (math.pi / 6);
      final dist = maxR * (0.35 + radiusProgress * 0.65);
      final pos = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );
      final color = (i.isEven ? accentColor : YuYuYuAssets.shinjuGold)
          .withValues(alpha: opacity * 0.9);
      final dotRadius = (3.4 * (1.0 - progress * 0.55)).clamp(1.0, 4.0);
      canvas.drawCircle(pos, dotRadius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotSparklePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accentColor != accentColor;
}
