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

  /// Predefined subject/topic tags for cards (same as OpenAI topics)
  static const List<String> predefinedTags = [
    'Inglês',
    'Espanhol',
    'Francês',
    'Matemática',
    'Geografia',
    'Cálculo',
    'Física',
    'Biologia',
    'História',
    'Química',
    'Programação',
    'Concursos',
    'Direito',
    'Filosofia',
    'Medicina',
  ];

  /// Fixed color for each predefined tag (index-matched with predefinedTags)
  static const Map<String, int> predefinedTagColors = {
    'Inglês':      0xFF4FC3F7, // Light Blue
    'Espanhol':    0xFFFF8A65, // Orange
    'Francês':     0xFF7986CB, // Indigo
    'Matemática':  0xFFFFD54F, // Yellow
    'Geografia':   0xFF81C784, // Green
    'Cálculo':     0xFFBA68C8, // Purple
    'Física':      0xFF4DB6AC, // Teal
    'Biologia':    0xFFAED581, // Light Green
    'História':    0xFFA1887F, // Brown
    'Química':     0xFFE57373, // Red
    'Programação': 0xFF90A4AE, // Blue Grey
    'Concursos':   0xFFF06292, // Pink
    'Direito':     0xFFFFD54F, // Yellow
    'Filosofia':   0xFF7986CB, // Indigo
    'Medicina':    0xFFE57373, // Red
  };

  /// Preset colors available for custom tags (saturated, visible)
  static const List<int> tagColorValues = [
    0xFFE57373, // Red
    0xFFFF8A65, // Orange
    0xFFFFD54F, // Yellow
    0xFF81C784, // Green
    0xFF4FC3F7, // Light Blue
    0xFF7986CB, // Indigo
    0xFFBA68C8, // Purple
    0xFFF06292, // Pink
    0xFF4DB6AC, // Teal
    0xFFA1887F, // Brown
    0xFF90A4AE, // Blue Grey
    0xFFAED581, // Light Green
  ];
}
