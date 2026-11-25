import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/tactile_scale.dart';

/// Shared quick-increment pill(s) used on both Anime/Manga ProgressShelfCard
/// and MediaCard (neo/compact/grid). Supports a single `+1` mode (Anime) or
/// dual `+Ch` + `+Vol` mode (Manga).
class ProgressIncrementPills extends StatelessWidget {
  final Color accentColor;
  final Color primaryTextColor;
  final VoidCallback onIncrementPrimary;
  final VoidCallback? onIncrementVolume;
  final bool compact;
  final bool stacked;

  const ProgressIncrementPills({
    super.key,
    required this.accentColor,
    required this.primaryTextColor,
    required this.onIncrementPrimary,
    this.onIncrementVolume,
    this.compact = false,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasVolume = onIncrementVolume != null;
    final primaryLabel = hasVolume ? '+Ch' : '+1';

    final primaryBtn = _buildPill(
      label: primaryLabel,
      onTap: onIncrementPrimary,
      isOutlined: false,
      height: compact ? 25 : 28,
      minWidth: hasVolume ? (stacked ? 38 : 34) : (compact ? 28 : 32),
      fontSize: hasVolume ? (compact || stacked ? 9.5 : 10.5) : (compact ? 11 : 12),
    );

    if (!hasVolume) return primaryBtn;

    final volBtn = _buildPill(
      label: '+Vol',
      onTap: onIncrementVolume!,
      isOutlined: true,
      height: compact ? 25 : 28,
      minWidth: stacked ? 38 : 36,
      fontSize: compact || stacked ? 9.5 : 10.5,
    );

    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          primaryBtn,
          const SizedBox(height: 4),
          volBtn,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        primaryBtn,
        SizedBox(width: compact ? 4 : 5),
        volBtn,
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required VoidCallback onTap,
    required bool isOutlined,
    required double height,
    required double minWidth,
    required double fontSize,
  }) {
    return TactileScale(
      pressedScale: 0.90,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth),
        height: height,
        padding: EdgeInsets.symmetric(horizontal: compact || stacked ? 6 : 8),
        decoration: BoxDecoration(
          color: isOutlined ? accentColor.withValues(alpha: 0.14) : accentColor,
          borderRadius: BorderRadius.circular(compact || stacked ? 6 : 8),
          border: isOutlined
              ? Border.all(color: accentColor.withValues(alpha: 0.55), width: 1)
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.32),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            height: 1.0,
            color: isOutlined ? accentColor : primaryTextColor,
          ),
        ),
      ),
    );
  }
}
