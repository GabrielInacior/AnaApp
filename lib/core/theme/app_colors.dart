// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Soft rose-lavender seed — feminine and warm
  static const Color seedColor = Color(0xFFD4A0B9);

  /// Preset pastel colors for decks (8 options) — light mode originals
  static const List<int> deckColorValues = [
    0xFFF8BBD0, // Soft Pink
    0xFFFFCCBC, // Peach
    0xFFFFF9C4, // Cream Yellow
    0xFFC8E6C9, // Mint Green
    0xFFB3E5FC, // Baby Blue
    0xFFD1C4E9, // Lavender
    0xFFE1BEE7, // Lilac
    0xFFB2DFDB, // Soft Teal
  ];

  /// Dark-mode saturated variants for each deck color
  static const Map<int, int> _darkDeckColors = {
    0xFFF8BBD0: 0xFFAD3A6A, // Soft Pink → Deep Rose
    0xFFFFCCBC: 0xFFC75B39, // Peach → Warm Coral
    0xFFFFF9C4: 0xFFBFA730, // Cream → Amber Gold
    0xFFC8E6C9: 0xFF4A8C50, // Mint → Forest Green
    0xFFB3E5FC: 0xFF2979B5, // Baby Blue → Ocean Blue
    0xFFD1C4E9: 0xFF6C4DAB, // Lavender → Deep Purple
    0xFFE1BEE7: 0xFF8E3DA0, // Lilac → Rich Magenta
    0xFFB2DFDB: 0xFF2D8C7E, // Soft Teal → Deep Teal
  };

  /// Light-mode contrast-adjusted values (only for colors with poor contrast)
  static const Map<int, int> _lightAdjustedColors = {
    0xFFFFF9C4: 0xFFE8D44D, // Cream Yellow → Gold (better visibility)
  };

  /// Returns a brightness-aware deck color.
  /// In dark mode, returns saturated deep variants.
  /// In light mode, adjusts low-contrast colors (e.g. yellow).
  static Color getDeckColor(int? colorValue,
      {Brightness brightness = Brightness.light}) {
    if (colorValue == null) return seedColor;

    if (brightness == Brightness.dark) {
      final darkVariant = _darkDeckColors[colorValue];
      if (darkVariant != null) return Color(darkVariant);
      // Generic fallback: desaturate and darken
      final hsl = HSLColor.fromColor(Color(colorValue));
      return hsl
          .withLightness(0.35)
          .withSaturation((hsl.saturation * 0.7).clamp(0.3, 0.8))
          .toColor();
    }

    // Light mode: check for contrast-adjusted variants
    final adjusted = _lightAdjustedColors[colorValue];
    if (adjusted != null) return Color(adjusted);
    return Color(colorValue);
  }

  /// Predefined tags for decks
  static const List<String> predefinedTags = [
    'Idiomas',
    'Ciencias',
    'Exatas',
    'Concursos',
    'Medicina',
    'Direito',
    'Programacao',
    'Historia',
    'Geografia',
    'Outros',
  ];
}
