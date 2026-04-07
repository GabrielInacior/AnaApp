// lib/domain/entities/deck.dart
class Deck {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final int totalCards;
  final int dueCards;

  const Deck({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.totalCards = 0,
    this.dueCards = 0,
  });

  Deck copyWith({
    String? name,
    String? description,
    int? totalCards,
    int? dueCards,
  }) {
    return Deck(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      totalCards: totalCards ?? this.totalCards,
      dueCards: dueCards ?? this.dueCards,
    );
  }
}
