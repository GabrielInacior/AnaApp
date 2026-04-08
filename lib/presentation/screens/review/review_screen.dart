// lib/presentation/screens/review/review_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/sm2.dart';
import '../../providers/repository_providers.dart';
import '../../providers/review_session_provider.dart';
import '../../widgets/flashcard_flip_widget.dart';
import '../../widgets/rating_buttons_widget.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String deckId;
  final String deckName;

  const ReviewScreen(
      {super.key, required this.deckId, required this.deckName});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  Timer? _waitingTimer;

  @override
  void dispose() {
    _waitingTimer?.cancel();
    super.dispose();
  }

  void _startWaitingTimer(DateTime until) {
    _waitingTimer?.cancel();
    final delay = until.difference(DateTime.now());
    if (delay.isNegative) {
      ref.read(reviewSessionProvider(widget.deckId).notifier).checkWaiting();
      return;
    }
    _waitingTimer = Timer(delay + const Duration(seconds: 1), () {
      if (mounted) {
        ref.read(reviewSessionProvider(widget.deckId).notifier).checkWaiting();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(reviewSessionProvider(widget.deckId));
    final notifier = ref.read(reviewSessionProvider(widget.deckId).notifier);

    // Handle waiting state — start timer to re-check
    if (session.isWaiting && session.waitingUntil != null) {
      _startWaitingTimer(session.waitingUntil!);
    }

    if (session.isComplete ||
        (session.currentCard == null &&
            !session.isWaiting &&
            session.total == 0)) {
      return _CompletionScreen(
        deckName: widget.deckName,
        correct: session.correct,
        total: session.total,
      );
    }

    // Waiting for learning cards
    if (session.isWaiting) {
      return _WaitingScreen(
        deckName: widget.deckName,
        waitingUntil: session.waitingUntil,
        onSkip: () {
          // Force check now
          notifier.checkWaiting();
        },
      );
    }

    final card = session.currentCard;
    if (card == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Resolve tag color
    ref.watch(allTagsProvider);
    final tagNotifier = ref.read(allTagsProvider.notifier);
    final tagColorValue = card.tag != null ? tagNotifier.getTagColor(card.tag!) : null;
    final tagColor = tagColorValue != null ? Color(tagColorValue) : null;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Compute dynamic previews for rating buttons
    final previews = AnkiScheduler.previewAll(
      card: card,
      config: session.config,
    );

    // Progress based on cards seen vs total loaded
    final progress = session.total > 0
        ? session.currentIndex / session.total
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor:
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color:
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${session.currentIndex + 1} de ${session.total}',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FlashcardFlipWidget(
                front: card.front,
                back: card.back,
                isFlipped: session.isFlipped,
                onTap: session.isFlipped ? () {} : notifier.flipCard,
                frontImagePath: card.frontImagePath,
                backImagePath: card.backImagePath,
                tag: card.tag,
                tagColor: tagColor,
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
                  previews: previews,
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

class _WaitingScreen extends StatelessWidget {
  final String deckName;
  final DateTime? waitingUntil;
  final VoidCallback onSkip;

  const _WaitingScreen({
    required this.deckName,
    required this.waitingUntil,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final remaining = waitingUntil != null
        ? waitingUntil!.difference(DateTime.now())
        : Duration.zero;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Scaffold(
      appBar: AppBar(title: Text(deckName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color:
                      colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(Icons.hourglass_top_rounded,
                    size: 48, color: colorScheme.primary),
              ),
              const SizedBox(height: 28),
              Text('Aguardando proximo card...',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  minutes > 0
                      ? 'Proximo em ${minutes}min ${seconds}s'
                      : 'Proximo em ${seconds}s',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onSkip,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Verificar agora'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar ao baralho'),
              ),
            ],
          ),
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
    final colorScheme = theme.colorScheme;
    final accuracy = total > 0 ? (correct / total * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(title: Text(deckName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color:
                      colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(Icons.celebration_rounded,
                    size: 48, color: colorScheme.primary),
              ),
              const SizedBox(height: 28),
              Text('Sessao concluida!',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$correct de $total cards — $accuracy% de acerto',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar ao baralho'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
