// lib/presentation/screens/decks/decks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/deck_card_widget.dart';
import '../../widgets/empty_state_widget.dart';
import 'deck_detail_screen.dart';

class DecksScreen extends ConsumerWidget {
  const DecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(deckProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Baralhos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDeckSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo Baralho'),
      ),
      body: decksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (decks) {
          if (decks.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.style_outlined,
              title: 'Nenhum baralho ainda',
              subtitle: 'Crie seu primeiro baralho para começar a aprender.',
              action: FilledButton.icon(
                onPressed: () => _showCreateDeckSheet(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Criar baralho'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: decks.length,
            itemBuilder: (context, i) {
              final deck = decks[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DeckCardWidget(
                  deck: deck,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DeckDetailScreen(deck: deck)),
                  ),
                  onDelete: () => _confirmDelete(context, ref, deck.id, deck.name),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDeckSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Novo Baralho',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome do baralho'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  await ref.read(deckProvider.notifier).createDeck(
                        name: nameController.text,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Criar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir baralho'),
        content: Text('Tem certeza que deseja excluir "$name"? Todos os cards serão removidos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await ref.read(deckProvider.notifier).deleteDeck(id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
