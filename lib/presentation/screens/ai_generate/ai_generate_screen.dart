// lib/presentation/screens/ai_generate/ai_generate_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/pdf_parser.dart';
import '../../../domain/entities/deck.dart';
import '../../../domain/entities/flashcard.dart';
import '../../providers/ai_generation_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/tag_picker.dart';
import '../settings/settings_screen.dart';

enum _CreationMode { manual, ai }

enum _SourceMode { topic, text, pdf }

class AIGenerateScreen extends ConsumerStatefulWidget {
  final Deck deck;
  const AIGenerateScreen({super.key, required this.deck});

  @override
  ConsumerState<AIGenerateScreen> createState() => _AIGenerateScreenState();
}

class _AIGenerateScreenState extends ConsumerState<AIGenerateScreen> {
  // --- Mode ---
  _CreationMode _creationMode = _CreationMode.ai;

  // --- Manual mode ---
  final _frontController = TextEditingController();
  final _backController = TextEditingController();

  // --- AI mode: topic chips ---
  final Set<String> _selectedTopics = {};
  bool _topicExpanded = true;

  // --- AI mode: quantity ---
  int _quantity = 10;

  // --- AI mode: source ---
  _SourceMode _sourceMode = _SourceMode.topic;
  final _descriptionController = TextEditingController();
  final _textController = TextEditingController();

  // --- AI mode: PDF ---
  Uint8List? _pdfBytes;
  String? _pdfName;
  PdfParseMode _parseMode = PdfParseMode.lineByLine;
  final _pdfInstructionsController = TextEditingController();
  bool _isPptx = false;

  // --- AI mode: images ---
  bool _generateImages = false;

  // --- Manual mode: images ---
  String? _manualFrontImagePath;
  String? _manualBackImagePath;

  // --- Manual mode: tag ---
  String? _manualSelectedTag;
  bool _manualTagExpanded = true;

