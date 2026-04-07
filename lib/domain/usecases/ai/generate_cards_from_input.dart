// lib/domain/usecases/ai/generate_cards_from_input.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/sm2.dart';
import '../../../data/datasources/remote/openai_client.dart';
import '../../entities/flashcard.dart';
import '../../repositories/flashcard_repository.dart';

enum AIInputType { text, pdfLineByLine, pdfAI, topic }

class GenerateCardsFromInput {
  final OpenAIClient _aiClient;
  final FlashcardRepository _cardRepository;
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;

  GenerateCardsFromInput({
    required OpenAIClient aiClient,
    required FlashcardRepository cardRepository,
    required FlutterSecureStorage secureStorage,
    Uuid? uuid,
  })  : _aiClient = aiClient,
        _cardRepository = cardRepository,
        _secureStorage = secureStorage,
        _uuid = uuid ?? const Uuid();

  Future<List<Flashcard>> execute({
    required String deckId,
    required String input,
    required AIInputType inputType,
    required String topic,
    int maxCards = 20,
  }) async {
    final apiKey = await _secureStorage.read(key: AppConstants.apiKeyStorageKey);
    if (apiKey == null || apiKey.isEmpty) {
      throw const AIFailure(
          'Chave de API não configurada. Adicione sua chave nas configurações.');
    }

    String prompt;
    switch (inputType) {
      case AIInputType.topic:
        prompt = 'Gere $maxCards flashcards sobre: "$input"';
      case AIInputType.text:
      case AIInputType.pdfAI:
        prompt =
            'Extraia e gere até $maxCards flashcards a partir deste texto:\n\n$input';
      case AIInputType.pdfLineByLine:
        prompt =
            'Este documento contém pares bilíngues já prontos (frases em um idioma seguidas da tradução em outro). '
            'Identifique TODOS os pares de frases e extraia-os como flashcards. '
            'Cada par forma um card: front = frase no idioma estrangeiro, back = tradução em português. '
            'Junte fragmentos que continuam a mesma frase. Ignore cabeçalhos, rodapés e marcas d\'água.\n\n$input';
    }

    final generated = await _aiClient.generateCards(
      apiKey: apiKey,
      prompt: prompt,
      topic: topic,
      maxCards: maxCards,
      isPdfLineByLine: inputType == AIInputType.pdfLineByLine,
    );

    final now = DateTime.now();
    final cards = generated
        .map((g) => Flashcard(
              id: _uuid.v4(),
              deckId: deckId,
              front: g.front,
              back: g.back,
              createdAt: now,
              dueDate: now,
              easeFactor: AnkiScheduler.initialEaseFactor,
            ))
        .toList();

    await _cardRepository.addCards(cards);
    return cards;
  }
}
