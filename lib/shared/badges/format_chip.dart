import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class FormatChip extends StatelessWidget {
  final String format;
  final double fontSize;

  const FormatChip({
    super.key,
    required this.format,
    this.fontSize = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.9),
        borderRadius: AppSpacing.borderRadius4,
        border: Border.all(color: AppColors.darkBorder, width: 0.8),
      ),
      child: Text(
        format.replaceAll('_', ' '),
        style: TextStyle(
          color: AppColors.brandBlue,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
