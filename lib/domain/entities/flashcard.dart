// lib/domain/entities/flashcard.dart
class Flashcard {
  final String id;
  final String deckId;
  final String front;    // frase em inglês
  final String back;     // tradução em português
  final DateTime createdAt;

  // Campos SM-2
  final double easeFactor;   // fator de facilidade (inicia em 2.5)
  final int interval;        // intervalo em dias
  final int repetitions;     // número de repetições consecutivas corretas
  final DateTime dueDate;    // próxima data de revisão

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    required this.dueDate,
  });

  Flashcard copyWith({
    String? front,
    String? back,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? dueDate,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      createdAt: createdAt,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