  // --- API key check ---
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    // Reset stale generation results (from a previous session/deck)
    // but only if images are NOT actively generating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiState = ref.read(aiGenerationProvider);
      if (!aiState.isGeneratingImages && !aiState.isLoading) {
        ref.read(aiGenerationProvider.notifier).reset();
      }
    });
  }

  Future<void> _checkApiKey() async {
    const storage = FlutterSecureStorage();
    final key = await storage.read(key: AppConstants.apiKeyStorageKey);
    if (mounted) {
      setState(() => _hasApiKey = key != null && key.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();

    _descriptionController.dispose();
    _textController.dispose();
    _pdfInstructionsController.dispose();
    super.dispose();
  }

  // ───────────────────── topic resolution ─────────────────────
  String _resolveTopic() {
    if (_selectedTopics.isEmpty) return 'Geral';
    return _selectedTopics.join(', ');
  }

  /// Tags to send to AI: selected topics become the available tags
  List<String> _resolveAvailableTags() {
    if (_selectedTopics.isNotEmpty) return _selectedTopics.toList();
    return widget.deck.tags;
  }

  Future<void> _handleTagLongPress(String tag) async {
    final notifier = ref.read(allTagsProvider.notifier);
    final count = await notifier.countCardsWithTag(tag);
    if (!mounted) return;
    final confirmed = await showDeleteTagDialog(
      context,
      tagName: tag,
      cardsWithTag: count,
    );
    if (confirmed) {
      await notifier.deleteTag(tag, clearFromCards: true);
      if (mounted) {
        setState(() => _selectedTopics.remove(tag));
        ref.invalidate(cardsByDeckProvider);
      }
    }
  }

  void _showCreateTagModal(BuildContext ctx) {
    final controller = TextEditingController();
    int? selectedColorValue;

    showModalBottomSheet(
      context: ctx,
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
                        setState(() => _selectedTopics.add(text));
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

  // ───────────────────── manual card creation ─────────────────
  Future<void> _createManualCard() async {
    final front = _frontController.text.trim();
    final back = _backController.text.trim();
    if (front.isEmpty || back.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha frente e verso')),
      );
      return;
    }

    final flashcard = Flashcard(
      id: const Uuid().v4(),
      deckId: widget.deck.id,
      front: front,
      back: back,
      createdAt: DateTime.now(),
      dueDate: DateTime.now(),
      frontImagePath: _manualFrontImagePath,
      backImagePath: _manualBackImagePath,
      tag: _manualSelectedTag,
    );
    await ref.read(flashcardRepositoryProvider).addCard(flashcard);
    ref.invalidate(cardsByDeckProvider);
    ref.invalidate(deckProvider);

    _frontController.clear();
    _backController.clear();
    setState(() {
      _manualFrontImagePath = null;
      _manualBackImagePath = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Card criado com sucesso!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  // ───────────────────── AI generation ─────────────────────────
  Future<void> _generate(AIGenerationNotifier notifier) async {
    notifier.reset();
    final topic = _resolveTopic();
    final tags = _resolveAvailableTags();

    switch (_sourceMode) {
      case _SourceMode.topic:
        await notifier.generateFromTopic(
          deckId: widget.deck.id,
          topic: topic,
          description: _descriptionController.text,
          maxCards: _quantity,
          generateImages: _generateImages,
          availableTags: tags,
        );
      case _SourceMode.text:
        if (_textController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cole um texto primeiro')),
          );
          return;
        }
        await notifier.generateFromText(
          deckId: widget.deck.id,
          text: _textController.text,
          topic: topic,
          maxCards: _quantity,
          generateImages: _generateImages,
          availableTags: tags,
        );
      case _SourceMode.pdf:
        if (_pdfBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecione um documento primeiro')),
          );
          return;
        }
        await notifier.generateFromPdf(
          deckId: widget.deck.id,
          pdfBytes: _pdfBytes!,
          parseMode: _parseMode,
          topic: topic,
          maxCards: _quantity,
          generateImages: _generateImages,
          additionalInstructions: _pdfInstructionsController.text,
          isPptx: _isPptx,
          availableTags: tags,
        );
    }
  }

  // ───────────────────── PDF picker ────────────────────────────
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'pptx'],
      withData: true,
    );
    if (result != null && result.files.first.bytes != null) {
      final file = result.files.first;
      setState(() {
        _pdfBytes = file.bytes;
        _pdfName = file.name;
        _isPptx = file.extension?.toLowerCase() == 'pptx';
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final aiState = ref.watch(aiGenerationProvider);
    final notifier = ref.read(aiGenerationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Criar cards \u2014 ${widget.deck.name}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Mode selector ───
            _buildModeSelector(colorScheme),
            const SizedBox(height: 20),

            // ─── Manual or AI ───
            if (_creationMode == _CreationMode.manual)
              _buildManualSection(theme, colorScheme, isDark)
            else if (!_hasApiKey) ...[
              // API key missing warning
              _SectionContainer(
                colorScheme: colorScheme,
                isDark: isDark,
                child: Column(
                  children: [
                    Icon(Icons.vpn_key_off_rounded,
                        size: 48, color: colorScheme.error.withValues(alpha: 0.7)),
                    const SizedBox(height: 16),
                    Text(
                      'Chave de API necessaria',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Para usar a geracao por IA, adicione sua chave da OpenAI nas Configuracoes.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: const Text('Ir para Configuracoes'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildSourceSection(theme, colorScheme, isDark),
              const SizedBox(height: 20),
              if (_sourceMode != _SourceMode.pdf) ...[
                _buildTopicSection(theme, colorScheme, isDark),
                const SizedBox(height: 20),
              ],
              _buildQuantitySection(theme, colorScheme, isDark),
              const SizedBox(height: 20),
              _buildImageToggle(theme, colorScheme, isDark),
              const SizedBox(height: 24),
              _buildGenerateButton(theme, colorScheme, aiState, notifier),
              const SizedBox(height: 12),

              // ─── Error card ───
              if (aiState.error != null)
                _buildErrorCard(theme, colorScheme),

              // ─── Success card ───
              if (aiState.generatedCards.isNotEmpty)
                _buildSuccessCard(theme, colorScheme),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  WIDGETS
  // ═══════════════════════════════════════════════════════════════

  // ─── Mode Segmented Button ──────────────────────────────────
  Widget _buildModeSelector(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_CreationMode>(
        segments: const [
          ButtonSegment(
            value: _CreationMode.manual,
            icon: Icon(Icons.edit_rounded, size: 18),
            label: Text('Manual'),
          ),
          ButtonSegment(
            value: _CreationMode.ai,
            icon: Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text('Gerar com IA'),
          ),
        ],
        selected: {_creationMode},
        onSelectionChanged: (selection) {
          setState(() => _creationMode = selection.first);
        },
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Manual creation section ────────────────────────────────
  Widget _buildManualSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return _SectionContainer(
      colorScheme: colorScheme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Novo card manual',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _frontController,
            decoration: InputDecoration(
              labelText: 'Frente',
              hintText: 'O que estudar...',
              prefixIcon: const Icon(Icons.translate_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _backController,
            decoration: InputDecoration(
              labelText: 'Verso',
              hintText: 'Resposta / traducao...',
              prefixIcon: const Icon(Icons.spellcheck_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Image upload buttons
          Row(
            children: [
              Expanded(
                child: _ImageUploadButton(
                  label: 'Imagem frente',
                  imagePath: _manualFrontImagePath,
                  colorScheme: colorScheme,
                  onPick: () => _pickManualImage(true),
                  onClear: () => setState(() => _manualFrontImagePath = null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ImageUploadButton(
                  label: 'Imagem verso',
                  imagePath: _manualBackImagePath,
                  colorScheme: colorScheme,
                  onPick: () => _pickManualImage(false),
                  onClear: () => setState(() => _manualBackImagePath = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tag selector (same style as AI topic chips)
          _buildManualTagSection(theme, colorScheme, isDark),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _createManualCard,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar card'),
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
  }

  // ─── Manual tag selector (single select, same style as AI topics) ──
  Widget _buildManualTagSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final topics = ref.watch(allTagsProvider);
    final tagNotifier = ref.read(allTagsProvider.notifier);

    final chipColors = [
      const Color(0xFFF8BBD0),
      const Color(0xFFFFCCBC),
      const Color(0xFFFFF9C4),
      const Color(0xFFC8E6C9),
      const Color(0xFFBBDEFB),
      const Color(0xFFD1C4E9),
      const Color(0xFFE1BEE7),
      const Color(0xFFB2DFDB),
    ];
    final darkChipColors = [
      const Color(0xFF880E4F),
      const Color(0xFFBF360C),
      const Color(0xFFF9A825),
      const Color(0xFF2E7D32),
      const Color(0xFF1565C0),
      const Color(0xFF4527A0),
      const Color(0xFF6A1B9A),
      const Color(0xFF00695C),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _manualTagExpanded = !_manualTagExpanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Icon(Icons.label_rounded,
                  size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tag do card',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!_manualTagExpanded && _manualSelectedTag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _manualSelectedTag!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (!_manualTagExpanded && _manualSelectedTag == null)
                Text('Nenhuma',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _manualTagExpanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 22,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 1,
              children: [
                ...List.generate(topics.length, (i) {
                  final topic = topics[i];
                  final isSelected = _manualSelectedTag == topic;
                  final tagColorVal = tagNotifier.getTagColor(topic);
                  final Color chipColor;
                  if (tagColorVal != null) {
                    chipColor = Color(tagColorVal);
                  } else {
                    chipColor = isDark
                        ? darkChipColors[i % darkChipColors.length]
                        : chipColors[i % chipColors.length];
                  }
                  final bgColor = chipColor.withValues(
                      alpha: isSelected
                          ? (isDark ? 0.6 : 1.0)
                          : (isDark ? 0.2 : 0.3));
                  final fgColor = isDark
                      ? (isSelected
                          ? Colors.white
                          : colorScheme.onSurface)
                      : (isSelected
                          ? Colors.black87
                          : colorScheme.onSurface
                              .withValues(alpha: 0.8));

                  return GestureDetector(
                    onLongPress: () => _handleTagLongPress(topic),
                    child: FilterChip(
                      label: Text(topic),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _manualSelectedTag = selected ? topic : null;
                        });
                      },
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
                              ? colorScheme.primary
                                  .withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      showCheckmark: isSelected,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                    ),
                  );
                }),
                ActionChip(
                  avatar: Icon(Icons.add_rounded,
                      size: 18, color: colorScheme.primary),
                  label: const Text('Outro'),
                  onPressed: () => _showCreateTagModal(context),
                  backgroundColor:
                      colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _manualTagExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }

  // ─── Topic chips section (collapsible) ────────────────────
  Widget _buildTopicSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final topics = ref.watch(allTagsProvider);

    // Fallback pastel chip colors for tags without DB color
    final chipColors = [
      const Color(0xFFF8BBD0), // pink
      const Color(0xFFFFCCBC), // peach
      const Color(0xFFFFF9C4), // cream
      const Color(0xFFC8E6C9), // mint
      const Color(0xFFBBDEFB), // baby blue
      const Color(0xFFD1C4E9), // lavender
      const Color(0xFFE1BEE7), // lilac
      const Color(0xFFB2DFDB), // teal
    ];

    final darkChipColors = [
      const Color(0xFF880E4F), // pink dark
      const Color(0xFFBF360C), // peach dark
      const Color(0xFFF9A825), // cream dark
      const Color(0xFF2E7D32), // mint dark
      const Color(0xFF1565C0), // blue dark
      const Color(0xFF4527A0), // lavender dark
      const Color(0xFF6A1B9A), // lilac dark
      const Color(0xFF00695C), // teal dark
    ];

    final resolvedTopic = _resolveTopic();
    final hasSelection = _selectedTopics.isNotEmpty;

    return _SectionContainer(
      colorScheme: colorScheme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header
          GestureDetector(
            onTap: () => setState(() => _topicExpanded = !_topicExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.category_rounded,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Escolha o assunto',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Show selected topic labels when collapsed
                if (!_topicExpanded && hasSelection)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedTopics.length > 2
                            ? '${_selectedTopics.length} assuntos'
                            : resolvedTopic,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _topicExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Collapsible content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 1,
                    children: [
                      ...List.generate(topics.length, (i) {
                        final topic = topics[i];
                        final isSelected = _selectedTopics.contains(topic);
                        // Use tag color from DB if available, else fallback to pastel rotation
                        final tagNotifier = ref.read(allTagsProvider.notifier);
                        final tagColorVal = tagNotifier.getTagColor(topic);
                        final Color chipColor;
                        if (tagColorVal != null) {
                          chipColor = Color(tagColorVal);
                        } else {
                          chipColor = isDark
                              ? darkChipColors[i % darkChipColors.length]
                              : chipColors[i % chipColors.length];
                        }
                        final bgColor = chipColor.withValues(
                            alpha: isSelected ? (isDark ? 0.6 : 1.0) : (isDark ? 0.2 : 0.3));
                        final fgColor = isDark
                            ? (isSelected ? Colors.white : colorScheme.onSurface)
                            : (isSelected
                                ? Colors.black87
                                : colorScheme.onSurface.withValues(alpha: 0.8));

                        return GestureDetector(
                          onLongPress: () => _handleTagLongPress(topic),
                          child: FilterChip(
                          label: Text(topic),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTopics.add(topic);
                              } else {
                                _selectedTopics.remove(topic);
                              }
                            });
                          },
                          backgroundColor: bgColor,
                          selectedColor: bgColor,
                          labelStyle: TextStyle(
                            color: fgColor,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
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
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                        );
                      }),
                      // "+ Outro" chip — opens tag creator modal
                      ActionChip(
                        avatar: Icon(Icons.add_rounded,
                            size: 18, color: colorScheme.primary),
                        label: const Text('Outro'),
                        onPressed: () => _showCreateTagModal(context),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _topicExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  // ─── Quantity slider section ────────────────────────────────
  Widget _buildQuantitySection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return _SectionContainer(
      colorScheme: colorScheme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Quantidade de cards',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_quantity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('5', style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              )),
              Expanded(
                child: Slider(
                  value: _quantity.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  label: '$_quantity',
                  onChanged: (v) =>
                      setState(() => _quantity = v.round()),
                ),
              ),
              Text('30', style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              )),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Source section (topic / text / pdf) ────────────────────
  Widget _buildSourceSection(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return _SectionContainer(
      colorScheme: colorScheme,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.source_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Fonte do conteudo',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Source choice chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _sourceChoiceChip(
                label: 'Tema',
                icon: Icons.lightbulb_rounded,
                mode: _SourceMode.topic,
                colorScheme: colorScheme,
              ),
              _sourceChoiceChip(
                label: 'Texto',
                icon: Icons.text_snippet_rounded,
                mode: _SourceMode.text,
                colorScheme: colorScheme,
              ),
              _sourceChoiceChip(
                label: 'Documento',
                icon: Icons.description_rounded,
                mode: _SourceMode.pdf,
                colorScheme: colorScheme,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dynamic source content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            child: _buildSourceContent(theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _sourceChoiceChip({
    required String label,
    required IconData icon,
    required _SourceMode mode,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _sourceMode == mode;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label,
          style: const TextStyle(fontSize: 12), // diminui aqui
        ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _sourceMode = mode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildSourceContent(ThemeData theme, ColorScheme colorScheme) {
    switch (_sourceMode) {
      case _SourceMode.topic:
        return TextField(
          key: const ValueKey('source-topic'),
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Instrucoes adicionais (opcional)',
            hintText: 'Ex: foco em vocabulario de viagem...',
            prefixIcon: const Icon(Icons.notes_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          minLines: 1,
        );

      case _SourceMode.text:
        return TextField(
          key: const ValueKey('source-text'),
          controller: _textController,
          maxLines: 8,
          minLines: 4,
          decoration: InputDecoration(
            labelText: 'Texto',
            hintText: 'Cole o texto aqui...',
            alignLabelWithHint: true,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 80),
              child: Icon(Icons.content_paste_rounded),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          textCapitalization: TextCapitalization.sentences,
        );

      case _SourceMode.pdf:
        return Column(
          key: const ValueKey('source-pdf'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parse mode
            Text(
              'Modo de leitura:',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<PdfParseMode>(
              groupValue: _parseMode,
              onChanged: (v) => setState(() => _parseMode = v!),
              child: Column(
                children: [
                  RadioListTile<PdfParseMode>(
                    value: PdfParseMode.lineByLine,
                    title: const Text('Pares prontos'),
                    subtitle: const Text(
                      'A IA identifica pares bilíngues já existentes no documento',
                    ),
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  RadioListTile<PdfParseMode>(
                    value: PdfParseMode.aiInterpreted,
                    title: const Text('IA interpreta'),
                    subtitle: const Text('A IA analisa o texto e cria os cards'),
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),

            // Additional instructions (only for AI-interpreted mode)
            if (_parseMode == PdfParseMode.aiInterpreted) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _pdfInstructionsController,
                maxLines: 3,
                minLines: 2,
                decoration: InputDecoration(
                  labelText: 'Instrucoes para a IA (opcional)',
                  hintText: 'Ex: Crie cards com perguntas em ingles e respostas em portugues...',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.psychology_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  helperText: 'Se vazio, a IA segue pelo contexto do documento',
                  helperMaxLines: 2,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickPdf,
                icon: Icon(_isPptx
                    ? Icons.slideshow_rounded
                    : Icons.upload_file_rounded),
                label: Text(_pdfName ?? 'Selecionar documento'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_pdfName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _pdfName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
    }
  }

  // ─── Generate button ────────────────────────────────────────
  Widget _buildGenerateButton(
    ThemeData theme,
    ColorScheme colorScheme,
    AIGenerationState aiState,
    AIGenerationNotifier notifier,
  ) {
    // Only block while generating card text, not during background image gen
    final isTextLoading = aiState.isLoading;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: isTextLoading ? null : () => _generate(notifier),
            icon: isTextLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(
              isTextLoading ? 'Gerando cards...' : 'Gerar $_quantity cards',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        // Image generation progress (shown below button)
        if (aiState.isGeneratingImages && aiState.imagesToGenerate > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
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
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: aiState.imagesGenerated / aiState.imagesToGenerate,
                          color: colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Gerando imagens: ${aiState.imagesGenerated}/${aiState.imagesToGenerate}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
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
              ),
            ),
          ),
      ],
    );
  }

  // ─── Error card ─────────────────────────────────────────────
  Widget _buildErrorCard(ThemeData theme, ColorScheme colorScheme) {
    final aiState = ref.read(aiGenerationProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: colorScheme.error, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                aiState.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Success card ───────────────────────────────────────────
  Widget _buildSuccessCard(ThemeData theme, ColorScheme colorScheme) {
    final aiState = ref.watch(aiGenerationProvider);
    final isImaging = aiState.isGeneratingImages;
    final done = aiState.imagesGenerated;
    final total = aiState.imagesToGenerate;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isImaging ? Icons.image_rounded : Icons.celebration_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isImaging
                        ? '${aiState.generatedCards.length} cards criados! Gerando imagens...'
                        : total > 0 && done == total
                            ? '${aiState.generatedCards.length} cards com imagens prontos!'
                            : '${aiState.generatedCards.length} cards gerados e adicionados ao baralho!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (isImaging || (total > 0 && done > 0)) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  minHeight: 6,
                  backgroundColor: colorScheme.primaryContainer,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isImaging
                    ? '$done de $total imagens geradas'
                    : '$done imagens geradas',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Image toggle (AI mode) ────────────────────────────────
  Widget _buildImageToggle(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return _SectionContainer(
      colorScheme: colorScheme,
      isDark: isDark,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Icon(Icons.image_rounded, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Gerar imagens com IA',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            '~R\$0,01 por card (DALL-E 2)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        value: _generateImages,
        onChanged: (v) => setState(() => _generateImages = v),
      ),
    );
  }

  // ─── Pick image for manual card ────────────────────────────
  Future<void> _pickManualImage(bool isFront) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final savedPath = await ImageHelper.saveImage(bytes);

    setState(() {
      if (isFront) {
        _manualFrontImagePath = savedPath;
      } else {
        _manualBackImagePath = savedPath;
      }
    });
  }
}

// ═══════════════════════════════════════════════════════════════
//  Reusable section container
// ═══════════════════════════════════════════════════════════════
class _SectionContainer extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isDark;
  final Widget child;

  const _SectionContainer({
    required this.colorScheme,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withValues(alpha: 0.2)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Image upload button for manual mode
// ═══════════════════════════════════════════════════════════════
class _ImageUploadButton extends StatelessWidget {
  final String label;
  final String? imagePath;
  final ColorScheme colorScheme;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ImageUploadButton({
    required this.label,
    required this.imagePath,
    required this.colorScheme,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(imagePath!),
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded,
                size: 22, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
