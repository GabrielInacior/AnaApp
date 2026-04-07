// lib/presentation/providers/deck_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/deck.dart';
import 'repository_providers.dart';

final deckProvider =
    AsyncNotifierProvider<DeckNotifier, List<Deck>>(DeckNotifier.new);

class DeckNotifier extends AsyncNotifier<List<Deck>> {
  @override
  Future<List<Deck>> build() async {
    return ref.read(getDecksUseCaseProvider).execute();
  }

  Future<void> createDeck({
    required String name,
    String? description,
    int? colorValue,
    List<String>? tags,
  }) async {
    await ref.read(createDeckUseCaseProvider).execute(
          name: name,
          description: description,
          colorValue: colorValue,
          tags: tags,
        );
    ref.invalidateSelf();
  }

  Future<void> updateDeck(Deck deck) async {
    await ref.read(updateDeckUseCaseProvider).execute(deck);
    ref.invalidateSelf();
  }

  Future<void> deleteDeck(String id) async {
    await ref.read(deleteDeckUseCaseProvider).execute(id);
    ref.invalidateSelf();
  }

  Future<void> toggleFavorite(Deck deck) async {
    final updated = deck.copyWith(isFavorite: !deck.isFavorite);
    await ref.read(updateDeckUseCaseProvider).execute(updated);
    ref.invalidateSelf();
  }

  Future<void> updateDeckColor(Deck deck, int? colorValue) async {
    final updated = colorValue == null
        ? deck.copyWith(clearColor: true)
        : deck.copyWith(colorValue: colorValue);
    await ref.read(updateDeckUseCaseProvider).execute(updated);
    ref.invalidateSelf();
  }
}
