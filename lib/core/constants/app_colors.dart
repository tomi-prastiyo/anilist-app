import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // AniList Brand Colors
  static const Color brandBlue = Color(0xFF3DB4F2);
  static const Color brandDarkBlue = Color(0xFF02A9FF);
  static const Color brandNavy = Color(0xFF152232);
  static const Color accentUserCustom = Color(0xFFD878CB); // Custom user accent (e.g. PdBear)

  // Dark Theme Palette (AniList Dark)
  static const Color darkBackground = Color(0xFF0B1622);
  static const Color darkSurface = Color(0xFF151F2E);
  static const Color darkSurfaceAlt = Color(0xFF0F161F);
  static const Color darkSurfaceInput = Color(0xFF060C13);
  static const Color darkCard = Color(0xFF192639);
  static const Color darkBorder = Color(0xFF22354E);
  static const Color darkTextPrimary = Color(0xFFEDF1F5);
  static const Color darkTextSecondary = Color(0xFF9FADBD);
  static const Color darkTextMuted = Color(0xFF728AA1);
  static const Color darkTextDim = Color(0xFF8596A5);

  // AMOLED Theme Palette
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF0C0C0E);
  static const Color amoledCard = Color(0xFF151518);
  static const Color amoledBorder = Color(0xFF232328);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFEDF1F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF263238);
  static const Color lightTextSecondary = Color(0xFF516170);
  static const Color lightTextMuted = Color(0xFF8BA0B2);

  // Scoring & Status Colors (Official AniList Web Tokens)
  static const Color scoreHigh = Color(0xFF46C07B); // >= 75
  static const Color scoreMedium = Color(0xFFF7A361); // 60 - 74
  static const Color scoreLow = Color(0xFFE85D75); // < 60

  static const Color statusWatching = Color(0xFF7BD555);
  static const Color statusCompleted = Color(0xFF3DB4F2);
  static const Color statusPaused = Color(0xFFF79A63);
  static const Color statusDropped = Color(0xFFE85D75);
  static const Color statusPlanning = Color(0xFF9FADBD);
  static const Color statusRepeating = Color(0xFF7C57E8);
  static const Color statusBehind = Color(0xFFE85D75);
  static const Color statusAiring = Color(0xFFF79A63);

  // Accent Tones
  static const Color favoritePink = Color(0xFFE53E3E);
  static const Color shimmerBase = Color(0xFF1A2634);
  static const Color shimmerHighlight = Color(0xFF283A4E);

  /// Resolves AniList user options.profileColor into a concrete Flutter Color
  static Color getProfileAccentColor(String? colorName) {
    if (colorName == null || colorName.isEmpty) return brandBlue;
    final lower = colorName.toLowerCase();
    switch (lower) {
      case 'blue':
        return brandBlue;
      case 'purple':
        return const Color(0xFFC063FF);
      case 'pink':
        return accentUserCustom;
      case 'orange':
        return const Color(0xFFF79A63);
      case 'red':
        return const Color(0xFFE85D75);
      case 'green':
        return const Color(0xFF46C07B);
      case 'gray':
      case 'grey':
        return const Color(0xFF677B94);
      default:
        if (colorName.startsWith('#') && colorName.length == 7) {
          final hex = colorName.substring(1);
          final val = int.tryParse('FF$hex', radix: 16);
          if (val != null) return Color(val);
        }
        return brandBlue;
    }
  }
}
