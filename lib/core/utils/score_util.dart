import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ScoreUtil {
  ScoreUtil._();

  /// Formats raw numerical score (0 to 100) based on user's selected score format.
  /// Formats:
  /// - POINT_100: "85%"
  /// - POINT_10_DECIMAL: "8.5"
  /// - POINT_10: "8/10"
  /// - POINT_5: "4/5 ★"
  /// - POINT_3: ":)" or ":|" or ":("
  static String formatScore(double? score, {String format = 'POINT_100'}) {
    if (score == null || score == 0) return '-';

    switch (format) {
      case 'POINT_10_DECIMAL':
        // Raw score is typically 0-10 or 0-100 depending on mutation vs query
        final val = score > 10 ? score / 10.0 : score;
        return val.toStringAsFixed(1);
      case 'POINT_10':
        final val = score > 10 ? (score / 10.0).round() : score.round();
        return '$val/10';
      case 'POINT_5':
        final val = score > 5 ? (score / 20.0).round() : score.round();
        return '$val/5 ★';
      case 'POINT_3':
        if (score >= 67 || score == 3) return ':)';
        if (score >= 34 || score == 2) return ':|';
        return ':(';
      case 'POINT_100':
      default:
        return '${score.round()}%';
    }
  }

  /// Returns appropriate badge color based on score
  static Color getScoreColor(double? score) {
    if (score == null || score == 0) return AppColors.darkTextMuted;
    final normalized = score <= 10 ? score * 10 : score;
    if (normalized >= 75) return AppColors.scoreHigh;
    if (normalized >= 60) return AppColors.scoreMedium;
    return AppColors.scoreLow;
  }
}
