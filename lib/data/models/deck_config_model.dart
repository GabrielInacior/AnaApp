// lib/data/models/deck_config_model.dart
import '../../domain/entities/deck_config.dart';

class DeckConfigModel {
  final String deckId;
  final int newCardsPerDay;
  final int reviewsPerDay;
  final String learningSteps;
  final int graduatingInterval;
  final int easyInterval;
  final String relearningSteps;
  final int lapseThreshold;
  final int maxInterval;

  const DeckConfigModel({
    required this.deckId,
    required this.newCardsPerDay,
    required this.reviewsPerDay,
    required this.learningSteps,
    required this.graduatingInterval,
    required this.easyInterval,
    required this.relearningSteps,
    required this.lapseThreshold,
    required this.maxInterval,
  });

  factory DeckConfigModel.fromMap(Map<String, dynamic> map) =>
      DeckConfigModel(
        deckId: map['deck_id'] as String,
        newCardsPerDay: map['new_cards_per_day'] as int,
        reviewsPerDay: map['reviews_per_day'] as int,
        learningSteps: map['learning_steps'] as String,
        graduatingInterval: map['graduating_interval'] as int,
        easyInterval: map['easy_interval'] as int,
        relearningSteps: map['relearning_steps'] as String,
        lapseThreshold: map['lapse_threshold'] as int,
        maxInterval: map['max_interval'] as int,
      );

  Map<String, dynamic> toMap() => {
        'deck_id': deckId,
        'new_cards_per_day': newCardsPerDay,
        'reviews_per_day': reviewsPerDay,
        'learning_steps': learningSteps,
        'graduating_interval': graduatingInterval,
        'easy_interval': easyInterval,
        'relearning_steps': relearningSteps,
        'lapse_threshold': lapseThreshold,
        'max_interval': maxInterval,
      };

  DeckConfig toEntity() => DeckConfig(
        deckId: deckId,
        newCardsPerDay: newCardsPerDay,
        reviewsPerDay: reviewsPerDay,
        learningSteps: _parseIntList(learningSteps),
        graduatingInterval: graduatingInterval,
        easyInterval: easyInterval,
        relearningSteps: _parseIntList(relearningSteps),
        lapseThreshold: lapseThreshold,
        maxInterval: maxInterval,
      );

  factory DeckConfigModel.fromEntity(DeckConfig config) => DeckConfigModel(
        deckId: config.deckId,
        newCardsPerDay: config.newCardsPerDay,
        reviewsPerDay: config.reviewsPerDay,
        learningSteps: config.learningSteps.join(','),
        graduatingInterval: config.graduatingInterval,
        easyInterval: config.easyInterval,
        relearningSteps: config.relearningSteps.join(','),
        lapseThreshold: config.lapseThreshold,
        maxInterval: config.maxInterval,
      );

  static List<int> _parseIntList(String csv) {
    if (csv.isEmpty) return [];
    return csv.split(',').map((s) => int.parse(s.trim())).toList();
  }
}
