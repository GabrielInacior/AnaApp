// lib/presentation/screens/review/review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/review_session_provider.dart';
import '../../widgets/flashcard_flip_widget.dart';
import '../../widgets/rating_buttons_widget.dart';

class ReviewScreen extends ConsumerWidget {
  final String deckId;
  final String deckName;

  const ReviewScreen({super.key, required this.deckId, required this.deckName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(reviewSessionProvider(deckId));
    final notifier = ref.read(reviewSessionProvider(deckId).notifier);

    if (session.isComplete || (session.queue.isEmpty && session.total == 0)) {
      return _CompletionScreen(
        deckName: deckName,
        correct: session.correct,
        total: session.total,
      );
    }

    final card = session.currentCard;
    if (card == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = session.total > 0
        ? session.currentIndex / session.total
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(deckName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${session.currentIndex + 1} / ${session.total}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FlashcardFlipWidget(
                front: card.front,
                back: card.back,
                isFlipped: session.isFlipped,
                onTap: session.isFlipped ? () {} : notifier.flipCard,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: session.isFlipped ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !session.isFlipped,
                child: RatingButtonsWidget(
                  onRate: notifier.submitRating,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  final String deckName;
  final int correct;
  final int total;

  const _CompletionScreen({
    required this.deckName,
    required this.correct,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration_rounded,
                  size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text('Sessão concluída!',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$correct de $total cards — $accuracy% de acerto',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar ao baralho'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
