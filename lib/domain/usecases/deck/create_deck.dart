// lib/domain/usecases/deck/create_deck.dart
import 'package:uuid/uuid.dart';
import '../../entities/deck.dart';
import '../../repositories/deck_repository.dart';

class CreateDeck {
  final DeckRepository _repository;
  final Uuid _uuid;

  CreateDeck(this._repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<Deck> execute({required String name, String? description}) async {
    final deck = Deck(
      id: _uuid.v4(),
      name: name.trim(),
      description: description?.trim(),
      createdAt: DateTime.now(),
    );
    await _repository.createDeck(deck);
    return deck;
  }
}
