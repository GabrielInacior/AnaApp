// lib/data/models/deck_model.dart
import '../../domain/entities/deck.dart';

class DeckModel {
  final String id;
  final String name;
  final String? description;
  final String createdAt;
  final bool isFavorite;
  final int? colorValue;
  final String? tags;

  const DeckModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.isFavorite = false,
    this.colorValue,
    this.tags,
  });

  factory DeckModel.fromMap(Map<String, dynamic> map) => DeckModel(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        createdAt: map['created_at'] as String,
        isFavorite: (map['is_favorite'] as int?) == 1,
        colorValue: map['color_value'] as int?,
        tags: map['tags'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'created_at': createdAt,
        'is_favorite': isFavorite ? 1 : 0,
        'color_value': colorValue,
        'tags': tags,
      };

  Deck toEntity({int totalCards = 0, int dueCards = 0}) => Deck(
        id: id,
        name: name,
        description: description,
        createdAt: DateTime.parse(createdAt),
        totalCards: totalCards,
        dueCards: dueCards,
        isFavorite: isFavorite,
        colorValue: colorValue,
        tags: tags != null && tags!.isNotEmpty
            ? tags!.split(',').where((t) => t.isNotEmpty).toList()
            : const [],
      );

  factory DeckModel.fromEntity(Deck deck) => DeckModel(
        id: deck.id,
        name: deck.name,
        description: deck.description,
        createdAt: deck.createdAt.toIso8601String(),
        isFavorite: deck.isFavorite,
        colorValue: deck.colorValue,
        tags: deck.tags.isEmpty ? null : deck.tags.join(','),
      );
}
