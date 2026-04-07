// lib/presentation/screens/decks/deck_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/deck.dart';
import '../../../domain/entities/flashcard.dart';
import '../../providers/repository_providers.dart';
import '../ai_generate/ai_generate_screen.dart';
import '../review/review_screen.dart';

class DeckDetailScreen extends ConsumerWidget {
  final Deck deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(_cardsByDeckProvider(deck.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Gerar com IA',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AIGenerateScreen(deck: deck)),
            ),
          ),
        ],
      ),
      floatingActionButton: deck.dueCards > 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReviewScreen(deckId: deck.id, deckName: deck.name),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Revisar (${deck.dueCards})'),
            )
          : null,
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (cardList) {
          if (cardList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.style_outlined, size: 60),
                  const SizedBox(height: 16),
                  const Text('Nenhum card ainda'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AIGenerateScreen(deck: deck)),
                    ),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Gerar cards com IA'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: cardList.length,
            itemBuilder: (context, i) {
              final card = cardList[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(card.front,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(card.back),
                  trailing: Text(
                    'Int: ${card.interval}d',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Auto-dispose provider for cards by deck
final _cardsByDeckProvider = FutureProvider.autoDispose
    .family<List<Flashcard>, String>((ref, deckId) {
  return ref.read(flashcardRepositoryProvider).getCardsByDeck(deckId);
});
