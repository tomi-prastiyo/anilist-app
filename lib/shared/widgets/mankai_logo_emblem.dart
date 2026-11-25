import 'package:flutter/material.dart';
import '../../core/constants/yuyuyu_assets.dart';

/// Shared Hero Club Mankai logo emblem used cleanly across Initial Loading
/// and Login screens with a subtle Shinju gold & sakura twilight glow.
class MankaiLogoEmblem extends StatelessWidget {
  final double size;
  final Color accentColor;
  final double radius;

  const MankaiLogoEmblem({
    super.key,
    this.size = 96,
    this.accentColor = const Color(0xFFF472B6),
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.55),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.34),
            blurRadius: 26,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/mankai_logo.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: YuYuYuAssets.twilightSurface,
          alignment: Alignment.center,
          child: Icon(
            Icons.local_florist_rounded,
            size: size * 0.48,
            color: accentColor,
          ),
        ),
      ),
    );
  }
}
