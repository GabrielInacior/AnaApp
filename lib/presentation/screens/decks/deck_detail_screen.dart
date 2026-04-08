// lib/presentation/screens/decks/deck_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_helper.dart';
import '../../../domain/entities/deck.dart';
import '../../../domain/entities/flashcard.dart';
import '../../providers/ai_generation_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/tag_picker.dart';
import '../ai_generate/ai_generate_screen.dart';
import '../review/review_screen.dart';

class DeckDetailScreen extends ConsumerStatefulWidget {
  final Deck deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  ConsumerState<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends ConsumerState<DeckDetailScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String? _selectedTag;
  final _searchController = TextEditingController();
  late final AnimationController _animController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(deckProvider);
    final currentDeck = decksAsync.whenOrNull(
          data: (decks) {
            try {
              return decks.firstWhere((d) => d.id == widget.deck.id);
            } catch (_) {
              return null;
            }
          },
        ) ??
        widget.deck;

    final cardsAsync = ref.watch(cardsByDeckProvider(widget.deck.id));
    final aiState = ref.watch(aiGenerationProvider);
    final isGeneratingForThis = aiState.isGeneratingImages &&
        aiState.generatingForDeckId == widget.deck.id;
    final isLoadingForThis = aiState.isLoading &&
        aiState.generatingForDeckId == widget.deck.id;
    final isAutoTaggingForThis = aiState.isAutoTagging &&
        aiState.generatingForDeckId == widget.deck.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final deckColor = AppColors.getDeckColor(
      currentDeck.colorValue,
      brightness: theme.brightness,
    );

