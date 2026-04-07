// lib/presentation/widgets/rating_buttons_widget.dart
import 'package:flutter/material.dart';
import '../../../core/utils/sm2.dart';

class RatingButtonsWidget extends StatelessWidget {
  final void Function(CardRating) onRate;

  const RatingButtonsWidget({super.key, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RatingButton(
          label: 'Errei',
          sublabel: '< 1 dia',
          color: Theme.of(context).colorScheme.error,
          onTap: () => onRate(CardRating.again),
        ),
        _RatingButton(
          label: 'Difícil',
          sublabel: '~2 dias',
          color: Colors.orange,
          onTap: () => onRate(CardRating.hard),
        ),
        _RatingButton(
          label: 'Bom',
          sublabel: '~4 dias',
          color: Colors.green,
          onTap: () => onRate(CardRating.good),
        ),
        _RatingButton(
          label: 'Fácil',
          sublabel: '~7 dias',
          color: Colors.blue,
          onTap: () => onRate(CardRating.easy),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(sublabel,
                style: TextStyle(
                    color: color.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
