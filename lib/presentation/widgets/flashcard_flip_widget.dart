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

  const FlashcardFlipWidget({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
    required this.onTap,
    this.frontImagePath,
    this.backImagePath,
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
                    ),
                  )
                : _CardFace(
                    text: widget.front,
                    label: 'PERGUNTA',
                    isBack: false,
                    imagePath: widget.frontImagePath,
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

  const _CardFace({
    required this.text,
    required this.label,
    required this.isBack,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Color> gradientColors;
    final Color glowColor;
    final Color labelBgColor;
    final Color labelTextColor;
    final Color mainTextColor;
    final Color hintColor;
    final Color borderColor;

    if (isBack) {
      gradientColors = isDark
          ? [const Color(0xFF3D2852), const Color(0xFF4A2040)]
          : [const Color(0xFFE8D5F5), const Color(0xFFF5D5E8)];
      glowColor = isDark
          ? const Color(0xFF9C4DCC).withValues(alpha: 0.3)
          : const Color(0xFFCE93D8).withValues(alpha: 0.35);
      labelBgColor = isDark
          ? const Color(0xFFCE93D8).withValues(alpha: 0.2)
          : const Color(0xFFCE93D8).withValues(alpha: 0.25);
      labelTextColor = isDark
          ? const Color(0xFFE1BEE7)
          : const Color(0xFF7B1FA2);
      mainTextColor = isDark
          ? const Color(0xFFF3E5F6)
          : const Color(0xFF4A1068);
      hintColor = Colors.transparent;
      borderColor = isDark
          ? const Color(0xFFCE93D8).withValues(alpha: 0.15)
          : const Color(0xFFCE93D8).withValues(alpha: 0.3);
    } else {
      gradientColors = isDark
          ? [const Color(0xFF3D2040), const Color(0xFF2D2852)]
          : [const Color(0xFFFCE4EC), const Color(0xFFE8DEF8)];
      glowColor = isDark
          ? const Color(0xFFF48FB1).withValues(alpha: 0.25)
          : const Color(0xFFF48FB1).withValues(alpha: 0.3);
      labelBgColor = isDark
          ? const Color(0xFFF48FB1).withValues(alpha: 0.18)
          : const Color(0xFFF48FB1).withValues(alpha: 0.2);
      labelTextColor = isDark
          ? const Color(0xFFF8BBD0)
          : const Color(0xFFC2185B);
      mainTextColor = isDark
          ? const Color(0xFFFCE4EC)
          : const Color(0xFF4A1048);
      hintColor = isDark
          ? const Color(0xFFF8BBD0).withValues(alpha: 0.4)
          : const Color(0xFFAD1457).withValues(alpha: 0.35);
      borderColor = isDark
          ? const Color(0xFFF48FB1).withValues(alpha: 0.12)
          : const Color(0xFFF8BBD0).withValues(alpha: 0.6);
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
}
