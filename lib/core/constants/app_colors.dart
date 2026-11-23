import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // AniList Brand Colors
  static const Color brandBlue = Color(0xFF3DB4F2);
  static const Color brandDarkBlue = Color(0xFF02A9FF);
  static const Color brandNavy = Color(0xFF152232);

  // Dark Theme Palette (AniList Dark)
  static const Color darkBackground = Color(0xFF0B1622);
  static const Color darkSurface = Color(0xFF151F2E);
  static const Color darkCard = Color(0xFF192639);
  static const Color darkBorder = Color(0xFF22354E);
  static const Color darkTextPrimary = Color(0xFFEDF1F5);
  static const Color darkTextSecondary = Color(0xFF8BA0B2);
  static const Color darkTextMuted = Color(0xFF5A6F82);

  // AMOLED Theme Palette
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF0C0C0E);
  static const Color amoledCard = Color(0xFF151518);
  static const Color amoledBorder = Color(0xFF232328);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Scoring & Status Colors
  static const Color scoreHigh = Color(0xFF48BB78); // >= 75
  static const Color scoreMedium = Color(0xFFECC94B); // 60 - 74
  static const Color scoreLow = Color(0xFFF56565); // < 60

  static const Color statusWatching = Color(0xFF3DB4F2);
  static const Color statusCompleted = Color(0xFF48BB78);
  static const Color statusPaused = Color(0xFFED8936);
  static const Color statusDropped = Color(0xFFE53E3E);
  static const Color statusPlanning = Color(0xFF9F7AEA);
  static const Color statusRepeating = Color(0xFF38B2AC);

  // Accent Tones
  static const Color favoritePink = Color(0xFFE53E3E);
  static const Color shimmerBase = Color(0xFF1A2634);
  static const Color shimmerHighlight = Color(0xFF283A4E);
}
