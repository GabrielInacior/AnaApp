// lib/data/models/deck_model.dart
import '../../domain/entities/deck.dart';

class DeckModel {
  final String id;
  final String name;
  final String? description;
  final String createdAt;

  const DeckModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory DeckModel.fromMap(Map<String, dynamic> map) => DeckModel(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'created_at': createdAt,
      };

  Deck toEntity({int totalCards = 0, int dueCards = 0}) => Deck(
        id: id,
        name: name,
        description: description,
        createdAt: DateTime.parse(createdAt),
        totalCards: totalCards,
        dueCards: dueCards,
      );

  factory DeckModel.fromEntity(Deck deck) => DeckModel(
        id: deck.id,
        name: deck.name,
        description: deck.description,
        createdAt: deck.createdAt.toIso8601String(),
      );
}
