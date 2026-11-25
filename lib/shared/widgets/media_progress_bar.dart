import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Calm, non-bouncing progress bar for both known-total and ongoing (`?`) media.
class MediaProgressBar extends StatelessWidget {
  final int progress;
  final int? total;
  final Color color;
  final double height;

  const MediaProgressBar({
    super.key,
    required this.progress,
    required this.total,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTotal = total != null && total! > 0;
    final double ratio;
    if (hasTotal) {
      ratio = (progress / total!).clamp(0.0, 1.0);
    } else {
      // Ongoing/unknown total: subtle static indicator instead of distracting indeterminate loop
      ratio = progress > 0 ? 0.22 : 0.0;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(
            height: height,
            width: double.infinity,
            color: context.appInputSurface,
          ),
          if (ratio > 0)
            FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: hasTotal ? color : color.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
