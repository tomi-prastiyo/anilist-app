import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified typography tokens using GoogleFonts Overpass with safe Unicode & system fallbacks.
class AppTypography {
  AppTypography._();

  static const List<String> fallbackFonts = [
    'Roboto',
    'Noto Sans',
    'Noto Color Emoji',
    'sans-serif',
  ];

  static final String? fontFamily = GoogleFonts.overpass().fontFamily;

  static TextStyle style({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.overpass(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: decorationColor,
      shadows: shadows,
    ).copyWith(fontFamilyFallback: fallbackFonts);
  }

  static TextStyle heading(
    BuildContext context, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w800,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return style(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).textTheme.titleMedium?.color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle body(
    BuildContext context, {
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double height = 1.45,
  }) {
    return style(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
      height: height,
    );
  }

  static StrutStyle strut(double fontSize, {double height = 1.38}) {
    return StrutStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: fontSize,
      height: height,
    );
  }
}
