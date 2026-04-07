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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentDeck.name),
        actions: [
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
          if (cardList.isEmpty) {
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

          final now = DateTime.now();
          final dueCount =
              cardList.where((c) => !c.dueDate.isAfter(now)).length;
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
                      color: theme.scaffoldBackgroundColor,
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
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
                                  ),
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
                  final filteredList = query.isEmpty
                      ? cardList
                      : cardList
                          .where((c) =>
                              c.front.toLowerCase().contains(query) ||
                              c.back.toLowerCase().contains(query))
                          .toList();

                  if (filteredList.isEmpty) {
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

                  return ListView.separated(
                    key: ValueKey('cards-${filteredList.length}-$query'),
                    padding: const EdgeInsets.only(bottom: 96, top: 4),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colorScheme.outlineVariant
                          .withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final card = filteredList[index];
                      final isPending = card.pendingImage ||
                          aiState.pendingImageCardIds.contains(card.id);
                      return _AnimatedCardItem(
                        key: ValueKey(card.id),
                        index: index,
                        child: _CardListItem(
                          card: card,
                          isPendingImage: isPending,
                          onTap: () => _showEditCardSheet(context, card),
                          onDelete: () async {
                            final confirmed =
                                await _confirmDelete(context);
                            if (!confirmed) return;
                            await ref
                                .read(flashcardRepositoryProvider)
                                .deleteCard(card.id);
                            ref.invalidate(cardsByDeckProvider);
                            ref.invalidate(deckProvider);
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          );
        },
      ),
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

                  // Tags section (collapsible)
                  GestureDetector(
                    onTap: () =>
                        setSheetState(() => tagsExpanded = !tagsExpanded),
                    child: Row(
                      children: [
                        Text('Tags',
                            style: Theme.of(ctx).textTheme.labelLarge),
                        const Spacer(),
                        if (!tagsExpanded && selectedTags.isEmpty)
                          Text('Nenhuma',
                              style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              )),
                        Icon(tagsExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded),
                      ],
                    ),
                  ),
                  if (!tagsExpanded && selectedTags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedTags.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close_rounded, size: 14),
                          onDeleted: () => setSheetState(() => selectedTags.remove(tag)),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
                    ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: tagsExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppColors.predefinedTags.map((tag) {
                          final isSelected = selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (v) => setSheetState(() {
                              if (v) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            }),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          );
                        }).toList(),
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
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
                        );
                        await ref
                            .read(flashcardRepositoryProvider)
                            .updateCard(updated);
                        ref.invalidate(cardsByDeckProvider);
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

  const _CardListItem({
    required this.card,
    required this.onDelete,
    this.onTap,
    this.isPendingImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = card.frontImagePath != null || card.backImagePath != null;
    final imagePath = card.frontImagePath ?? card.backImagePath;

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
      subtitle: Text(
        card.back,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
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
              '${card.interval}d',
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
}
