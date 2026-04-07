// lib/presentation/providers/ai_generation_provider.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/image_helper.dart';
import '../../core/utils/pdf_parser.dart';
import '../../data/datasources/remote/openai_client.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/ai/generate_cards_from_input.dart';
import 'repository_providers.dart';
import 'deck_provider.dart';

class AIGenerationState {
  final bool isLoading;
  final bool isGeneratingImages;
  final List<Flashcard> generatedCards;
  final String? error;
  final int imagesGenerated;
  final int imagesToGenerate;
  final Set<String> pendingImageCardIds;
  final String? generatingForDeckId;

  const AIGenerationState({
    this.isLoading = false,
    this.isGeneratingImages = false,
    this.generatedCards = const [],
    this.error,
    this.imagesGenerated = 0,
    this.imagesToGenerate = 0,
    this.pendingImageCardIds = const {},
    this.generatingForDeckId,
  });

  bool get isBusy => isLoading || isGeneratingImages;
}

final aiGenerationProvider =
    StateNotifierProvider<AIGenerationNotifier, AIGenerationState>(
        (ref) => AIGenerationNotifier(ref));

class AIGenerationNotifier extends StateNotifier<AIGenerationState> {
  final Ref _ref;
  AIGenerationNotifier(this._ref) : super(const AIGenerationState());

  Future<void> generateFromTopic({
    required String deckId,
    required String topic,
    String? description,
    int maxCards = 20,
    bool generateImages = false,
  }) async {
    state = const AIGenerationState(isLoading: true);
    try {
      final input = description != null && description.trim().isNotEmpty
          ? '$topic: ${description.trim()}'
          : topic;
      final cards = await _ref.read(generateCardsUseCaseProvider).execute(
            deckId: deckId,
            input: input,
            inputType: AIInputType.topic,
            topic: topic,
            maxCards: maxCards,
          );
      state = AIGenerationState(generatedCards: cards);
      _ref.invalidate(deckProvider);
      _ref.invalidate(cardsByDeckProvider);

      if (generateImages) {
        unawaited(_generateImagesInBackground(cards, deckId));
      }
    } catch (e) {
      state = AIGenerationState(
          error: e is Failure ? e.message : e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> generateFromText({
    required String deckId,
    required String text,
    required String topic,
    int maxCards = 20,
    bool generateImages = false,
  }) async {
    state = const AIGenerationState(isLoading: true);
    try {
      final cards = await _ref.read(generateCardsUseCaseProvider).execute(
            deckId: deckId,
            input: text,
            inputType: AIInputType.text,
            topic: topic,
            maxCards: maxCards,
          );
      state = AIGenerationState(generatedCards: cards);
      _ref.invalidate(deckProvider);
      _ref.invalidate(cardsByDeckProvider);

      if (generateImages) {
        unawaited(_generateImagesInBackground(cards, deckId));
      }
    } catch (e) {
      state = AIGenerationState(
          error: e is Failure ? e.message : e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> generateFromPdf({
    required String deckId,
    required Uint8List pdfBytes,
    required PdfParseMode parseMode,
    required String topic,
    int maxCards = 20,
    bool generateImages = false,
  }) async {
    state = const AIGenerationState(isLoading: true);
    try {
      final rawText = PdfParser.extractRawText(pdfBytes);
      final useCase = _ref.read(generateCardsUseCaseProvider);
      List<Flashcard> cards;

      if (parseMode == PdfParseMode.lineByLine) {
        final pairs = PdfParser.parseLineByLine(rawText);
        cards = await useCase.fromParsedPairs(
          deckId: deckId,
          pairs: pairs
              .map((p) => (front: p.front, back: p.back))
              .toList(),
        );
      } else {
        final text = PdfParser.prepareTextForAI(rawText);
        cards = await useCase.execute(
          deckId: deckId,
          input: text,
          inputType: AIInputType.pdfAI,
          topic: topic,
          maxCards: maxCards,
        );
      }

      state = AIGenerationState(generatedCards: cards);
      _ref.invalidate(deckProvider);
      _ref.invalidate(cardsByDeckProvider);

      if (generateImages) {
        unawaited(_generateImagesInBackground(cards, deckId));
      }
    } catch (e) {
      state = AIGenerationState(
          error: e is Failure ? e.message : e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Generate images in background — survives screen navigation
  Future<void> _generateImagesInBackground(List<Flashcard> cards, String deckId) async {
    final secureStorage = _ref.read(secureStorageProvider);
    final apiKey =
        await secureStorage.read(key: AppConstants.apiKeyStorageKey);
    if (apiKey == null || apiKey.isEmpty) return;

    final openAIClient = _ref.read(openAIClientProvider);
    final flashcardDao = _ref.read(flashcardDaoProvider);

    final pendingIds = cards.map((c) => c.id).toSet();

    state = AIGenerationState(
      generatedCards: state.generatedCards,
      isGeneratingImages: true,
      imagesToGenerate: cards.length,
      imagesGenerated: 0,
      pendingImageCardIds: Set.of(pendingIds),
      generatingForDeckId: deckId,
    );

    for (int i = 0; i < cards.length; i++) {
      if (!mounted) return;

      try {
        final prompt =
            OpenAIClient.buildImagePrompt(cards[i].front, cards[i].back);
        final imageBytes =
            await openAIClient.generateImage(apiKey: apiKey, prompt: prompt);
        final path = await ImageHelper.saveImage(imageBytes);
        // Targeted update: only set image path + clear pending flag
        // Does NOT overwrite review progress (dueDate, interval, queue, etc.)
        await flashcardDao.updateImagePath(cards[i].id, frontImagePath: path);
      } catch (_) {
        // Image failed — clear pending flag only
        try {
          await flashcardDao.updateImagePath(cards[i].id);
        } catch (_) {}
      }

      if (!mounted) return;

      pendingIds.remove(cards[i].id);

      state = AIGenerationState(
        generatedCards: state.generatedCards,
        isGeneratingImages: i + 1 < cards.length,
        imagesToGenerate: cards.length,
        imagesGenerated: i + 1,
        pendingImageCardIds: Set.of(pendingIds),
        generatingForDeckId: i + 1 < cards.length ? deckId : null,
      );

      // Refresh the card list after each image
      _ref.invalidate(cardsByDeckProvider);
    }

    _ref.invalidate(deckProvider);
  }

  void reset() => state = const AIGenerationState();
}
