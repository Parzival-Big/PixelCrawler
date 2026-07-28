import 'package:flutter/material.dart';

/// Shared palette — matches the sprite placeholder palette so the GUI and
/// the game world feel like one piece.
class PixelColors {
  static const bg = Color(0xFF14141C);
  static const surface = Color(0xFF23232F);
  static const surfaceLight = Color(0xFF2E2E3D);
  static const border = Color(0xFF6A6A8C);
  static const borderDark = Color(0xFF3A3A4F);
  static const text = Color(0xFFE8E8DC);
  static const textDim = Color(0xFF9C9CB0);
  static const gold = Color(0xFFF8D848);
  static const red = Color(0xFFE83C4C);
  static const green = Color(0xFF5CC85C);
  static const blue = Color(0xFF4CA8E8);
  static const purple = Color(0xFF7A4CD8);
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
