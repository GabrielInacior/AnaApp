import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable tag picker widget with collapsible section and "Outros" for custom tags with color picker.
class TagPicker extends StatelessWidget {
  final List<String> allTags;
  final List<String> selectedTags;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(String tag, bool selected) onTagChanged;
  final void Function(String tag, int? colorValue) onCustomTagAdded;
  final void Function(String tag)? onTagLongPress;

  /// Optional map of tag name -> color value for colored chips
  final Map<String, int>? tagColors;

  const TagPicker({
    super.key,
    required this.allTags,
    required this.selectedTags,
    required this.expanded,
    required this.onToggle,
    required this.onTagChanged,
    required this.onCustomTagAdded,
    this.onTagLongPress,
    this.tagColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Text('Tags', style: theme.textTheme.labelLarge),
              const Spacer(),
              if (!expanded && selectedTags.isEmpty)
                Text('Nenhuma',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
              Icon(expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded),
            ],
          ),
        ),
        if (!expanded && selectedTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selectedTags
                  .map((tag) {
                    final color = tagColors?[tag];
                    return Chip(
                      label:
                          Text(tag, style: const TextStyle(fontSize: 12)),
                      avatar: color != null
                          ? CircleAvatar(
                              backgroundColor: Color(color), radius: 5)
                          : null,
                      deleteIcon:
                          const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => onTagChanged(tag, false),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    );
                  })
                  .toList(),
            ),
          ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...allTags.map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  final color = tagColors?[tag];
                  return GestureDetector(
                    onLongPress: onTagLongPress != null
                        ? () => onTagLongPress!(tag)
                        : null,
                    child: FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (v) => onTagChanged(tag, v),
                      avatar: color != null && !isSelected
                          ? CircleAvatar(
                              backgroundColor: Color(color), radius: 6)
                          : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                }),
                // "Outros" chip -> opens custom tag creator
                ActionChip(
                  avatar: Icon(Icons.add_rounded,
                      size: 18, color: colorScheme.primary),
                  label: const Text('Outros'),
                  onPressed: () => _showCreateTagModal(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showCreateTagModal(BuildContext context) {
    final controller = TextEditingController();
    int? selectedColorValue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Nova tag',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(
                  'Crie uma tag personalizada para organizar seus cards',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nome da tag',
                    hintText: 'Ex: Anatomia, React, ENEM...',
                    prefixIcon: const Icon(Icons.label_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                Text('Cor da tag', style: theme.textTheme.labelLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // No color option
                    GestureDetector(
                      onTap: () => setSheetState(() => selectedColorValue = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: selectedColorValue == null
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.2),
                            width: selectedColorValue == null ? 3 : 1.5,
                          ),
                        ),
                        child: Icon(Icons.auto_awesome_rounded,
                            size: 16, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    // Color options
                    for (final colorVal in AppColors.tagColorValues)
                      GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedColorValue = colorVal),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(colorVal),
                            border: Border.all(
                              color: selectedColorValue == colorVal
                                  ? colorScheme.primary
                                  : colorScheme.outline.withValues(alpha: 0.2),
                              width: selectedColorValue == colorVal ? 3 : 1.5,
                            ),
                            boxShadow: selectedColorValue == colorVal
                                ? [
                                    BoxShadow(
                                      color: Color(colorVal).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: selectedColorValue == colorVal
                              ? const Icon(Icons.check_rounded,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        onCustomTagAdded(text, selectedColorValue);
                        Navigator.pop(ctx);
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Criar tag'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shows a delete confirmation dialog for a tag. Returns true if the tag should be deleted.
Future<bool> showDeleteTagDialog(
  BuildContext context, {
  required String tagName,
  required int cardsWithTag,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colorScheme = theme.colorScheme;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Excluir tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja excluir a tag "$tagName"?'),
            if (cardsWithTag > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded,
                        size: 20, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$cardsWithTag card${cardsWithTag > 1 ? 's' : ''} usa${cardsWithTag > 1 ? 'm' : ''} essa tag. A tag sera removida desses cards.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Excluir'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
