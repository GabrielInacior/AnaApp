// lib/presentation/screens/ai_generate/ai_generate_screen.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/pdf_parser.dart';
import '../../../domain/entities/deck.dart';
import '../../providers/ai_generation_provider.dart';
import '../../widgets/api_key_info_banner.dart';

class AIGenerateScreen extends ConsumerStatefulWidget {
  final Deck deck;
  const AIGenerateScreen({super.key, required this.deck});

  @override
  ConsumerState<AIGenerateScreen> createState() => _AIGenerateScreenState();
}

class _AIGenerateScreenState extends ConsumerState<AIGenerateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _topicController = TextEditingController();
  final _textController = TextEditingController();
  Uint8List? _pdfBytes;
  String? _pdfName;
  PdfParseMode _parseMode = PdfParseMode.lineByLine;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiGenerationProvider);
    final notifier = ref.read(aiGenerationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gerar cards — ${widget.deck.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Tema'),
            Tab(icon: Icon(Icons.text_fields), text: 'Texto'),
            Tab(icon: Icon(Icons.picture_as_pdf_outlined), text: 'PDF'),
          ],
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: ApiKeyInfoBanner(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TopicTab(controller: _topicController),
                _TextTab(controller: _textController),
                _PdfTab(
                  pdfName: _pdfName,
                  parseMode: _parseMode,
                  onPickPdf: _pickPdf,
                  onModeChanged: (m) => setState(() => _parseMode = m),
                ),
              ],
            ),
          ),
          if (aiState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiState.error!,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (aiState.generatedCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${aiState.generatedCards.length} cards gerados e adicionados ao baralho!',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: aiState.isLoading ? null : () => _generate(notifier),
                icon: aiState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label:
                    Text(aiState.isLoading ? 'Gerando...' : 'Gerar cards'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _pdfBytes = result.files.first.bytes;
        _pdfName = result.files.first.name;
      });
    }
  }

  Future<void> _generate(AIGenerationNotifier notifier) async {
    final tab = _tabController.index;
    notifier.reset();

    switch (tab) {
      case 0:
        if (_topicController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Digite um tema')));
          return;
        }
        await notifier.generateFromTopic(
          deckId: widget.deck.id,
          topic: _topicController.text,
        );
      case 1:
        if (_textController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cole um texto')));
          return;
        }
        await notifier.generateFromText(
          deckId: widget.deck.id,
          text: _textController.text,
        );
      case 2:
        if (_pdfBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selecione um PDF')));
          return;
        }
        await notifier.generateFromPdf(
          deckId: widget.deck.id,
          pdfBytes: _pdfBytes!,
          parseMode: _parseMode,
        );
    }
  }
}

class _TopicTab extends StatelessWidget {
  final TextEditingController controller;
  const _TopicTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sugira um tema e a IA gerará os cards automaticamente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Tema',
              hintText: 'Ex: viagem ao exterior, entrevista de emprego...',
              prefixIcon: Icon(Icons.lightbulb_outline),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}

class _TextTab extends StatelessWidget {
  final TextEditingController controller;
  const _TextTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cole um texto em inglês e a IA extrairá frases para os cards.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                labelText: 'Texto',
                hintText: 'Cole o texto aqui...',
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfTab extends StatelessWidget {
  final String? pdfName;
  final PdfParseMode parseMode;
  final VoidCallback onPickPdf;
  final void Function(PdfParseMode) onModeChanged;

  const _PdfTab({
    required this.pdfName,
    required this.parseMode,
    required this.onPickPdf,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Modo de leitura do PDF:',
              style: theme.textTheme.labelLarge),
          RadioGroup<PdfParseMode>(
            groupValue: parseMode,
            onChanged: (v) => onModeChanged(v!),
            child: const Column(
              children: [
                RadioListTile<PdfParseMode>(
                  value: PdfParseMode.lineByLine,
                  title: Text('Linha a linha'),
                  subtitle: Text(
                      'Linha ímpar = inglês, linha par = tradução\n(ideal para materiais do seu curso)'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<PdfParseMode>(
                  value: PdfParseMode.aiInterpreted,
                  title: Text('IA interpreta'),
                  subtitle: Text('A IA analisa o texto e cria os cards'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPickPdf,
            icon: const Icon(Icons.upload_file),
            label: Text(pdfName ?? 'Selecionar PDF'),
          ),
          if (pdfName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(pdfName!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
