import 'package:flutter/material.dart';

/// Shared palette — derived from the 1-bit asset pack (light #B9DDA7,
/// mid #68A08A, dark #1E4250) so the GUI and the game world feel like
/// one piece.
class PixelColors {
  static const bg = Color(0xFF0E222B);
  static const surface = Color(0xFF1E4250);
  static const surfaceLight = Color(0xFF2B5666);
  static const border = Color(0xFF68A08A);
  static const borderDark = Color(0xFF15323D);
  static const text = Color(0xFFB9DDA7);
  static const textDim = Color(0xFF68A08A);
  static const gold = Color(0xFFB9DDA7);
  static const red = Color(0xFFC85A5A);
  static const green = Color(0xFF68A08A);
  static const blue = Color(0xFF68A08A);
  static const purple = Color(0xFF2B5666);
}

const pixelFont = 'PressStart2P';

ThemeData buildPixelTheme() {
  const base = TextStyle(
    fontFamily: pixelFont,
    color: PixelColors.text,
    height: 1.6,
  );
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: PixelColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: PixelColors.gold,
      secondary: PixelColors.red,
      surface: PixelColors.surface,
    ),
    textTheme: TextTheme(
      displayLarge: base.copyWith(fontSize: 28, color: PixelColors.gold),
      headlineMedium: base.copyWith(fontSize: 16),
      titleMedium: base.copyWith(fontSize: 12),
      bodyMedium: base.copyWith(fontSize: 8, color: PixelColors.textDim),
      labelLarge: base.copyWith(fontSize: 10),
    ),
  );
}