    // Compute untagged cards for AppBar icon
    final knownTags = ref.watch(allTagsProvider);
    final allCards = cardsAsync.whenOrNull(data: (cards) => cards) ?? [];
    final untaggedCards = allCards.where((c) =>
        c.tag == null || c.tag!.isEmpty || !knownTags.contains(c.tag)).toList();
    final hasUntagged = untaggedCards.isNotEmpty && allCards.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(currentDeck.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (isAutoTaggingForThis)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  OutlinedButton.icon(
                    onPressed: hasUntagged && !aiState.isBusy
                        ? () => _autoTagCards(untaggedCards, knownTags, widget.deck.id)
                        : null,
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text(
                      'Gerar tags',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (hasUntagged && !aiState.isBusy)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDeckDialog(context, currentDeck);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Editar baralho'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          SlideUpRoute(page: AIGenerateScreen(deck: currentDeck)),
        ).then((_) {
          ref.invalidate(cardsByDeckProvider);
          ref.invalidate(deckProvider);
        }),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Criar cards'),
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (cardList) {
          if (cardList.isEmpty && !isLoadingForThis) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.auto_stories_outlined, size: 40,
                        color: colorScheme.primary),
                  ),
                  const SizedBox(height: 18),
                  Text('Nenhum card ainda',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Toque em Criar cards para adicionar manualmente ou gerar com IA.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Show skeletons when generating and list is empty
          if (cardList.isEmpty && isLoadingForThis) {
            return Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
                // Loading banner at top
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Gerando cards com IA...',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Skeleton cards
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96, top: 4),
                    itemCount: 5,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) => _SkeletonCard(
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ],
            );
          }

          final dueCount = currentDeck.dueCards;
          final pendingCount =
              cardList.where((c) => c.pendingImage).length;

          return Column(
            children: [
              // ─── Sticky header (doesn't scroll) ───
              FadeTransition(
                opacity: _headerOpacity,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          deckColor.withValues(alpha: isDark ? 0.22 : 0.16),
                          deckColor.withValues(alpha: isDark ? 0.10 : 0.07),
                          deckColor.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: deckColor.withValues(alpha: isDark ? 0.15 : 0.18),
                        ),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + kToolbarHeight,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Summary pills + review button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              _SummaryPill(
                                icon: Icons.layers_rounded,
                                label: '${cardList.length} cards',
                                color: colorScheme.primary,
                                bgColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                              ),
                              const SizedBox(width: 10),
                              _SummaryPill(
                                icon: Icons.schedule_rounded,
                                label: '$dueCount pendentes',
                                color: dueCount > 0
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                                bgColor: dueCount > 0
                                    ? colorScheme.errorContainer.withValues(alpha: 0.3)
                                    : colorScheme.surfaceContainerHighest,
                              ),
                              if (dueCount > 0) ...[
                                const Spacer(),
                                FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    SlideUpRoute(
                                      page: ReviewScreen(
                                        deckId: currentDeck.id,
                                        deckName: currentDeck.name,
                                      ),
                                    ),
                                  ).then((_) {
                                    ref.invalidate(cardsByDeckProvider);
                                    ref.invalidate(deckProvider);
                                  }),
                                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                  label: const Text('Revisar'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // AI text generation in progress banner
                        if (isLoadingForThis)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Gerando cards com IA...',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Image generation progress banner
                        if (isGeneratingForThis || pendingCount > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colorScheme.tertiary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: aiState.imagesToGenerate > 0
                                              ? aiState.imagesGenerated / aiState.imagesToGenerate
                                              : null,
                                          color: colorScheme.tertiary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          isGeneratingForThis && aiState.imagesToGenerate > 0
                                              ? 'Gerando imagens: ${aiState.imagesGenerated}/${aiState.imagesToGenerate}'
                                              : '$pendingCount imagens pendentes...',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: colorScheme.onTertiaryContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isGeneratingForThis && aiState.imagesToGenerate > 0) ...[
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: aiState.imagesGenerated / aiState.imagesToGenerate,
                                        minHeight: 3,
                                        backgroundColor: colorScheme.tertiaryContainer,
                                        color: colorScheme.tertiary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        // Search field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Buscar cards...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                        FocusScope.of(context).unfocus();
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
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Scrollable card list ───
              Expanded(
                child: Builder(builder: (context) {
                  final query = _searchQuery.toLowerCase();
                  var filteredList = query.isEmpty
                      ? cardList
                      : cardList
                          .where((c) =>
                              c.front.toLowerCase().contains(query) ||
                              c.back.toLowerCase().contains(query))
                          .toList();

                  // Collect all tags in this deck's cards
                  final allCardTags = <String>{};
                  for (final c in cardList) {
                    if (c.tag != null && c.tag!.isNotEmpty) {
                      allCardTags.add(c.tag!);
                    }
                  }
                  final sortedTags = allCardTags.toList()..sort();

                  // Apply tag filter
                  if (_selectedTag != null) {
                    filteredList = filteredList
                        .where((c) => c.tag == _selectedTag)
                        .toList();
                  }

                  if (filteredList.isEmpty && query.isEmpty && _selectedTag == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 40,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum card encontrado',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Build grouped or flat list
                  final showGroups = _selectedTag == null &&
                      query.isEmpty &&
                      sortedTags.length > 1;

                  return Column(
                    children: [
                      // Tag filter chips
                      if (sortedTags.isNotEmpty)
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: const Text('Todas'),
                                  selected: _selectedTag == null,
                                  onSelected: (_) =>
                                      setState(() => _selectedTag = null),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              ...sortedTags.map((tag) {
                                    final tagColorVal = ref.read(allTagsProvider.notifier).getTagColor(tag);
                                    final rawColor = tagColorVal != null
                                        ? Color(tagColorVal)
                                        : colorScheme.primary;
                                    // Ensure readable contrast on light mode
                                    final chipColor = isDark
                                        ? rawColor
                                        : _ensureLightContrast(rawColor);
                                    final isSelected = _selectedTag == tag;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(
                                          tag,
                                          style: TextStyle(
                                            color: isSelected
                                                ? chipColor
                                                : chipColor.withValues(alpha: 0.85),
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                        selected: isSelected,
                                        onSelected: (v) => setState(() =>
                                            _selectedTag = v ? tag : null),
                                        backgroundColor: chipColor.withValues(alpha: 0.10),
                                        selectedColor: chipColor.withValues(alpha: 0.20),
                                        checkmarkColor: chipColor,
                                        side: BorderSide(
                                          color: isSelected
                                              ? chipColor.withValues(alpha: 0.5)
                                              : chipColor.withValues(alpha: 0.25),
                                        ),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    );
                                  }),
                            ],
                          ),
                        ),

                      Expanded(
                        child: showGroups
                            ? _buildGroupedList(
                                filteredList, sortedTags, aiState)
                            : _buildFlatList(filteredList, aiState, query),
                      ),
                    ],
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFlatList(
      List<Flashcard> cards, AIGenerationState aiState, String query) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGenerating = aiState.isLoading &&
        aiState.generatingForDeckId == widget.deck.id;

    if (cards.isEmpty && !isGenerating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 40,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Nenhum card encontrado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final skeletonCount = isGenerating ? 3 : 0;
    final totalItems = cards.length + skeletonCount;

    return ListView.separated(
      key: ValueKey('cards-${cards.length}-$query-$isGenerating'),
      padding: const EdgeInsets.only(bottom: 96, top: 4),
      itemCount: totalItems,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        // Skeleton placeholders at end
        if (index >= cards.length) {
          return _SkeletonCard(colorScheme: colorScheme);
        }

        final card = cards[index];
        final isPending =
            card.pendingImage || aiState.pendingImageCardIds.contains(card.id);
        return _AnimatedCardItem(
          key: ValueKey(card.id),
          index: index,
          child: _CardListItem(
            card: card,
            isPendingImage: isPending,
            tagColor: card.tag != null
                ? ref.read(allTagsProvider.notifier).getTagColor(card.tag!)
                : null,
            onTap: () => _showEditCardSheet(context, card),
            onDelete: () async {
              final confirmed = await _confirmDelete(context);
              if (!confirmed) return;
              await ref.read(flashcardRepositoryProvider).deleteCard(card.id);
              ref.invalidate(cardsByDeckProvider);
              ref.invalidate(deckProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupedList(
      List<Flashcard> cards, List<String> tags, AIGenerationState aiState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Group cards by tag
    final grouped = <String, List<Flashcard>>{};
    final untagged = <Flashcard>[];
    for (final card in cards) {
      if (card.tag != null && card.tag!.isNotEmpty) {
        grouped.putIfAbsent(card.tag!, () => []).add(card);
      } else {
        untagged.add(card);
      }
    }

    final sections = <String>[...tags];
    if (untagged.isNotEmpty) sections.add('Sem tag');

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96, top: 4),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];
        final sectionCards =
            section == 'Sem tag' ? untagged : (grouped[section] ?? []);
        if (sectionCards.isEmpty) return const SizedBox.shrink();

        return _CollapsibleTagGroup(
          tag: section,
          count: sectionCards.length,
          theme: theme,
          colorScheme: colorScheme,
          tagColor: section != 'Sem tag'
              ? ref.read(allTagsProvider.notifier).getTagColor(section)
              : null,
          children: sectionCards.map((card) {
            final isPending = card.pendingImage ||
                aiState.pendingImageCardIds.contains(card.id);
            return Column(
              children: [
                _CardListItem(
                  card: card,
                  isPendingImage: isPending,
                  tagColor: card.tag != null
                      ? ref.read(allTagsProvider.notifier).getTagColor(card.tag!)
                      : null,
                  onTap: () => _showEditCardSheet(context, card),
                  onDelete: () async {
                    final confirmed = await _confirmDelete(context);
                    if (!confirmed) return;
                    await ref
                        .read(flashcardRepositoryProvider)
                        .deleteCard(card.id);
                    ref.invalidate(cardsByDeckProvider);
                    ref.invalidate(deckProvider);
                  },
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  void _showEditDeckDialog(
      BuildContext context, Deck currentDeck) {
    final nameCtrl = TextEditingController(text: currentDeck.name);
    final descCtrl =
        TextEditingController(text: currentDeck.description ?? '');
    int? selectedColor = currentDeck.colorValue;
    List<String> selectedTags = List.of(currentDeck.tags);
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
                    controller: nameCtrl,
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: 'Nome do baralho'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
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
                      _buildColorCircle(
                        context: ctx,
                        color: null,
                        isSelected: selectedColor == null,
                        onTap: () =>
                            setSheetState(() => selectedColor = null),
                      ),
                      for (final colorValue in AppColors.deckColorValues)
                        _buildColorCircle(
                          context: ctx,
                          color: AppColors.getDeckColor(colorValue,
                              brightness: brightness),
                          isSelected: selectedColor == colorValue,
                          onTap: () =>
                              setSheetState(() => selectedColor = colorValue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tags section
                  TagPicker(
                    allTags: ref.watch(allTagsProvider),
                    selectedTags: selectedTags,
                    expanded: tagsExpanded,
                    onToggle: () =>
                        setSheetState(() => tagsExpanded = !tagsExpanded),
                    onTagChanged: (tag, v) => setSheetState(() {
                      if (v) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    }),
                    onCustomTagAdded: (tag, colorValue) {
                      ref.read(allTagsProvider.notifier).addTag(tag, colorValue: colorValue);
                      setSheetState(() => selectedTags.add(tag));
                    },
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        final descText = descCtrl.text.trim();
                        final updated = currentDeck.copyWith(
                          name: name,
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

  Widget _buildColorCircle({
    required BuildContext context,
    required Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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

  void _showEditCardSheet(BuildContext context, Flashcard card) {
    final frontCtrl = TextEditingController(text: card.front);
    final backCtrl = TextEditingController(text: card.back);
    String? frontImagePath = card.frontImagePath;
    String? backImagePath = card.backImagePath;
    String? selectedTag = card.tag;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;

          Widget buildImageSection(String label, String? imagePath,
              {required bool isFront}) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                if (imagePath != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(imagePath),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(Icons.broken_image_rounded,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _miniIconButton(
                              icon: Icons.swap_horiz_rounded,
                              color: colorScheme.primaryContainer,
                              iconColor: colorScheme.onPrimaryContainer,
                              onTap: () => _pickImage(isFront, setSheetState,
                                  (path) {
                                if (isFront) {
                                  frontImagePath = path;
                                } else {
                                  backImagePath = path;
                                }
                              }),
                            ),
                            const SizedBox(width: 4),
                            _miniIconButton(
                              icon: Icons.close_rounded,
                              color: colorScheme.errorContainer,
                              iconColor: colorScheme.onErrorContainer,
                              onTap: () => setSheetState(() {
                                if (isFront) {
                                  frontImagePath = null;
                                } else {
                                  backImagePath = null;
                                }
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: () => _pickImage(isFront, setSheetState, (path) {
                      if (isFront) {
                        frontImagePath = path;
                      } else {
                        backImagePath = path;
                      }
                    }),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 64,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 20, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text('Adicionar imagem',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

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
                  Text('Editar Card',
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  const SizedBox(height: 18),
                  TextField(
                    controller: frontCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Frente'),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: backCtrl,
                    decoration: const InputDecoration(labelText: 'Verso'),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 18),
                  buildImageSection('Imagem da frente', frontImagePath,
                      isFront: true),
                  const SizedBox(height: 14),
                  buildImageSection('Imagem do verso', backImagePath,
                      isFront: false),
                  const SizedBox(height: 14),

                  // Tag selector
                  Text('Tag', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Nenhuma'),
                        selected: selectedTag == null,
                        onSelected: (_) =>
                            setSheetState(() => selectedTag = null),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        selectedColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
                        labelStyle: TextStyle(
                          color: selectedTag == null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: selectedTag == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                      ...ref.watch(allTagsProvider).map((tag) {
                            final tagColorVal = ref
                                .read(allTagsProvider.notifier)
                                .getTagColor(tag);
                            final isSelected = selectedTag == tag;
                            final isDark = theme.brightness == Brightness.dark;
                            final chipColor = tagColorVal != null
                                ? Color(tagColorVal)
                                : colorScheme.primary;
                            final bgColor = chipColor.withValues(
                                alpha: isSelected
                                    ? (isDark ? 0.6 : 1.0)
                                    : (isDark ? 0.2 : 0.3));
                            final fgColor = isDark
                                ? (isSelected ? Colors.white : colorScheme.onSurface)
                                : (isSelected
                                    ? Colors.black87
                                    : colorScheme.onSurface.withValues(alpha: 0.8));

                            return GestureDetector(
                              onLongPress: () async {
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
                                  if (ctx.mounted) {
                                    setSheetState(() {
                                      if (selectedTag == tag) selectedTag = null;
                                    });
                                    ref.invalidate(cardsByDeckProvider);
                                  }
                                }
                              },
                              child: FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (v) => setSheetState(
                                    () => selectedTag = v ? tag : null),
                                backgroundColor: bgColor,
                                selectedColor: bgColor,
                                labelStyle: TextStyle(
                                  color: fgColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                checkmarkColor: fgColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? colorScheme.primary.withValues(alpha: 0.3)
                                        : Colors.transparent,
                                  ),
                                ),
                                showCheckmark: isSelected,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              ),
                            );
                          }),
                      ActionChip(
                        avatar: Icon(Icons.add_rounded,
                            size: 16,
                            color: colorScheme.primary),
                        label: const Text('Outro'),
                        onPressed: () {
                          _showCreateTagModalInEdit(ctx, setSheetState,
                              (tag) {
                            setSheetState(() => selectedTag = tag);
                          });
                        },
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        labelStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Fechar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: () async {
                              final front = frontCtrl.text.trim();
                              final back = backCtrl.text.trim();
                              if (front.isEmpty || back.isEmpty) return;

                              final updated = card.copyWith(
                                front: front,
                                back: back,
                                frontImagePath: frontImagePath,
                                clearFrontImage: frontImagePath == null &&
                                    card.frontImagePath != null,
                                backImagePath: backImagePath,
                                clearBackImage: backImagePath == null &&
                                    card.backImagePath != null,
                                tag: selectedTag,
                                clearTag: selectedTag == null && card.tag != null,
                              );
                              await ref
                                  .read(flashcardRepositoryProvider)
                                  .updateCard(updated);
                              ref.invalidate(cardsByDeckProvider);
                              ref.invalidate(deckProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Salvar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateTagModalInEdit(
    BuildContext parentCtx,
    StateSetter parentSetState,
    void Function(String tag) onCreated,
  ) {
    final controller = TextEditingController();
    int? selectedColorValue;

    showModalBottomSheet(
      context: parentCtx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final theme = Theme.of(sheetCtx);
          final colorScheme = theme.colorScheme;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
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
                    GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedColorValue = null),
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
                                : colorScheme.outline
                                    .withValues(alpha: 0.2),
                            width: selectedColorValue == null ? 3 : 1.5,
                          ),
                        ),
                        child: Icon(Icons.auto_awesome_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    for (final colorVal in AppColors.tagColorValues)
                      GestureDetector(
                        onTap: () => setSheetState(
                            () => selectedColorValue = colorVal),
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
                                  : colorScheme.outline
                                      .withValues(alpha: 0.2),
                              width:
                                  selectedColorValue == colorVal ? 3 : 1.5,
                            ),
                            boxShadow: selectedColorValue == colorVal
                                ? [
                                    BoxShadow(
                                      color: Color(colorVal)
                                          .withValues(alpha: 0.4),
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
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        await ref
                            .read(allTagsProvider.notifier)
                            .addTag(text, colorValue: selectedColorValue);
                        onCreated(text);
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
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

  Widget _miniIconButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  Future<void> _pickImage(bool isFront, StateSetter setSheetState,
      void Function(String path) onPicked) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final path = await ImageHelper.saveImage(bytes);
    setSheetState(() => onPicked(path));
  }

  Future<void> _autoTagCards(
    List<Flashcard> untaggedCards,
    List<String> availableTags,
    String deckId,
  ) async {
    final tagged = await ref.read(aiGenerationProvider.notifier).autoTagCards(
          deckId: deckId,
          untaggedCards: untaggedCards,
          availableTags: availableTags,
        );
    if (mounted) {
      final error = ref.read(aiGenerationProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ??
              (tagged > 0
                  ? '$tagged card${tagged > 1 ? 's' : ''} ${tagged > 1 ? 'receberam' : 'recebeu'} tags'
                  : 'Nenhum card foi taggeado')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir card'),
            content:
                const Text('Tem certeza que deseja excluir este card?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// Animated card item with staggered entrance
class _AnimatedCardItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedCardItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedCardItem> createState() => _AnimatedCardItemState();
}

class _AnimatedCardItemState extends State<_AnimatedCardItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slideOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideOffset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final delay = (widget.index * 30).clamp(0, 250);
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

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _CardListItem extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool isPendingImage;
  final int? tagColor;

  const _CardListItem({
    required this.card,
    required this.onDelete,
    this.onTap,
    this.isPendingImage = false,
    this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasImage = card.frontImagePath != null || card.backImagePath != null;
    final imagePath = card.frontImagePath ?? card.backImagePath;
    final resolvedTagColor = tagColor != null
        ? (isDark ? Color(tagColor!) : _ensureLightContrast(Color(tagColor!)))
        : null;

    Widget? leadingWidget;
    if (isPendingImage) {
      leadingWidget = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.tertiary,
            ),
          ),
        ),
      );
    } else if (hasImage && imagePath != null) {
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(imagePath),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.broken_image_rounded,
                size: 20, color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: leadingWidget,
      onTap: onTap,
      title: Text(
        card.front,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.back,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (card.tag != null && card.tag!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: resolvedTagColor != null
                      ? resolvedTagColor.withValues(alpha: 0.18)
                      : colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card.tag!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: resolvedTagColor ??
                        colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _formatInterval(card.interval),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.edit_rounded,
                size: 18, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
            onPressed: onTap,
            tooltip: 'Editar card',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: colorScheme.error.withValues(alpha: 0.7)),
            onPressed: onDelete,
            tooltip: 'Excluir card',
          ),
        ],
      ),
    );
  }

  static String _formatInterval(int intervalDays) {
    if (intervalDays <= 0) return 'novo';
    if (intervalDays == 1) return '1 dia';
    if (intervalDays < 7) return '$intervalDays dias';
    if (intervalDays < 14) return '1 sem';
    if (intervalDays < 30) return '${intervalDays ~/ 7} sem';
    if (intervalDays < 60) return '1 mes';
    if (intervalDays < 365) return '${intervalDays ~/ 30} meses';
    if (intervalDays < 730) return '1 ano';
    return '${intervalDays ~/ 365} anos';
  }
}

class _CollapsibleTagGroup extends StatefulWidget {
  final String tag;
  final int count;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final List<Widget> children;
  final int? tagColor;

  const _CollapsibleTagGroup({
    required this.tag,
    required this.count,
    required this.theme,
    required this.colorScheme,
    required this.children,
    this.tagColor,
  });

  @override
  State<_CollapsibleTagGroup> createState() => _CollapsibleTagGroupState();
}

class _CollapsibleTagGroupState extends State<_CollapsibleTagGroup>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _animController;
  late final CurvedAnimation _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_expanded) {
      _animController.reverse();
    } else {
      _animController.forward();
    }
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawAccent = widget.tagColor != null
        ? Color(widget.tagColor!)
        : widget.colorScheme.primary;
    final accentColor = isDark ? rawAccent : _ensureLightContrast(rawAccent);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    widget.tag,
                    style: widget.theme.textTheme.labelLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: widget.theme.textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: -0.25)
                        .animate(_animation),
                    child: Icon(
                      Icons.expand_less_rounded,
                      size: 18,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Border starts here — below the header
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: accentColor.withValues(alpha: 0.45),
                  width: 2.5,
                ),
              ),
            ),
            margin: const EdgeInsets.only(left: 8),
            child: ClipRect(
              child: SizeTransition(
                sizeFactor: _animation,
                child: Column(children: widget.children),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton card shown while AI is generating
class _SkeletonCard extends StatefulWidget {
  final ColorScheme colorScheme;

  const _SkeletonCard({required this.colorScheme});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final opacity = 0.15 + 0.15 * (0.5 + 0.5 * (_shimmer.value * 2 - 1).abs());
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.colorScheme.primaryContainer
                  .withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          title: Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.colorScheme.onSurface.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              height: 10,
              width: 160,
              decoration: BoxDecoration(
                color: widget.colorScheme.onSurface
                    .withValues(alpha: opacity * 0.6),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ensures a color has enough contrast on white backgrounds.
/// Darkens colors whose luminance is too high (pastel yellows, light blues, etc.).
Color _ensureLightContrast(Color color) {
  final hsl = HSLColor.fromColor(color);
  if (hsl.lightness > 0.58) {
    return hsl.withLightness(0.42).withSaturation((hsl.saturation * 1.15).clamp(0.0, 1.0)).toColor();
  }
  return color;
}
