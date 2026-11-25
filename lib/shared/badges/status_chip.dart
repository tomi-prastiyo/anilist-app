import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusChip({
    super.key,
    required this.status,
    this.fontSize = 10.0,
  });

  Color _getStatusColor() {
    switch (status.toUpperCase()) {
      case 'CURRENT':
      case 'WATCHING':
      case 'RELEASING':
        return AppColors.statusWatching;
      case 'COMPLETED':
      case 'FINISHED':
        return AppColors.statusCompleted;
      case 'PAUSED':
        return AppColors.statusPaused;
      case 'DROPPED':
      case 'CANCELLED':
        return AppColors.statusDropped;
      case 'PLANNING':
      case 'NOT_YET_RELEASED':
        return AppColors.statusPlanning;
      case 'REPEATING':
        return AppColors.statusRepeating;
      default:
        return AppColors.darkTextMuted;
    }
  }

  String _formatStatus() {
    return status.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadius4,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        _formatStatus(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
