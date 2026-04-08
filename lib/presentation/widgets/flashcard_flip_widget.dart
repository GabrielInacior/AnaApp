// lib/presentation/widgets/flashcard_flip_widget.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

class FlashcardFlipWidget extends StatefulWidget {
  final String front;
  final String back;
  final bool isFlipped;
  final VoidCallback onTap;
  final String? frontImagePath;
  final String? backImagePath;
  final String? tag;
  final Color? tagColor;

  const FlashcardFlipWidget({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
    required this.onTap,
    this.frontImagePath,
    this.backImagePath,
    this.tag,
    this.tagColor,
  });

  @override
  State<FlashcardFlipWidget> createState() => _FlashcardFlipWidgetState();
}

class _FlashcardFlipWidgetState extends State<FlashcardFlipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _animation = Tween<double>(begin: 0, end: pi).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(FlashcardFlipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the card content changed (new card), snap to front instantly
    final contentChanged =
        widget.front != oldWidget.front || widget.back != oldWidget.back;
    if (contentChanged && !widget.isFlipped) {
      _controller.value = 0;
      return;
    }
    if (widget.isFlipped && !oldWidget.isFlipped) {
      _controller.forward();
    } else if (!widget.isFlipped && oldWidget.isFlipped) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isShowingBack = _animation.value > pi / 2;
          return Transform(
            transform: Matrix4.rotationY(_animation.value),
            alignment: Alignment.center,
            child: isShowingBack
                ? Transform(
                    transform: Matrix4.rotationY(pi),
                    alignment: Alignment.center,
                    child: _CardFace(
                      text: widget.back,
                      label: 'RESPOSTA',
                      isBack: true,
                      imagePath: widget.backImagePath,
                      tag: widget.tag,
                      tagColor: widget.tagColor,
                    ),
                  )
                : _CardFace(
                    text: widget.front,
                    label: 'PERGUNTA',
                    isBack: false,
                    imagePath: widget.frontImagePath,
                    tag: widget.tag,
                    tagColor: widget.tagColor,
                  ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String label;
  final bool isBack;
  final String? imagePath;
  final String? tag;
  final Color? tagColor;

  const _CardFace({
    required this.text,
    required this.label,
    required this.isBack,
    this.imagePath,
    this.tag,
    this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Base accent color: tag color if available, gray for untagged
    final accent = tagColor ?? const Color(0xFF90A4AE);

    final List<Color> gradientColors;
    final Color glowColor;
    final Color labelBgColor;
    final Color labelTextColor;
    final Color mainTextColor;
    final Color hintColor;
    final Color borderColor;

    if (isBack) {
      gradientColors = isDark
          ? [
              _blendDark(accent, 0.20),
              _blendDark(accent, 0.15),
            ]
          : [
              _blendLight(accent, 0.12),
              _blendLight(accent, 0.08),
            ];
      glowColor = accent.withValues(alpha: isDark ? 0.25 : 0.30);
      labelBgColor = accent.withValues(alpha: isDark ? 0.20 : 0.22);
      labelTextColor = isDark
          ? _lighten(accent, 0.7)
          : _darken(accent, 0.35);
      mainTextColor = isDark
          ? _lighten(accent, 0.85)
          : _darken(accent, 0.55);
      hintColor = Colors.transparent;
      borderColor = accent.withValues(alpha: isDark ? 0.15 : 0.25);
    } else {
      gradientColors = isDark
          ? [
              _blendDark(accent, 0.18),
              _blendDark(accent, 0.12),
            ]
          : [
              _blendLight(accent, 0.15),
              _blendLight(accent, 0.10),
            ];
      glowColor = accent.withValues(alpha: isDark ? 0.20 : 0.25);
      labelBgColor = accent.withValues(alpha: isDark ? 0.18 : 0.20);
      labelTextColor = isDark
          ? _lighten(accent, 0.7)
          : _darken(accent, 0.35);
      mainTextColor = isDark
          ? _lighten(accent, 0.85)
          : _darken(accent, 0.55);
      hintColor = accent.withValues(alpha: isDark ? 0.35 : 0.30);
      borderColor = accent.withValues(alpha: isDark ? 0.12 : 0.40);
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black12)
                .withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label pill row with tag badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: labelBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: labelTextColor,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          // Tag badge
          if (tag != null && tag!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.25 : 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.3 : 0.25),
                  width: 0.5,
                ),
              ),
              child: Text(
                tag!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? _lighten(accent, 0.65)
                      : _darken(accent, 0.25),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],

          // Image (if available)
          if (imagePath != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(imagePath!),
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],

          const SizedBox(height: 28),
          Text(
            text,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: mainTextColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isBack) ...[
            const SizedBox(height: 28),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: hintColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Toque para revelar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Blend accent into a dark background
  static Color _blendDark(Color accent, double amount) {
    return Color.lerp(const Color(0xFF1A1A2E), accent, amount)!;
  }

  /// Blend accent into a light background
  static Color _blendLight(Color accent, double amount) {
    return Color.lerp(Colors.white, accent, amount)!;
  }

  /// Darken a color by mixing with black
  static Color _darken(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount)!;
  }

  /// Lighten a color by mixing with white
  static Color _lighten(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount)!;
  }
}
