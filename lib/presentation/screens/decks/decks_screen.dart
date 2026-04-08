// lib/presentation/screens/decks/decks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/deck_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/deck_card_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/tag_picker.dart';
import 'deck_detail_screen.dart';

class DecksScreen extends ConsumerStatefulWidget {
  const DecksScreen({super.key});

  @override
  ConsumerState<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends ConsumerState<DecksScreen> {
  bool _showFavoritesOnly = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _selectedTag;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(deckProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baralhos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_showFavoritesOnly ? 'Favoritos' : 'Todos'),
              selected: _showFavoritesOnly,
              onSelected: (value) => setState(() => _showFavoritesOnly = value),
              avatar: Icon(
                _showFavoritesOnly
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDeckSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Baralho'),
      ),
      body: decksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.error_outline_rounded,
                      size: 32, color: colorScheme.error),
                ),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar baralhos',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(deckProvider),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (decks) {
          if (decks.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.auto_stories_outlined,
              title: 'Nenhum baralho ainda',
              subtitle:
                  'Crie seu primeiro baralho para comecar a aprender!',
              action: FilledButton.icon(
                onPressed: () => _showCreateDeckSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Criar baralho'),
              ),
            );
          }

          var filtered = _showFavoritesOnly
              ? decks.where((d) => d.isFavorite).toList()
              : decks.toList();

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filtered = filtered.where((d) {
              return d.name.toLowerCase().contains(query) ||
                  (d.description?.toLowerCase().contains(query) ??
                      false) ||
                  d.tags.any((t) => t.toLowerCase().contains(query));
            }).toList();
          }

          if (_selectedTag != null) {
            filtered = filtered
                .where((d) => d.tags.contains(_selectedTag))
                .toList();
          }

          // Collect all tags in use across decks for the filter bar
          final allTags = <String>{};
          for (final d in decks) {
            allTags.addAll(d.tags);
          }
          final sortedTags = allTags.toList()..sort();

          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar baralhos...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              // Tag filter chips
              if (sortedTags.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final tag in sortedTags)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            selected: _selectedTag == tag,
                            onSelected: (v) =>
                                setState(() => _selectedTag = v ? tag : null),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              // Content with animated transitions
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _buildFilteredContent(
                    filtered, colorScheme, theme, sortedTags),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilteredContent(
    List<dynamic> filtered,
    ColorScheme colorScheme,
    ThemeData theme,
    List<String> sortedTags,
  ) {
    if (filtered.isEmpty && _searchQuery.isNotEmpty) {
      return EmptyStateWidget(
        key: const ValueKey('search-empty'),
        icon: Icons.search_off_rounded,
        title: 'Nenhum resultado',
        subtitle:
            'Nenhum baralho encontrado para "$_searchQuery".',
      );
    }

    if (filtered.isEmpty && _selectedTag != null) {
      return EmptyStateWidget(
        key: const ValueKey('tag-empty'),
        icon: Icons.label_off_rounded,
        title: 'Nenhum baralho',
        subtitle: 'Nenhum baralho com a tag "$_selectedTag".',
        action: FilledButton.tonal(
          onPressed: () => setState(() => _selectedTag = null),
          child: const Text('Limpar filtro'),
        ),
      );
    }

    if (filtered.isEmpty && _showFavoritesOnly) {
      return EmptyStateWidget(
        key: const ValueKey('fav-empty'),
        icon: Icons.favorite_outline_rounded,
        title: 'Nenhum favorito',
        subtitle:
            'Marque baralhos como favoritos para ve-los aqui.',
        action: FilledButton.tonal(
          onPressed: () =>
              setState(() => _showFavoritesOnly = false),
          child: const Text('Ver todos'),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey('list-${filtered.length}-$_showFavoritesOnly-$_searchQuery-$_selectedTag'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final deck = filtered[i];
        return _AnimatedDeckItem(
          key: ValueKey(deck.id),
          index: i,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DeckCardWidget(
              deck: deck,
              onTap: () => Navigator.push(
                context,
                SlideUpRoute(
                  page: DeckDetailScreen(deck: deck),
                ),
              ),
              onEdit: () => _showEditDeckSheet(context, deck),
              onDelete: () =>
                  _confirmDelete(context, deck.id, deck.name),
              onToggleFavorite: () => ref
                  .read(deckProvider.notifier)
                  .toggleFavorite(deck),
            ),
          ),
        );
      },
    );
  }

  void _showCreateDeckSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int? selectedColor;
    List<String> selectedTags = [];
    bool tagsExpanded = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final brightness = Theme.of(ctx).brightness;
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Novo Baralho',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: 'Nome do baralho'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                        labelText: 'Descricao (opcional)'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 18),
                  Text('Cor do baralho',
                      style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ColorCircle(
                        color: null,
                        isSelected: selectedColor == null,
                        onTap: () =>
                            setSheetState(() => selectedColor = null),
                      ),
                      for (final colorValue in AppColors.deckColorValues)
                        _ColorCircle(
                          color: AppColors.getDeckColor(colorValue,
                              brightness: brightness),
                          isSelected: selectedColor == colorValue,
                          onTap: () =>
                              setSheetState(() => selectedColor = colorValue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tags section (collapsible)
                  // Tags section
                  TagPicker(
                    allTags: ref.watch(allTagsProvider),
                    selectedTags: selectedTags,
                    expanded: tagsExpanded,
                    tagColors: ref.read(allTagsProvider.notifier).tagColors,
                    onToggle: () =>
                        setSheetState(() => tagsExpanded = !tagsExpanded),
                    onTagChanged: (tag, v) => setSheetState(() {
                      if (v) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    }),
                    onCustomTagAdded: (tag, colorValue) async {
                      await ref.read(allTagsProvider.notifier).addTag(tag, colorValue: colorValue);
                      setSheetState(() => selectedTags.add(tag));
                    },
                    onTagLongPress: (tag) async {
                      final notifier = ref.read(allTagsProvider.notifier);
                      final count = await notifier.countCardsWithTag(tag);
                      if (!ctx.mounted) return;
                      final confirmed = await showDeleteTagDialog(
                        ctx,
                        tagName: tag,
                        cardsWithTag: count,
                      );
                      if (confirmed) {
                        await notifier.deleteTag(tag, clearFromCards: true);
                        setSheetState(() => selectedTags.remove(tag));
                      }
                    },
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        await ref.read(deckProvider.notifier).createDeck(
                              name: nameController.text.trim(),
                              description: descController.text.trim().isEmpty
                                  ? null
                                  : descController.text.trim(),
                              colorValue: selectedColor,
                              tags: selectedTags.isEmpty ? null : selectedTags,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Criar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDeckSheet(BuildContext context, dynamic deck) {
    final nameController = TextEditingController(text: deck.name);
    final descController =
        TextEditingController(text: deck.description ?? '');
    int? selectedColor = deck.colorValue;
    List<String> selectedTags = List<String>.from(deck.tags);
    bool tagsExpanded = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final brightness = Theme.of(ctx).brightness;
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Editar Baralho',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: 'Nome do baralho'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                        labelText: 'Descricao (opcional)'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 18),
                  Text('Cor do baralho',
                      style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ColorCircle(
                        color: null,
                        isSelected: selectedColor == null,
                        onTap: () =>
                            setSheetState(() => selectedColor = null),
                      ),
                      for (final colorValue in AppColors.deckColorValues)
                        _ColorCircle(
                          color: AppColors.getDeckColor(colorValue,
                              brightness: brightness),
                          isSelected: selectedColor == colorValue,
                          onTap: () =>
                              setSheetState(() => selectedColor = colorValue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tags section (collapsible)
                  // Tags section
                  TagPicker(
                    allTags: ref.watch(allTagsProvider),
                    selectedTags: selectedTags,
                    expanded: tagsExpanded,
                    tagColors: ref.read(allTagsProvider.notifier).tagColors,
                    onToggle: () =>
                        setSheetState(() => tagsExpanded = !tagsExpanded),
                    onTagChanged: (tag, v) => setSheetState(() {
                      if (v) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    }),
                    onCustomTagAdded: (tag, colorValue) async {
                      await ref.read(allTagsProvider.notifier).addTag(tag, colorValue: colorValue);
                      setSheetState(() => selectedTags.add(tag));
                    },
                    onTagLongPress: (tag) async {
                      final notifier = ref.read(allTagsProvider.notifier);
                      final count = await notifier.countCardsWithTag(tag);
                      if (!ctx.mounted) return;
                      final confirmed = await showDeleteTagDialog(
                        ctx,
                        tagName: tag,
                        cardsWithTag: count,
                      );
                      if (confirmed) {
                        await notifier.deleteTag(tag, clearFromCards: true);
                        setSheetState(() => selectedTags.remove(tag));
                      }
                    },
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        final descText = descController.text.trim();
                        final updated = deck.copyWith(
                          name: nameController.text.trim(),
                          description: descText.isEmpty ? null : descText,
                          clearDescription: descText.isEmpty,
                          colorValue: selectedColor,
                          clearColor: selectedColor == null,
                          tags: selectedTags.isEmpty ? null : selectedTags,
                        );
                        await ref.read(deckProvider.notifier).updateDeck(updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir baralho'),
        content: Text(
            'Tem certeza que deseja excluir "$name"? Todos os cards serao removidos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () async {
              await ref.read(deckProvider.notifier).deleteDeck(id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

/// Animated list item with staggered entrance
class _AnimatedDeckItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedDeckItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedDeckItem> createState() => _AnimatedDeckItemState();
}

class _AnimatedDeckItemState extends State<_AnimatedDeckItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slideOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideOffset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final delay = (widget.index * 40).clamp(0, 300);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slideOffset,
        child: widget.child,
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 40.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (color ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: color == null
            ? Icon(Icons.block_rounded,
                size: 18, color: theme.colorScheme.onSurfaceVariant)
            : isSelected
                ? const Icon(Icons.check_rounded,
                    size: 18, color: Colors.white)
                : null,
      ),
    );
  }
}
