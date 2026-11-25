import 'package:flutter/material.dart';
import 'yuyuyu_assets.dart';

@immutable
class AppThemePalette extends ThemeExtension<AppThemePalette> {
  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color inputSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color secondaryAccent;
  final bool isYuYuYu;

  const AppThemePalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.inputSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.secondaryAccent,
    this.isYuYuYu = false,
  });

  static const dark = AppThemePalette(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    card: AppColors.darkCard,
    border: Color(0x14FFFFFF),
    inputSurface: AppColors.darkSurfaceInput,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    accent: AppColors.brandBlue,
    secondaryAccent: AppColors.brandDarkBlue,
    isYuYuYu: false,
  );

  static const light = AppThemePalette(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    card: AppColors.lightCard,
    border: AppColors.lightBorder,
    inputSurface: Colors.white,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    accent: AppColors.brandBlue,
    secondaryAccent: AppColors.brandDarkBlue,
    isYuYuYu: false,
  );

  static AppThemePalette yuyuyu([Color accent = const Color(0xFFF472B6)]) => AppThemePalette(
        background: YuYuYuAssets.twilightBg,
        surface: YuYuYuAssets.twilightSurface,
        card: YuYuYuAssets.twilightCard,
        border: YuYuYuAssets.twilightBorder,
        inputSurface: YuYuYuAssets.twilightInput,
        textPrimary: YuYuYuAssets.blossomTextPrimary,
        textSecondary: YuYuYuAssets.blossomTextSecondary,
        textMuted: YuYuYuAssets.blossomTextMuted,
        accent: accent,
        secondaryAccent: YuYuYuAssets.shinjuGold,
        isYuYuYu: true,
      );

  @override
  AppThemePalette copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? border,
    Color? inputSurface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? secondaryAccent,
    bool? isYuYuYu,
  }) {
    return AppThemePalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      inputSurface: inputSurface ?? this.inputSurface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      isYuYuYu: isYuYuYu ?? this.isYuYuYu,
    );
  }

  @override
  AppThemePalette lerp(ThemeExtension<AppThemePalette>? other, double t) {
    if (other is! AppThemePalette) return this;
    return AppThemePalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputSurface: Color.lerp(inputSurface, other.inputSurface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      isYuYuYu: t < 0.5 ? isYuYuYu : other.isYuYuYu,
    );
  }
}

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

  // Dynamic Theme-Aware Helpers
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;
  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : lightCard;
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0x14FFFFFF) : lightBorder;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;
  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextMuted : lightTextMuted;
  static Color inputSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceInput : Colors.white;
}

/// Convenience extension on [BuildContext] for clean, responsive theming.
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  AppThemePalette get appPalette =>
      Theme.of(this).extension<AppThemePalette>() ??
      (isDark ? AppThemePalette.dark : AppThemePalette.light);

  Color get appBackground => appPalette.background;
  Color get appSurface => appPalette.surface;
  Color get appCard => appPalette.card;
  Color get appBorder => appPalette.border;
  Color get appTextPrimary => appPalette.textPrimary;
  Color get appTextSecondary => appPalette.textSecondary;
  Color get appTextMuted => appPalette.textMuted;
  Color get appInputSurface => appPalette.inputSurface;
  Color get appAccent => appPalette.accent;
  Color get appSecondaryAccent => appPalette.secondaryAccent;
  bool get isYuYuYu => appPalette.isYuYuYu;
}

