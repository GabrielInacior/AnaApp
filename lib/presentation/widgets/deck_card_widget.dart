// lib/presentation/widgets/deck_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/deck.dart';
import '../providers/repository_providers.dart';

class DeckCardWidget extends ConsumerWidget {
  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFavorite;

  const DeckCardWidget({
    super.key,
    required this.deck,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deckColor = AppColors.getDeckColor(
      deck.colorValue,
      brightness: theme.brightness,
    );

    // Derive tags from cards inside this deck
    final cardsAsync = ref.watch(cardsByDeckProvider(deck.id));
    // Watch allTagsProvider so widget rebuilds when tag colors load from DB
    ref.watch(allTagsProvider);
    final tagNotifier = ref.read(allTagsProvider.notifier);
    final cardTags = cardsAsync.whenOrNull(
      data: (cards) {
        final tags = <String>{};
        for (final c in cards) {
          if (c.tag != null && c.tag!.isNotEmpty) tags.add(c.tag!);
        }
        return tags.toList()..sort();
      },
    ) ?? <String>[];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: deckColor.withValues(alpha: 0.25),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                deckColor.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: icon + name + actions
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: deckColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 20,
                        color: deckColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        deck.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onToggleFavorite != null)
                      _FavoriteButton(
                        isFavorite: deck.isFavorite,
                        onPressed: onToggleFavorite!,
                      ),
                    if (onDelete != null || onEdit != null)
                      _OverflowMenu(
                        onDelete: onDelete,
                        onEdit: onEdit,
                      ),
                  ],
                ),

                // Description
                if (deck.description != null &&
                    deck.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Text(
                      deck.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Tag badges (derived from cards)
                if (cardTags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...cardTags.take(4).map((tag) {
                          final tagColorVal = tagNotifier.getTagColor(tag);
                          final badgeColor = tagColorVal != null
                              ? Color(tagColorVal)
                              : deckColor;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }),
                        if (cardTags.length > 4)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+${cardTags.length - 4}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Stat pills
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Row(
                    children: [
                      _Pill(
                        icon: Icons.layers_rounded,
                        label: '${deck.totalCards} cards',
                        color: colorScheme.secondaryContainer,
                        textColor: colorScheme.onSecondaryContainer,
                      ),
                      if (deck.dueCards > 0) ...[
                        const SizedBox(width: 8),
                        _Pill(
                          icon: Icons.schedule_rounded,
                          label: '${deck.dueCards} pendentes',
                          color: colorScheme.errorContainer,
                          textColor: colorScheme.onErrorContainer,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const _FavoriteButton({
    required this.isFavorite,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        iconSize: 20,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          color: isFavorite
              ? const Color(0xFFE57373)
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onPressed: onPressed,
        tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _OverflowMenu({this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: 36,
      child: PopupMenuButton<String>(
        iconSize: 20,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(
          Icons.more_horiz_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        tooltip: 'Mais opcoes',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onSelected: (value) {
          if (value == 'delete') onDelete?.call();
          if (value == 'edit') onEdit?.call();
        },
        itemBuilder: (context) => [
          if (onEdit != null)
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded,
                      size: 20, color: colorScheme.onSurface),
                  const SizedBox(width: 12),
                  const Text('Editar baralho'),
                ],
              ),
            ),
          if (onDelete != null)
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 20, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Text(
                    'Excluir baralho',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
