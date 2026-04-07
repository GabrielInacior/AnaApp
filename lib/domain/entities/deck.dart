// lib/domain/entities/deck.dart
class Deck {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final int totalCards;
  final int dueCards;
  final bool isFavorite;
  final int? colorValue;
  final List<String> tags;

  const Deck({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.totalCards = 0,
    this.dueCards = 0,
    this.isFavorite = false,
    this.colorValue,
    this.tags = const [],
  });

  Deck copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    int? totalCards,
    int? dueCards,
    bool? isFavorite,
    int? colorValue,
    bool clearColor = false,
    List<String>? tags,
  }) {
    return Deck(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      createdAt: createdAt,
      totalCards: totalCards ?? this.totalCards,
      dueCards: dueCards ?? this.dueCards,
      isFavorite: isFavorite ?? this.isFavorite,
      colorValue: clearColor ? null : (colorValue ?? this.colorValue),
      tags: tags ?? this.tags,
    );
  }
}
