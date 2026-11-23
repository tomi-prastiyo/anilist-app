import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/score_util.dart';

class ScoreBadge extends StatelessWidget {
  final double? score;
  final String format;
  final double fontSize;

  const ScoreBadge({
    super.key,
    required this.score,
    this.format = 'POINT_100',
    this.fontSize = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    if (score == null || score == 0) return const SizedBox.shrink();

    final color = ScoreUtil.getScoreColor(score);
    final formatted = ScoreUtil.formatScore(score, format: format);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p6, vertical: AppSpacing.p2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: AppSpacing.borderRadius4,
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: fontSize + 2, color: color),
          const SizedBox(width: 2),
          Text(
            formatted,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
