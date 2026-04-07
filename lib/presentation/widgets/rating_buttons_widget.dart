// lib/presentation/widgets/rating_buttons_widget.dart
import 'package:flutter/material.dart';
import '../../core/utils/sm2.dart';

class RatingButtonsWidget extends StatelessWidget {
  final void Function(CardRating) onRate;
  final List<RatingPreview>? previews;

  const RatingButtonsWidget({
    super.key,
    required this.onRate,
    this.previews,
  });

  String _sublabelFor(CardRating rating) {
    if (previews == null) {
      // Fallback static labels
      switch (rating) {
        case CardRating.again: return '< 1min';
        case CardRating.hard: return '~2d';
        case CardRating.good: return '~4d';
        case CardRating.easy: return '~7d';
      }
    }
    final match = previews!.where((p) => p.rating == rating);
    return match.isNotEmpty ? match.first.label : '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RatingPill(
          label: 'Errei',
          sublabel: _sublabelFor(CardRating.again),
          icon: Icons.close_rounded,
          gradientColors: isDark
              ? [const Color(0xFFB71C4A), const Color(0xFF880E3B)]
              : [const Color(0xFFFBB4C4), const Color(0xFFF48CA8)],
          textColor: isDark ? const Color(0xFFFFC1D0) : const Color(0xFF9B1B4A),
          onTap: () => onRate(CardRating.again),
        ),
        _RatingPill(
          label: 'Dificil',
          sublabel: _sublabelFor(CardRating.hard),
          icon: Icons.thumb_down_alt_rounded,
          gradientColors: isDark
              ? [const Color(0xFFB8860B), const Color(0xFF8B6508)]
              : [const Color(0xFFFFE0A0), const Color(0xFFFFCB6B)],
          textColor: isDark ? const Color(0xFFFFD580) : const Color(0xFF8B6508),
          onTap: () => onRate(CardRating.hard),
        ),
        _RatingPill(
          label: 'Bom',
          sublabel: _sublabelFor(CardRating.good),
          icon: Icons.thumb_up_alt_rounded,
          gradientColors: isDark
              ? [const Color(0xFF6A3FA0), const Color(0xFF4A2080)]
              : [const Color(0xFFE0C8F0), const Color(0xFFCDA8E8)],
          textColor: isDark ? const Color(0xFFD4B8F0) : const Color(0xFF5C2D91),
          onTap: () => onRate(CardRating.good),
        ),
        _RatingPill(
          label: 'Facil',
          sublabel: _sublabelFor(CardRating.easy),
          icon: Icons.star_rounded,
          gradientColors: isDark
              ? [const Color(0xFF2E7D5A), const Color(0xFF1B5E40)]
              : [const Color(0xFFB8F0D0), const Color(0xFF8DE8B0)],
          textColor: isDark ? const Color(0xFFA0E8C0) : const Color(0xFF1B6840),
          onTap: () => onRate(CardRating.easy),
        ),
      ],
    );
  }
}

class _RatingPill extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final List<Color> gradientColors;
  final Color textColor;
  final VoidCallback onTap;

  const _RatingPill({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.gradientColors,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? textColor.withValues(alpha: 0.25)
                  : textColor.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: isDark ? 0.2 : 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: textColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                sublabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.75),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
