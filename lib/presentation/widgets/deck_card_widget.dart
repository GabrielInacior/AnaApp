// lib/presentation/widgets/deck_card_widget.dart
import 'package:flutter/material.dart';
import '../../domain/entities/deck.dart';

class DeckCardWidget extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const DeckCardWidget({
    super.key,
    required this.deck,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.style_rounded,
                    color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (deck.description != null)
                      Text(deck.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(
                          label: '${deck.totalCards} cards',
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        if (deck.dueCards > 0)
                          _Chip(
                            label: '${deck.dueCards} para revisar',
                            color: colorScheme.errorContainer,
                            textColor: colorScheme.onErrorContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: colorScheme.error,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Chip(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
    );
  }
}
