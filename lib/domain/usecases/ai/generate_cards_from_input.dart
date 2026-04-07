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
        prompt = 'Gere $maxCards flashcards de inglês sobre o tema: "$input"';
      case AIInputType.text:
      case AIInputType.pdfAI:
        prompt =
            'Extraia e gere até $maxCards flashcards de inglês a partir deste texto:\n\n$input';
      case AIInputType.pdfLineByLine:
        throw const ParseFailure(
            'pdfLineByLine deve ser processado antes de chamar este use case.');
    }

    final generated = await _aiClient.generateCards(
      apiKey: apiKey,
      prompt: prompt,
      maxCards: maxCards,
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
              easeFactor: SM2.initialEaseFactor,
            ))
        .toList();

    await _cardRepository.addCards(cards);
    return cards;
  }

  /// Para o modo PDF line-by-line: recebe pares prontos e salva diretamente
  Future<List<Flashcard>> fromParsedPairs({
    required String deckId,
    required List<({String front, String back})> pairs,
  }) async {
    final now = DateTime.now();
    final cards = pairs
        .map((p) => Flashcard(
              id: _uuid.v4(),
              deckId: deckId,
              front: p.front,
              back: p.back,
              createdAt: now,
              dueDate: now,
              easeFactor: SM2.initialEaseFactor,
            ))
        .toList();
    await _cardRepository.addCards(cards);
    return cards;
  }
}
