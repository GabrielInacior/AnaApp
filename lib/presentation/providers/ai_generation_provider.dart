// lib/presentation/providers/ai_generation_provider.dart
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/pdf_parser.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/ai/generate_cards_from_input.dart';
import 'repository_providers.dart';
import 'deck_provider.dart';

class AIGenerationState {
  final bool isLoading;
  final List<Flashcard> generatedCards;
  final String? error;

  const AIGenerationState({
    this.isLoading = false,
    this.generatedCards = const [],
    this.error,
  });
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
    int maxCards = 20,
  }) async {
    state = const AIGenerationState(isLoading: true);
    try {
      final cards = await _ref.read(generateCardsUseCaseProvider).execute(
            deckId: deckId,
            input: topic,
            inputType: AIInputType.topic,
            maxCards: maxCards,
          );
      state = AIGenerationState(generatedCards: cards);
      _ref.invalidate(deckProvider);
    } catch (e) {
      state = AIGenerationState(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> generateFromText({
    required String deckId,
    required String text,
    int maxCards = 20,
  }) async {
    state = const AIGenerationState(isLoading: true);
    try {
      final cards = await _ref.read(generateCardsUseCaseProvider).execute(
            deckId: deckId,
            input: text,
            inputType: AIInputType.text,
            maxCards: maxCards,
          );
      state = AIGenerationState(generatedCards: cards);
      _ref.invalidate(deckProvider);
    } catch (e) {
      state = AIGenerationState(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> generateFromPdf({
    required String deckId,
    required Uint8List pdfBytes,
    required PdfParseMode parseMode,
    int maxCards = 20,
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
          maxCards: maxCards,
        );
      }

      state = AIGenerationState(generatedCards: cards);
      _ref.invalidate(deckProvider);
    } catch (e) {
      state = AIGenerationState(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void reset() => state = const AIGenerationState();
}
