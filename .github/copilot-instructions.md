# AnaApp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build AnaApp — um clone inteligente do AnkiDroid em Flutter com geração de flashcards via IA (OpenAI gpt-4o-mini), repetição espaçada (SM-2), armazenamento SQLite e UI Material Design 3.

**Architecture:** Clean Architecture com camadas domain/data/presentation, MVVM via Riverpod 2 (StateNotifier/AsyncNotifier como ViewModels), repositórios abstratos na camada domain com implementações concretas na camada data.

**Tech Stack:** Flutter 3.x, Riverpod 2, sqflite, OpenAI REST API (gpt-4o-mini), flutter_secure_storage, dynamic_color, syncfusion_flutter_pdf, file_picker, fl_chart, uuid, intl.

---

## File Map

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart          # strings, limits, defaults
│   │   └── openai_constants.dart       # model name, endpoints
│   ├── errors/
│   │   └── failures.dart               # sealed class Failure
│   ├── theme/
│   │   ├── app_theme.dart              # ThemeData light/dark + M3
│   │   └── app_colors.dart             # fallback color seeds
│   └── utils/
│       ├── sm2.dart                    # SM-2 algorithm (pure functions)
│       ├── date_utils.dart             # due date helpers
│       └── pdf_parser.dart             # PDF text extraction + parsing modes
├── domain/
│   ├── entities/
│   │   ├── deck.dart
│   │   ├── flashcard.dart
│   │   ├── review_log.dart
│   │   └── app_user.dart
│   ├── repositories/
│   │   ├── deck_repository.dart        # abstract interface
│   │   ├── flashcard_repository.dart   # abstract interface
│   │   ├── review_repository.dart      # abstract interface
│   │   └── user_repository.dart        # abstract interface
│   └── usecases/
│       ├── deck/
│       │   ├── create_deck.dart
│       │   ├── get_decks.dart
│       │   ├── delete_deck.dart
│       │   └── update_deck.dart
│       ├── flashcard/
│       │   ├── get_due_cards.dart
│       │   ├── add_cards_to_deck.dart
│       │   └── delete_card.dart
│       ├── review/
│       │   ├── submit_review.dart       # applies SM-2, saves log
│       │   └── get_stats.dart
│       └── ai/
│           └── generate_cards_from_input.dart
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── database_helper.dart    # SQLite init, migrations
│   │   │   ├── deck_dao.dart
│   │   │   ├── flashcard_dao.dart
│   │   │   ├── review_dao.dart
│   │   │   └── user_dao.dart
│   │   └── remote/
│   │       └── openai_client.dart      # POST /chat/completions
│   ├── models/
│   │   ├── deck_model.dart             # fromMap/toMap
│   │   ├── flashcard_model.dart
│   │   ├── review_log_model.dart
│   │   └── app_user_model.dart
│   └── repositories/
│       ├── deck_repository_impl.dart
│       ├── flashcard_repository_impl.dart
│       ├── review_repository_impl.dart
│       └── user_repository_impl.dart
└── presentation/
    ├── providers/
    │   ├── repository_providers.dart   # Riverpod providers for repos + use cases
    │   ├── deck_provider.dart          # AsyncNotifier<List<Deck>>
    │   ├── review_session_provider.dart # StateNotifier para sessão ativa
    │   ├── ai_generation_provider.dart  # AsyncNotifier para geração IA
    │   ├── stats_provider.dart
    │   └── user_provider.dart
    ├── screens/
    │   ├── onboarding/
    │   │   └── onboarding_screen.dart
    │   ├── home/
    │   │   └── home_screen.dart
    │   ├── decks/
    │   │   ├── decks_screen.dart
    │   │   └── deck_detail_screen.dart
    │   ├── review/
    │   │   └── review_screen.dart
    │   ├── ai_generate/
    │   │   └── ai_generate_screen.dart
    │   ├── stats/
    │   │   └── stats_screen.dart
    │   └── settings/
    │       └── settings_screen.dart
    └── widgets/
        ├── flashcard_flip_widget.dart   # flip animation
        ├── deck_card_widget.dart
        ├── rating_buttons_widget.dart   # Again/Hard/Good/Easy
        ├── empty_state_widget.dart
        └── api_key_info_banner.dart     # banner explicativo da API key
```

---

## Task 1: Criar projeto Flutter e configurar dependências

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `lib/app.dart`

- [ ] **Step 1: Criar o projeto Flutter**

```bash
cd C:/Project
flutter create --org com.anaapp --project-name ana_app AnaApp
cd AnaApp
```

- [ ] **Step 2: Substituir pubspec.yaml com dependências do projeto**

```yaml
name: ana_app
description: AnaApp - Flashcards inteligentes com IA
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1

  # Database
  sqflite: ^2.3.3+1
  path: ^1.9.0

  # Secure storage (API key)
  flutter_secure_storage: ^9.2.2

  # HTTP
  http: ^1.2.1

  # PDF
  syncfusion_flutter_pdf: ^26.2.14
  file_picker: ^8.1.2

  # Dynamic Color (Material You)
  dynamic_color: ^1.7.0

  # Charts
  fl_chart: ^0.68.0

  # Utils
  intl: ^0.19.0
  shared_preferences: ^2.3.2
  uuid: ^4.4.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.11

flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

- [ ] **Step 3: Criar pastas de assets e instalar dependências**

```bash
mkdir -p lib/core/constants lib/core/errors lib/core/theme lib/core/utils
mkdir -p lib/domain/entities lib/domain/repositories lib/domain/usecases/deck
mkdir -p lib/domain/usecases/flashcard lib/domain/usecases/review lib/domain/usecases/ai
mkdir -p lib/data/datasources/local lib/data/datasources/remote
mkdir -p lib/data/models lib/data/repositories
mkdir -p lib/presentation/providers
mkdir -p lib/presentation/screens/onboarding lib/presentation/screens/home
mkdir -p lib/presentation/screens/decks lib/presentation/screens/review
mkdir -p lib/presentation/screens/ai_generate lib/presentation/screens/stats
mkdir -p lib/presentation/screens/settings lib/presentation/widgets
mkdir -p assets/images docs/superpowers/plans
flutter pub get
```

- [ ] **Step 4: Verificar que não há erros**

```bash
flutter analyze
```
Expected: `No issues found!` (ou apenas warnings de código gerado)

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: configure project dependencies"
```

---

## Task 2: Sistema de Tema (Material Design 3 + Dynamic Color)

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Criar app_colors.dart (seed color fallback)**

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color seedColor = Color(0xFF4A90D9); // azul confiável
  static const Color seedColorDark = Color(0xFF82B4F0);
}
```

- [ ] **Step 2: Criar app_theme.dart**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({ColorScheme? dynamicScheme}) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.seedColor,
          brightness: Brightness.light,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    );
  }

  static ThemeData dark({ColorScheme? dynamicScheme}) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: AppColors.seedColor,
          brightness: Brightness.dark,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    );
  }
}
```

- [ ] **Step 3: Criar app.dart com Dynamic Color**

```dart
// lib/app.dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';

class AnaApp extends ConsumerWidget {
  const AnaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'AnaApp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dynamicScheme: lightDynamic),
          darkTheme: AppTheme.dark(dynamicScheme: darkDynamic),
          themeMode: ThemeMode.system,
          home: userAsync.when(
            data: (user) =>
                user == null ? const OnboardingScreen() : const HomeScreen(),
            loading: () =>
                const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (_, __) => const OnboardingScreen(),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Atualizar main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AnaApp()));
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/ lib/app.dart lib/main.dart
git commit -m "feat: add Material 3 theme with Dynamic Color support"
```

---

## Task 3: Domain Layer — Entidades e Interfaces de Repositório

**Files:**
- Create: `lib/domain/entities/deck.dart`
- Create: `lib/domain/entities/flashcard.dart`
- Create: `lib/domain/entities/review_log.dart`
- Create: `lib/domain/entities/app_user.dart`
- Create: `lib/domain/repositories/deck_repository.dart`
- Create: `lib/domain/repositories/flashcard_repository.dart`
- Create: `lib/domain/repositories/review_repository.dart`
- Create: `lib/domain/repositories/user_repository.dart`
- Create: `lib/core/errors/failures.dart`

- [ ] **Step 1: Criar entidades**

```dart
// lib/domain/entities/app_user.dart
class AppUser {
  final String id;
  final String name;
  final DateTime createdAt;

  const AppUser({required this.id, required this.name, required this.createdAt});
}
```

```dart
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
```

```dart
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
```

```dart
// lib/domain/entities/review_log.dart
class ReviewLog {
  final String id;
  final String cardId;
  final String deckId;
  final int rating;        // 0=Again, 2=Hard, 3=Good, 4=Easy
  final DateTime reviewedAt;
  final int intervalAfter; // intervalo aplicado após a revisão

  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.deckId,
    required this.rating,
    required this.reviewedAt,
    required this.intervalAfter,
  });
}
```

- [ ] **Step 2: Criar Failures**

```dart
// lib/core/errors/failures.dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AIFailure extends Failure {
  const AIFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
```

- [ ] **Step 3: Criar interfaces de repositório**

```dart
// lib/domain/repositories/deck_repository.dart
import '../entities/deck.dart';

abstract interface class DeckRepository {
  Future<List<Deck>> getDecks();
  Future<Deck?> getDeckById(String id);
  Future<void> createDeck(Deck deck);
  Future<void> updateDeck(Deck deck);
  Future<void> deleteDeck(String id);
}
```

```dart
// lib/domain/repositories/flashcard_repository.dart
import '../entities/flashcard.dart';

abstract interface class FlashcardRepository {
  Future<List<Flashcard>> getCardsByDeck(String deckId);
  Future<List<Flashcard>> getDueCards(String deckId, DateTime now);
  Future<List<Flashcard>> getAllDueCards(DateTime now);
  Future<void> addCard(Flashcard card);
  Future<void> addCards(List<Flashcard> cards);
  Future<void> updateCard(Flashcard card);
  Future<void> deleteCard(String id);
  Future<int> countCardsByDeck(String deckId);
  Future<int> countDueCardsByDeck(String deckId, DateTime now);
}
```

```dart
// lib/domain/repositories/review_repository.dart
import '../entities/review_log.dart';

abstract interface class ReviewRepository {
  Future<void> saveReviewLog(ReviewLog log);
  Future<List<ReviewLog>> getReviewLogs({DateTime? from, DateTime? to});
  Future<List<ReviewLog>> getReviewLogsByDeck(String deckId);
  Future<int> countReviewsToday();
}
```

```dart
// lib/domain/repositories/user_repository.dart
import '../entities/app_user.dart';

abstract interface class UserRepository {
  Future<AppUser?> getUser();
  Future<void> saveUser(AppUser user);
  Future<void> updateUserName(String name);
}
```

- [ ] **Step 4: Escrever testes das entidades**

```dart
// test/domain/entities/flashcard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ana_app/domain/entities/flashcard.dart';

void main() {
  group('Flashcard', () {
    final card = Flashcard(
      id: '1',
      deckId: 'd1',
      front: 'Hello',
      back: 'Olá',
      createdAt: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 1, 1),
    );

    test('has default SM-2 values', () {
      expect(card.easeFactor, 2.5);
      expect(card.interval, 0);
      expect(card.repetitions, 0);
    });

    test('copyWith updates fields', () {
      final updated = card.copyWith(front: 'Hi', easeFactor: 2.8);
      expect(updated.front, 'Hi');
      expect(updated.easeFactor, 2.8);
      expect(updated.back, card.back);
      expect(updated.id, card.id);
    });
  });
}
```

- [ ] **Step 5: Rodar testes**

```bash
flutter test test/domain/entities/flashcard_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/domain/ lib/core/errors/ test/domain/
git commit -m "feat: add domain entities, repository interfaces and failure types"
```

---

## Task 4: Core Utils — SM-2 e PDF Parser

**Files:**
- Create: `lib/core/utils/sm2.dart`
- Create: `lib/core/utils/pdf_parser.dart`
- Create: `lib/core/constants/app_constants.dart`
- Create: `lib/core/constants/openai_constants.dart`
- Create: `test/core/utils/sm2_test.dart`

- [ ] **Step 1: Implementar o algoritmo SM-2**

```dart
// lib/core/utils/sm2.dart
import 'package:flutter/foundation.dart';

/// Ratings para avaliação do card
enum CardRating {
  again(0),   // Errou — reinicia
  hard(2),    // Lembrou com dificuldade
  good(3),    // Lembrou corretamente
  easy(4);    // Lembrou com facilidade

  final int value;
  const CardRating(this.value);
}

@immutable
class SM2Result {
  final double easeFactor;
  final int interval;     // dias até próxima revisão
  final int repetitions;

  const SM2Result({
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
  });
}

class SM2 {
  SM2._();

  static const double _minEaseFactor = 1.3;
  static const double _initialEaseFactor = 2.5;

  /// Calcula o próximo intervalo baseado no rating.
  /// [easeFactor] fator atual (inicia em 2.5)
  /// [interval] intervalo atual em dias
  /// [repetitions] número de repetições consecutivas corretas
  /// [rating] avaliação do usuário
  static SM2Result calculate({
    required double easeFactor,
    required int interval,
    required int repetitions,
    required CardRating rating,
  }) {
    if (rating == CardRating.again) {
      // Reinicia repetições, intervalo volta a 1
      return SM2Result(
        easeFactor: (easeFactor - 0.2).clamp(_minEaseFactor, 5.0),
        interval: 1,
        repetitions: 0,
      );
    }

    // Calcula novo easeFactor: EF' = EF + (0.1 - (5-q)*(0.08 + (5-q)*0.02))
    final q = rating.value;
    final newEF = (easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
        .clamp(_minEaseFactor, 5.0);

    int newInterval;
    final newRepetitions = repetitions + 1;

    if (repetitions == 0) {
      newInterval = 1;
    } else if (repetitions == 1) {
      newInterval = 6;
    } else {
      newInterval = (interval * newEF).round();
    }

    if (rating == CardRating.easy) {
      newInterval = (newInterval * 1.3).round();
    }

    return SM2Result(
      easeFactor: newEF,
      interval: newInterval,
      repetitions: newRepetitions,
    );
  }

  static DateTime nextDueDate(int intervalDays, {DateTime? from}) {
    final base = from ?? DateTime.now();
    return DateTime(base.year, base.month, base.day + intervalDays);
  }

  static double get initialEaseFactor => _initialEaseFactor;
}
```

- [ ] **Step 2: Escrever testes do SM-2**

```dart
// test/core/utils/sm2_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ana_app/core/utils/sm2.dart';

void main() {
  group('SM2.calculate', () {
    test('again resets repetitions and sets interval to 1', () {
      final result = SM2.calculate(
        easeFactor: 2.5,
        interval: 10,
        repetitions: 5,
        rating: CardRating.again,
      );
      expect(result.repetitions, 0);
      expect(result.interval, 1);
      expect(result.easeFactor, lessThan(2.5));
    });

    test('first good review gives interval 1', () {
      final result = SM2.calculate(
        easeFactor: 2.5,
        interval: 0,
        repetitions: 0,
        rating: CardRating.good,
      );
      expect(result.interval, 1);
      expect(result.repetitions, 1);
    });

    test('second good review gives interval 6', () {
      final result = SM2.calculate(
        easeFactor: 2.5,
        interval: 1,
        repetitions: 1,
        rating: CardRating.good,
      );
      expect(result.interval, 6);
      expect(result.repetitions, 2);
    });

    test('third review multiplies by easeFactor', () {
      final result = SM2.calculate(
        easeFactor: 2.5,
        interval: 6,
        repetitions: 2,
        rating: CardRating.good,
      );
      expect(result.interval, (6 * result.easeFactor).round());
    });

    test('easy rating gives bonus interval', () {
      final easy = SM2.calculate(
        easeFactor: 2.5,
        interval: 6,
        repetitions: 2,
        rating: CardRating.easy,
      );
      final good = SM2.calculate(
        easeFactor: 2.5,
        interval: 6,
        repetitions: 2,
        rating: CardRating.good,
      );
      expect(easy.interval, greaterThan(good.interval));
    });

    test('easeFactor never goes below 1.3', () {
      var ef = 1.4;
      for (int i = 0; i < 20; i++) {
        final result = SM2.calculate(
          easeFactor: ef,
          interval: 1,
          repetitions: 0,
          rating: CardRating.again,
        );
        ef = result.easeFactor;
      }
      expect(ef, greaterThanOrEqualTo(1.3));
    });
  });
}
```

- [ ] **Step 3: Rodar testes do SM-2**

```bash
flutter test test/core/utils/sm2_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 4: Implementar PDF Parser**

```dart
// lib/core/utils/pdf_parser.dart
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum PdfParseMode {
  /// Linha ímpar = inglês, linha par = português
  lineByLine,
  /// IA interpreta o texto livremente (texto bruto enviado para OpenAI)
  aiInterpreted,
}

class ParsedCardPair {
  final String front;
  final String back;
  const ParsedCardPair({required this.front, required this.back});
}

class PdfParser {
  PdfParser._();

  /// Extrai texto bruto do PDF
  static String extractRawText(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();
    return text;
  }

  /// Modo lineByLine: cada par de linhas consecutivas forma um card
  static List<ParsedCardPair> parseLineByLine(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final pairs = <ParsedCardPair>[];
    for (int i = 0; i + 1 < lines.length; i += 2) {
      pairs.add(ParsedCardPair(front: lines[i], back: lines[i + 1]));
    }
    return pairs;
  }

  /// Modo aiInterpreted: retorna o texto bruto para a IA processar
  static String prepareTextForAI(String rawText) {
    return rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');
  }
}
```

- [ ] **Step 5: Criar constantes**

```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  static const String appName = 'AnaApp';
  static const int maxCardsPerSession = 20;
  static const int maxCardsPerAIGeneration = 50;
  static const String exportFileExtension = '.anaapp.json';
  static const String apiKeyStorageKey = 'openai_api_key';
  static const String userNamePrefKey = 'user_name';
}
```

```dart
// lib/core/constants/openai_constants.dart
class OpenAIConstants {
  OpenAIConstants._();

  static const String baseUrl = 'https://api.openai.com/v1';
  static const String chatEndpoint = '$baseUrl/chat/completions';
  static const String model = 'gpt-4o-mini';
  static const int maxTokens = 2000;
  static const double temperature = 0.3;
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/core/ test/core/
git commit -m "feat: add SM-2 algorithm, PDF parser and app constants"
```

---

## Task 5: Data Layer — Database e DAOs

**Files:**
- Create: `lib/data/datasources/local/database_helper.dart`
- Create: `lib/data/models/deck_model.dart`
- Create: `lib/data/models/flashcard_model.dart`
- Create: `lib/data/models/review_log_model.dart`
- Create: `lib/data/models/app_user_model.dart`
- Create: `lib/data/datasources/local/deck_dao.dart`
- Create: `lib/data/datasources/local/flashcard_dao.dart`
- Create: `lib/data/datasources/local/review_dao.dart`
- Create: `lib/data/datasources/local/user_dao.dart`

- [ ] **Step 1: Criar DatabaseHelper com schema e migrações**

```dart
// lib/data/datasources/local/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'anaapp.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE decks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        created_at TEXT NOT NULL,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        interval_days INTEGER NOT NULL DEFAULT 0,
        repetitions INTEGER NOT NULL DEFAULT 0,
        due_date TEXT NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE review_logs (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        deck_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        reviewed_at TEXT NOT NULL,
        interval_after INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_cards_deck ON flashcards(deck_id)');
    await db.execute('CREATE INDEX idx_cards_due ON flashcards(due_date)');
    await db.execute('CREATE INDEX idx_logs_date ON review_logs(reviewed_at)');
  }
}
```

- [ ] **Step 2: Criar modelos (DTOs)**

```dart
// lib/data/models/app_user_model.dart
import '../../domain/entities/app_user.dart';

class AppUserModel {
  final String id;
  final String name;
  final String createdAt;

  const AppUserModel({required this.id, required this.name, required this.createdAt});

  factory AppUserModel.fromMap(Map<String, dynamic> map) => AppUserModel(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt,
      };

  AppUser toEntity() => AppUser(
        id: id,
        name: name,
        createdAt: DateTime.parse(createdAt),
      );

  factory AppUserModel.fromEntity(AppUser user) => AppUserModel(
        id: user.id,
        name: user.name,
        createdAt: user.createdAt.toIso8601String(),
      );
}
```

```dart
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
```

```dart
// lib/data/models/flashcard_model.dart
import '../../domain/entities/flashcard.dart';

class FlashcardModel {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final String createdAt;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final String dueDate;

  const FlashcardModel({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueDate,
  });

  factory FlashcardModel.fromMap(Map<String, dynamic> map) => FlashcardModel(
        id: map['id'] as String,
        deckId: map['deck_id'] as String,
        front: map['front'] as String,
        back: map['back'] as String,
        createdAt: map['created_at'] as String,
        easeFactor: (map['ease_factor'] as num).toDouble(),
        intervalDays: map['interval_days'] as int,
        repetitions: map['repetitions'] as int,
        dueDate: map['due_date'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'deck_id': deckId,
        'front': front,
        'back': back,
        'created_at': createdAt,
        'ease_factor': easeFactor,
        'interval_days': intervalDays,
        'repetitions': repetitions,
        'due_date': dueDate,
      };

  Flashcard toEntity() => Flashcard(
        id: id,
        deckId: deckId,
        front: front,
        back: back,
        createdAt: DateTime.parse(createdAt),
        easeFactor: easeFactor,
        interval: intervalDays,
        repetitions: repetitions,
        dueDate: DateTime.parse(dueDate),
      );

  factory FlashcardModel.fromEntity(Flashcard card) => FlashcardModel(
        id: card.id,
        deckId: card.deckId,
        front: card.front,
        back: card.back,
        createdAt: card.createdAt.toIso8601String(),
        easeFactor: card.easeFactor,
        intervalDays: card.interval,
        repetitions: card.repetitions,
        dueDate: card.dueDate.toIso8601String(),
      );
}
```

```dart
// lib/data/models/review_log_model.dart
import '../../domain/entities/review_log.dart';

class ReviewLogModel {
  final String id;
  final String cardId;
  final String deckId;
  final int rating;
  final String reviewedAt;
  final int intervalAfter;

  const ReviewLogModel({
    required this.id,
    required this.cardId,
    required this.deckId,
    required this.rating,
    required this.reviewedAt,
    required this.intervalAfter,
  });

  factory ReviewLogModel.fromMap(Map<String, dynamic> map) => ReviewLogModel(
        id: map['id'] as String,
        cardId: map['card_id'] as String,
        deckId: map['deck_id'] as String,
        rating: map['rating'] as int,
        reviewedAt: map['reviewed_at'] as String,
        intervalAfter: map['interval_after'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'card_id': cardId,
        'deck_id': deckId,
        'rating': rating,
        'reviewed_at': reviewedAt,
        'interval_after': intervalAfter,
      };

  ReviewLog toEntity() => ReviewLog(
        id: id,
        cardId: cardId,
        deckId: deckId,
        rating: rating,
        reviewedAt: DateTime.parse(reviewedAt),
        intervalAfter: intervalAfter,
      );

  factory ReviewLogModel.fromEntity(ReviewLog log) => ReviewLogModel(
        id: log.id,
        cardId: log.cardId,
        deckId: log.deckId,
        rating: log.rating,
        reviewedAt: log.reviewedAt.toIso8601String(),
        intervalAfter: log.intervalAfter,
      );
}
```

- [ ] **Step 3: Criar DAOs**

```dart
// lib/data/datasources/local/deck_dao.dart
import '../../../domain/entities/deck.dart';
import '../../models/deck_model.dart';
import 'database_helper.dart';

class DeckDAO {
  final DatabaseHelper _helper;
  DeckDAO(this._helper);

  Future<List<Deck>> getAll() async {
    final db = await _helper.database;
    final maps = await db.query('decks', orderBy: 'created_at DESC');
    return maps.map((m) => DeckModel.fromMap(m).toEntity()).toList();
  }

  Future<Deck?> getById(String id) async {
    final db = await _helper.database;
    final maps = await db.query('decks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return DeckModel.fromMap(maps.first).toEntity();
  }

  Future<void> insert(Deck deck) async {
    final db = await _helper.database;
    await db.insert('decks', DeckModel.fromEntity(deck).toMap());
  }

  Future<void> update(Deck deck) async {
    final db = await _helper.database;
    await db.update('decks', DeckModel.fromEntity(deck).toMap(),
        where: 'id = ?', whereArgs: [deck.id]);
  }

  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }
}
```

```dart
// lib/data/datasources/local/flashcard_dao.dart
import '../../../domain/entities/flashcard.dart';
import '../../models/flashcard_model.dart';
import 'database_helper.dart';

class FlashcardDAO {
  final DatabaseHelper _helper;
  FlashcardDAO(this._helper);

  Future<List<Flashcard>> getByDeck(String deckId) async {
    final db = await _helper.database;
    final maps = await db.query('flashcards',
        where: 'deck_id = ?', whereArgs: [deckId], orderBy: 'created_at ASC');
    return maps.map((m) => FlashcardModel.fromMap(m).toEntity()).toList();
  }

  Future<List<Flashcard>> getDueByDeck(String deckId, DateTime now) async {
    final db = await _helper.database;
    final maps = await db.query('flashcards',
        where: 'deck_id = ? AND due_date <= ?',
        whereArgs: [deckId, now.toIso8601String()],
        orderBy: 'due_date ASC');
    return maps.map((m) => FlashcardModel.fromMap(m).toEntity()).toList();
  }

  Future<List<Flashcard>> getAllDue(DateTime now) async {
    final db = await _helper.database;
    final maps = await db.query('flashcards',
        where: 'due_date <= ?',
        whereArgs: [now.toIso8601String()],
        orderBy: 'due_date ASC');
    return maps.map((m) => FlashcardModel.fromMap(m).toEntity()).toList();
  }

  Future<void> insert(Flashcard card) async {
    final db = await _helper.database;
    await db.insert('flashcards', FlashcardModel.fromEntity(card).toMap());
  }

  Future<void> insertAll(List<Flashcard> cards) async {
    final db = await _helper.database;
    final batch = db.batch();
    for (final card in cards) {
      batch.insert('flashcards', FlashcardModel.fromEntity(card).toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(Flashcard card) async {
    final db = await _helper.database;
    await db.update('flashcards', FlashcardModel.fromEntity(card).toMap(),
        where: 'id = ?', whereArgs: [card.id]);
  }

  Future<void> delete(String id) async {
    final db = await _helper.database;
    await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countByDeck(String deckId) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM flashcards WHERE deck_id = ?', [deckId]);
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> countDueByDeck(String deckId, DateTime now) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM flashcards WHERE deck_id = ? AND due_date <= ?',
        [deckId, now.toIso8601String()]);
    return (result.first['count'] as int?) ?? 0;
  }
}
```

```dart
// lib/data/datasources/local/review_dao.dart
import '../../../domain/entities/review_log.dart';
import '../../models/review_log_model.dart';
import 'database_helper.dart';

class ReviewDAO {
  final DatabaseHelper _helper;
  ReviewDAO(this._helper);

  Future<void> insert(ReviewLog log) async {
    final db = await _helper.database;
    await db.insert('review_logs', ReviewLogModel.fromEntity(log).toMap());
  }

  Future<List<ReviewLog>> getLogs({DateTime? from, DateTime? to}) async {
    final db = await _helper.database;
    String? where;
    List<dynamic>? whereArgs;

    if (from != null && to != null) {
      where = 'reviewed_at >= ? AND reviewed_at <= ?';
      whereArgs = [from.toIso8601String(), to.toIso8601String()];
    } else if (from != null) {
      where = 'reviewed_at >= ?';
      whereArgs = [from.toIso8601String()];
    }

    final maps = await db.query('review_logs',
        where: where, whereArgs: whereArgs, orderBy: 'reviewed_at DESC');
    return maps.map((m) => ReviewLogModel.fromMap(m).toEntity()).toList();
  }

  Future<List<ReviewLog>> getByDeck(String deckId) async {
    final db = await _helper.database;
    final maps = await db.query('review_logs',
        where: 'deck_id = ?', whereArgs: [deckId]);
    return maps.map((m) => ReviewLogModel.fromMap(m).toEntity()).toList();
  }

  Future<int> countToday() async {
    final db = await _helper.database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM review_logs WHERE reviewed_at >= ? AND reviewed_at <= ?',
        [start, end]);
    return (result.first['count'] as int?) ?? 0;
  }
}
```

```dart
// lib/data/datasources/local/user_dao.dart
import '../../../domain/entities/app_user.dart';
import '../../models/app_user_model.dart';
import 'database_helper.dart';

class UserDAO {
  final DatabaseHelper _helper;
  UserDAO(this._helper);

  Future<AppUser?> getUser() async {
    final db = await _helper.database;
    final maps = await db.query('users', limit: 1);
    if (maps.isEmpty) return null;
    return AppUserModel.fromMap(maps.first).toEntity();
  }

  Future<void> saveUser(AppUser user) async {
    final db = await _helper.database;
    await db.insert('users', AppUserModel.fromEntity(user).toMap());
  }

  Future<void> updateName(String name) async {
    final db = await _helper.database;
    await db.update('users', {'name': name});
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/data/
git commit -m "feat: add SQLite database schema, models and DAOs"
```

---

## Task 6: Data Layer — Implementações dos Repositórios

**Files:**
- Create: `lib/data/repositories/deck_repository_impl.dart`
- Create: `lib/data/repositories/flashcard_repository_impl.dart`
- Create: `lib/data/repositories/review_repository_impl.dart`
- Create: `lib/data/repositories/user_repository_impl.dart`

- [ ] **Step 1: Implementar repositórios concretos**

```dart
// lib/data/repositories/deck_repository_impl.dart
import '../../domain/entities/deck.dart';
import '../../domain/repositories/deck_repository.dart';
import '../datasources/local/deck_dao.dart';
import '../datasources/local/flashcard_dao.dart';

class DeckRepositoryImpl implements DeckRepository {
  final DeckDAO _deckDAO;
  final FlashcardDAO _cardDAO;

  DeckRepositoryImpl(this._deckDAO, this._cardDAO);

  @override
  Future<List<Deck>> getDecks() async {
    final decks = await _deckDAO.getAll();
    final now = DateTime.now();
    final enriched = <Deck>[];
    for (final deck in decks) {
      final total = await _cardDAO.countByDeck(deck.id);
      final due = await _cardDAO.countDueByDeck(deck.id, now);
      enriched.add(deck.copyWith(totalCards: total, dueCards: due));
    }
    return enriched;
  }

  @override
  Future<Deck?> getDeckById(String id) => _deckDAO.getById(id);

  @override
  Future<void> createDeck(Deck deck) => _deckDAO.insert(deck);

  @override
  Future<void> updateDeck(Deck deck) => _deckDAO.update(deck);

  @override
  Future<void> deleteDeck(String id) => _deckDAO.delete(id);
}
```

```dart
// lib/data/repositories/flashcard_repository_impl.dart
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../datasources/local/flashcard_dao.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final FlashcardDAO _dao;
  FlashcardRepositoryImpl(this._dao);

  @override
  Future<List<Flashcard>> getCardsByDeck(String deckId) => _dao.getByDeck(deckId);

  @override
  Future<List<Flashcard>> getDueCards(String deckId, DateTime now) =>
      _dao.getDueByDeck(deckId, now);

  @override
  Future<List<Flashcard>> getAllDueCards(DateTime now) => _dao.getAllDue(now);

  @override
  Future<void> addCard(Flashcard card) => _dao.insert(card);

  @override
  Future<void> addCards(List<Flashcard> cards) => _dao.insertAll(cards);

  @override
  Future<void> updateCard(Flashcard card) => _dao.update(card);

  @override
  Future<void> deleteCard(String id) => _dao.delete(id);

  @override
  Future<int> countCardsByDeck(String deckId) => _dao.countByDeck(deckId);

  @override
  Future<int> countDueCardsByDeck(String deckId, DateTime now) =>
      _dao.countDueByDeck(deckId, now);
}
```

```dart
// lib/data/repositories/review_repository_impl.dart
import '../../domain/entities/review_log.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/local/review_dao.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewDAO _dao;
  ReviewRepositoryImpl(this._dao);

  @override
  Future<void> saveReviewLog(ReviewLog log) => _dao.insert(log);

  @override
  Future<List<ReviewLog>> getReviewLogs({DateTime? from, DateTime? to}) =>
      _dao.getLogs(from: from, to: to);

  @override
  Future<List<ReviewLog>> getReviewLogsByDeck(String deckId) =>
      _dao.getByDeck(deckId);

  @override
  Future<int> countReviewsToday() => _dao.countToday();
}
```

```dart
// lib/data/repositories/user_repository_impl.dart
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_dao.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDAO _dao;
  UserRepositoryImpl(this._dao);

  @override
  Future<AppUser?> getUser() => _dao.getUser();

  @override
  Future<void> saveUser(AppUser user) => _dao.saveUser(user);

  @override
  Future<void> updateUserName(String name) => _dao.updateName(name);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/repositories/
git commit -m "feat: add concrete repository implementations"
```

---

## Task 7: OpenAI Client e Use Cases de IA

**Files:**
- Create: `lib/data/datasources/remote/openai_client.dart`
- Create: `lib/domain/usecases/ai/generate_cards_from_input.dart`

- [ ] **Step 1: Criar OpenAI Client**

```dart
// lib/data/datasources/remote/openai_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/openai_constants.dart';
import '../../../core/errors/failures.dart';

class GeneratedCard {
  final String front;
  final String back;
  const GeneratedCard({required this.front, required this.back});
}

class OpenAIClient {
  final http.Client _httpClient;
  OpenAIClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Future<List<GeneratedCard>> generateCards({
    required String apiKey,
    required String prompt,
    int maxCards = 20,
  }) async {
    final systemPrompt = '''
Você é um especialista em criação de flashcards para aprendizado de inglês.
Dado um texto ou tema, gere até $maxCards flashcards no formato JSON.
Cada flashcard deve ter:
- "front": frase em inglês (natural, do cotidiano)
- "back": tradução em português (natural, não literal)

Regras:
- Frases curtas e memoráveis (máximo 15 palavras)
- Traduções naturais em português brasileiro
- Variedade de estruturas gramaticais
- Foco em vocabulário e expressões úteis

Responda APENAS com um array JSON válido, sem markdown, sem explicações:
[{"front": "...", "back": "..."}, ...]
''';

    final body = jsonEncode({
      'model': OpenAIConstants.model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': OpenAIConstants.maxTokens,
      'temperature': OpenAIConstants.temperature,
    });

    final response = await _httpClient.post(
      Uri.parse(OpenAIConstants.chatEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode == 401) {
      throw const AIFailure('Chave de API inválida. Verifique nas configurações.');
    }
    if (response.statusCode == 429) {
      throw const AIFailure('Limite de requisições atingido. Tente novamente em instantes.');
    }
    if (response.statusCode != 200) {
      throw AIFailure('Erro da API OpenAI (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['choices'][0]['message']['content'] as String;

    try {
      final List<dynamic> cards = jsonDecode(content.trim());
      return cards
          .whereType<Map<String, dynamic>>()
          .map((c) => GeneratedCard(
                front: c['front'] as String,
                back: c['back'] as String,
              ))
          .toList();
    } catch (_) {
      throw const AIFailure('Não foi possível interpretar a resposta da IA.');
    }
  }
}
```

- [ ] **Step 2: Criar use case de geração de cards**

```dart
// lib/domain/usecases/ai/generate_cards_from_input.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../data/datasources/remote/openai_client.dart';
import '../../../data/datasources/local/flashcard_dao.dart';
import '../../entities/flashcard.dart';
import '../../repositories/flashcard_repository.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/sm2.dart';

enum AIInputType { text, pdfLineByLine, pdfAI, topic }

class GenerateCardsFromInput {
  final OpenAIClient _aiClient;
  final FlashcardRepository _cardRepository;
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;

  GenerateCardsFromInput({
    required OpenAIClient aiClient,
    required FlashcardRepository cardRepository,
    required FlutterSecureStorage secureStorage,
    Uuid? uuid,
  })  : _aiClient = aiClient,
        _cardRepository = cardRepository,
        _secureStorage = secureStorage,
        _uuid = uuid ?? const Uuid();

  Future<List<Flashcard>> execute({
    required String deckId,
    required String input,
    required AIInputType inputType,
    int maxCards = 20,
  }) async {
    final apiKey = await _secureStorage.read(key: AppConstants.apiKeyStorageKey);
    if (apiKey == null || apiKey.isEmpty) {
      throw const AIFailure(
          'Chave de API não configurada. Adicione sua chave nas configurações.');
    }

    String prompt;
    switch (inputType) {
      case AIInputType.topic:
        prompt = 'Gere $maxCards flashcards de inglês sobre o tema: "$input"';
      case AIInputType.text:
      case AIInputType.pdfAI:
        prompt =
            'Extraia e gere até $maxCards flashcards de inglês a partir deste texto:\n\n$input';
      case AIInputType.pdfLineByLine:
        // Para este modo, os pares já vêm prontos do PdfParser
        throw const ParseFailure(
            'pdfLineByLine deve ser processado antes de chamar este use case.');
    }

    final generated = await _aiClient.generateCards(
      apiKey: apiKey,
      prompt: prompt,
      maxCards: maxCards,
    );

    final now = DateTime.now();
    final cards = generated
        .map((g) => Flashcard(
              id: _uuid.v4(),
              deckId: deckId,
              front: g.front,
              back: g.back,
              createdAt: now,
              dueDate: now,
              easeFactor: SM2.initialEaseFactor,
            ))
        .toList();

    await _cardRepository.addCards(cards);
    return cards;
  }

  /// Para o modo PDF line-by-line: recebe pares prontos e salva diretamente
  Future<List<Flashcard>> fromParsedPairs({
    required String deckId,
    required List<({String front, String back})> pairs,
  }) async {
    final now = DateTime.now();
    final cards = pairs
        .map((p) => Flashcard(
              id: _uuid.v4(),
              deckId: deckId,
              front: p.front,
              back: p.back,
              createdAt: now,
              dueDate: now,
              easeFactor: SM2.initialEaseFactor,
            ))
        .toList();
    await _cardRepository.addCards(cards);
    return cards;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/datasources/remote/ lib/domain/usecases/ai/
git commit -m "feat: add OpenAI client and AI card generation use case"
```

---

## Task 8: Use Cases de Deck, Review e Stats

**Files:**
- Create: `lib/domain/usecases/deck/create_deck.dart`
- Create: `lib/domain/usecases/deck/get_decks.dart`
- Create: `lib/domain/usecases/deck/delete_deck.dart`
- Create: `lib/domain/usecases/deck/update_deck.dart`
- Create: `lib/domain/usecases/flashcard/get_due_cards.dart`
- Create: `lib/domain/usecases/flashcard/add_cards_to_deck.dart`
- Create: `lib/domain/usecases/flashcard/delete_card.dart`
- Create: `lib/domain/usecases/review/submit_review.dart`
- Create: `lib/domain/usecases/review/get_stats.dart`

- [ ] **Step 1: Use cases de deck**

```dart
// lib/domain/usecases/deck/get_decks.dart
import '../../entities/deck.dart';
import '../../repositories/deck_repository.dart';

class GetDecks {
  final DeckRepository _repository;
  GetDecks(this._repository);

  Future<List<Deck>> execute() => _repository.getDecks();
}
```

```dart
// lib/domain/usecases/deck/create_deck.dart
import 'package:uuid/uuid.dart';
import '../../entities/deck.dart';
import '../../repositories/deck_repository.dart';

class CreateDeck {
  final DeckRepository _repository;
  final Uuid _uuid;

  CreateDeck(this._repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<Deck> execute({required String name, String? description}) async {
    final deck = Deck(
      id: _uuid.v4(),
      name: name.trim(),
      description: description?.trim(),
      createdAt: DateTime.now(),
    );
    await _repository.createDeck(deck);
    return deck;
  }
}
```

```dart
// lib/domain/usecases/deck/update_deck.dart
import '../../entities/deck.dart';
import '../../repositories/deck_repository.dart';

class UpdateDeck {
  final DeckRepository _repository;
  UpdateDeck(this._repository);

  Future<void> execute(Deck deck) => _repository.updateDeck(deck);
}
```

```dart
// lib/domain/usecases/deck/delete_deck.dart
import '../../repositories/deck_repository.dart';

class DeleteDeck {
  final DeckRepository _repository;
  DeleteDeck(this._repository);

  Future<void> execute(String deckId) => _repository.deleteDeck(deckId);
}
```

- [ ] **Step 2: Use cases de flashcard**

```dart
// lib/domain/usecases/flashcard/get_due_cards.dart
import '../../entities/flashcard.dart';
import '../../repositories/flashcard_repository.dart';

class GetDueCards {
  final FlashcardRepository _repository;
  GetDueCards(this._repository);

  Future<List<Flashcard>> execute(String deckId) =>
      _repository.getDueCards(deckId, DateTime.now());

  Future<List<Flashcard>> executeAll() =>
      _repository.getAllDueCards(DateTime.now());
}
```

```dart
// lib/domain/usecases/flashcard/delete_card.dart
import '../../repositories/flashcard_repository.dart';

class DeleteCard {
  final FlashcardRepository _repository;
  DeleteCard(this._repository);

  Future<void> execute(String cardId) => _repository.deleteCard(cardId);
}
```

- [ ] **Step 3: Use case de revisão (aplica SM-2)**

```dart
// lib/domain/usecases/review/submit_review.dart
import 'package:uuid/uuid.dart';
import '../../../core/utils/sm2.dart';
import '../../entities/flashcard.dart';
import '../../entities/review_log.dart';
import '../../repositories/flashcard_repository.dart';
import '../../repositories/review_repository.dart';

class SubmitReview {
  final FlashcardRepository _cardRepository;
  final ReviewRepository _reviewRepository;
  final Uuid _uuid;

  SubmitReview({
    required FlashcardRepository cardRepository,
    required ReviewRepository reviewRepository,
    Uuid? uuid,
  })  : _cardRepository = cardRepository,
        _reviewRepository = reviewRepository,
        _uuid = uuid ?? const Uuid();

  Future<Flashcard> execute({
    required Flashcard card,
    required CardRating rating,
  }) async {
    final result = SM2.calculate(
      easeFactor: card.easeFactor,
      interval: card.interval,
      repetitions: card.repetitions,
      rating: rating,
    );

    final nextDue = SM2.nextDueDate(result.interval);
    final updatedCard = card.copyWith(
      easeFactor: result.easeFactor,
      interval: result.interval,
      repetitions: result.repetitions,
      dueDate: nextDue,
    );

    await _cardRepository.updateCard(updatedCard);

    final log = ReviewLog(
      id: _uuid.v4(),
      cardId: card.id,
      deckId: card.deckId,
      rating: rating.value,
      reviewedAt: DateTime.now(),
      intervalAfter: result.interval,
    );
    await _reviewRepository.saveReviewLog(log);

    return updatedCard;
  }
}
```

- [ ] **Step 4: Use case de estatísticas**

```dart
// lib/domain/usecases/review/get_stats.dart
import '../../repositories/review_repository.dart';

class DailyStats {
  final DateTime date;
  final int reviewCount;
  final int correctCount; // rating >= 3 (Good ou Easy)

  const DailyStats({
    required this.date,
    required this.reviewCount,
    required this.correctCount,
  });

  double get accuracy =>
      reviewCount == 0 ? 0 : correctCount / reviewCount;
}

class GetStats {
  final ReviewRepository _repository;
  GetStats(this._repository);

  Future<List<DailyStats>> getLast30Days() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - 29);
    final logs = await _repository.getReviewLogs(from: from, to: now);

    final Map<String, DailyStats> byDay = {};
    for (final log in logs) {
      final key =
          '${log.reviewedAt.year}-${log.reviewedAt.month}-${log.reviewedAt.day}';
      final existing = byDay[key];
      final isCorrect = log.rating >= 3;
      byDay[key] = DailyStats(
        date: DateTime(
            log.reviewedAt.year, log.reviewedAt.month, log.reviewedAt.day),
        reviewCount: (existing?.reviewCount ?? 0) + 1,
        correctCount: (existing?.correctCount ?? 0) + (isCorrect ? 1 : 0),
      );
    }

    return byDay.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<int> getTodayCount() => _repository.countReviewsToday();
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/usecases/
git commit -m "feat: add deck, flashcard, review and stats use cases"
```

---

## Task 9: Riverpod Providers (ViewModels)

**Files:**
- Create: `lib/presentation/providers/repository_providers.dart`
- Create: `lib/presentation/providers/user_provider.dart`
- Create: `lib/presentation/providers/deck_provider.dart`
- Create: `lib/presentation/providers/review_session_provider.dart`
- Create: `lib/presentation/providers/ai_generation_provider.dart`
- Create: `lib/presentation/providers/stats_provider.dart`

- [ ] **Step 1: Criar repository_providers.dart (injeção de dependências)**

```dart
// lib/presentation/providers/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/deck_dao.dart';
import '../../data/datasources/local/flashcard_dao.dart';
import '../../data/datasources/local/review_dao.dart';
import '../../data/datasources/local/user_dao.dart';
import '../../data/datasources/remote/openai_client.dart';
import '../../data/repositories/deck_repository_impl.dart';
import '../../data/repositories/flashcard_repository_impl.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/deck_repository.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/ai/generate_cards_from_input.dart';
import '../../domain/usecases/deck/create_deck.dart';
import '../../domain/usecases/deck/delete_deck.dart';
import '../../domain/usecases/deck/get_decks.dart';
import '../../domain/usecases/deck/update_deck.dart';
import '../../domain/usecases/flashcard/delete_card.dart';
import '../../domain/usecases/flashcard/get_due_cards.dart';
import '../../domain/usecases/review/get_stats.dart';
import '../../domain/usecases/review/submit_review.dart';

// Infrastructure
final dbHelperProvider = Provider<DatabaseHelper>((_) => DatabaseHelper.instance);

final secureStorageProvider = Provider<FlutterSecureStorage>(
    (_) => const FlutterSecureStorage());

// DAOs
final deckDaoProvider =
    Provider<DeckDAO>((ref) => DeckDAO(ref.read(dbHelperProvider)));
final flashcardDaoProvider =
    Provider<FlashcardDAO>((ref) => FlashcardDAO(ref.read(dbHelperProvider)));
final reviewDaoProvider =
    Provider<ReviewDAO>((ref) => ReviewDAO(ref.read(dbHelperProvider)));
final userDaoProvider =
    Provider<UserDAO>((ref) => UserDAO(ref.read(dbHelperProvider)));

// Repositories
final deckRepositoryProvider = Provider<DeckRepository>((ref) =>
    DeckRepositoryImpl(
        ref.read(deckDaoProvider), ref.read(flashcardDaoProvider)));

final flashcardRepositoryProvider = Provider<FlashcardRepository>(
    (ref) => FlashcardRepositoryImpl(ref.read(flashcardDaoProvider)));

final reviewRepositoryProvider = Provider<ReviewRepository>(
    (ref) => ReviewRepositoryImpl(ref.read(reviewDaoProvider)));

final userRepositoryProvider = Provider<UserRepository>(
    (ref) => UserRepositoryImpl(ref.read(userDaoProvider)));

// Remote
final openAIClientProvider =
    Provider<OpenAIClient>((_) => OpenAIClient());

// Use Cases
final getDecksUseCaseProvider =
    Provider<GetDecks>((ref) => GetDecks(ref.read(deckRepositoryProvider)));

final createDeckUseCaseProvider =
    Provider<CreateDeck>((ref) => CreateDeck(ref.read(deckRepositoryProvider)));

final updateDeckUseCaseProvider =
    Provider<UpdateDeck>((ref) => UpdateDeck(ref.read(deckRepositoryProvider)));

final deleteDeckUseCaseProvider =
    Provider<DeleteDeck>((ref) => DeleteDeck(ref.read(deckRepositoryProvider)));

final getDueCardsUseCaseProvider = Provider<GetDueCards>(
    (ref) => GetDueCards(ref.read(flashcardRepositoryProvider)));

final deleteCardUseCaseProvider = Provider<DeleteCard>(
    (ref) => DeleteCard(ref.read(flashcardRepositoryProvider)));

final submitReviewUseCaseProvider = Provider<SubmitReview>((ref) => SubmitReview(
      cardRepository: ref.read(flashcardRepositoryProvider),
      reviewRepository: ref.read(reviewRepositoryProvider),
    ));

final getStatsUseCaseProvider =
    Provider<GetStats>((ref) => GetStats(ref.read(reviewRepositoryProvider)));

final generateCardsUseCaseProvider =
    Provider<GenerateCardsFromInput>((ref) => GenerateCardsFromInput(
          aiClient: ref.read(openAIClientProvider),
          cardRepository: ref.read(flashcardRepositoryProvider),
          secureStorage: ref.read(secureStorageProvider),
        ));
```

- [ ] **Step 2: Criar user_provider.dart**

```dart
// lib/presentation/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';
import 'repository_providers.dart';

final userProvider = AsyncNotifierProvider<UserNotifier, AppUser?>(UserNotifier.new);

class UserNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final repo = ref.read(userRepositoryProvider);
    return repo.getUser();
  }

  Future<void> saveUser(AppUser user) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.saveUser(user);
    state = AsyncData(user);
  }

  Future<void> updateName(String name) async {
    final repo = ref.read(userRepositoryProvider);
    await repo.updateUserName(name);
    state = state.whenData((u) => u != null
        ? AppUser(id: u.id, name: name, createdAt: u.createdAt)
        : null);
  }
}
```

- [ ] **Step 3: Criar deck_provider.dart**

```dart
// lib/presentation/providers/deck_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/deck.dart';
import 'repository_providers.dart';

final deckProvider =
    AsyncNotifierProvider<DeckNotifier, List<Deck>>(DeckNotifier.new);

class DeckNotifier extends AsyncNotifier<List<Deck>> {
  @override
  Future<List<Deck>> build() async {
    return ref.read(getDecksUseCaseProvider).execute();
  }

  Future<void> createDeck({required String name, String? description}) async {
    await ref
        .read(createDeckUseCaseProvider)
        .execute(name: name, description: description);
    ref.invalidateSelf();
  }

  Future<void> updateDeck(Deck deck) async {
    await ref.read(updateDeckUseCaseProvider).execute(deck);
    ref.invalidateSelf();
  }

  Future<void> deleteDeck(String id) async {
    await ref.read(deleteDeckUseCaseProvider).execute(id);
    ref.invalidateSelf();
  }
}
```

- [ ] **Step 4: Criar review_session_provider.dart**

```dart
// lib/presentation/providers/review_session_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/sm2.dart';
import '../../domain/entities/flashcard.dart';
import 'repository_providers.dart';

class ReviewSessionState {
  final List<Flashcard> queue;
  final int currentIndex;
  final bool isFlipped;
  final bool isComplete;
  final int correct;
  final int total;

  const ReviewSessionState({
    required this.queue,
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isComplete = false,
    this.correct = 0,
    this.total = 0,
  });

  Flashcard? get currentCard =>
      currentIndex < queue.length ? queue[currentIndex] : null;

  ReviewSessionState copyWith({
    List<Flashcard>? queue,
    int? currentIndex,
    bool? isFlipped,
    bool? isComplete,
    int? correct,
    int? total,
  }) {
    return ReviewSessionState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isComplete: isComplete ?? this.isComplete,
      correct: correct ?? this.correct,
      total: total ?? this.total,
    );
  }
}

final reviewSessionProvider =
    StateNotifierProvider.family<ReviewSessionNotifier, ReviewSessionState, String>(
  (ref, deckId) => ReviewSessionNotifier(ref, deckId),
);

class ReviewSessionNotifier extends StateNotifier<ReviewSessionState> {
  final Ref _ref;
  final String _deckId;

  ReviewSessionNotifier(this._ref, this._deckId)
      : super(const ReviewSessionState(queue: [])) {
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards =
        await _ref.read(getDueCardsUseCaseProvider).execute(_deckId);
    state = ReviewSessionState(queue: cards, total: cards.length);
  }

  void flipCard() {
    state = state.copyWith(isFlipped: true);
  }

  Future<void> submitRating(CardRating rating) async {
    final card = state.currentCard;
    if (card == null) return;

    await _ref.read(submitReviewUseCaseProvider).execute(
          card: card,
          rating: rating,
        );

    final isCorrect = rating != CardRating.again;
    final nextIndex = state.currentIndex + 1;
    final isComplete = nextIndex >= state.queue.length;

    state = state.copyWith(
      currentIndex: nextIndex,
      isFlipped: false,
      isComplete: isComplete,
      correct: state.correct + (isCorrect ? 1 : 0),
    );

    if (isComplete) {
      _ref.invalidate(deckProvider);
    }
  }
}
```

- [ ] **Step 5: Criar ai_generation_provider.dart**

```dart
// lib/presentation/providers/ai_generation_provider.dart
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/pdf_parser.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/ai/generate_cards_from_input.dart';
import 'repository_providers.dart';

class AIGenerationState {
  final bool isLoading;
  final List<Flashcard> generatedCards;
  final String? error;

  const AIGenerationState({
    this.isLoading = false,
    this.generatedCards = const [],
    this.error,
  });
}

final aiGenerationProvider =
    StateNotifierProvider<AIGenerationNotifier, AIGenerationState>(
        (ref) => AIGenerationNotifier(ref));

class AIGenerationNotifier extends StateNotifier<AIGenerationState> {
  final Ref _ref;
  AIGenerationNotifier(this._ref) : super(const AIGenerationState());

  Future<void> generateFromTopic({
    required String deckId,
    required String topic,
    int maxCards = 20,
  }) async {
    state = const AIGenerationState(isLoading: true);
    try {
      final cards = await _ref.read(generateCardsUseCaseProvider).execute(
            deckId: deckId,
            input: topic,
            inputType: AIInputType.topic,
            maxCards: maxCards,
          );
      state = AIGenerationState(generatedCards: cards);
      _ref.invalidate(deckProvider);
    } catch (e) {
      state = AIGenerationState(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> generateFromText({
    required String deckId,
    required String text,
    int maxCards = 20,
  }) async {
    state = const AIGenerationState(isLoading: true);
    try {
      final cards = await _ref.read(generateCardsUseCaseProvider).execute(
            deckId: deckId,
            input: text,
            inputType: AIInputType.text,
            maxCards: maxCards,
          );
      state = AIGenerationState(generatedCards: cards);
      _ref.invalidate(deckProvider);
    } catch (e) {
      state = AIGenerationState(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> generateFromPdf({
    required String deckId,
    required Uint8List pdfBytes,
    required PdfParseMode parseMode,
    int maxCards = 20,
  }) async {
    state = const AIGenerationState(isLoading: true);
    try {
      final rawText = PdfParser.extractRawText(pdfBytes);
      final useCase = _ref.read(generateCardsUseCaseProvider);
      List<Flashcard> cards;

      if (parseMode == PdfParseMode.lineByLine) {
        final pairs = PdfParser.parseLineByLine(rawText);
        cards = await useCase.fromParsedPairs(
          deckId: deckId,
          pairs: pairs
              .map((p) => (front: p.front, back: p.back))
              .toList(),
        );
      } else {
        final text = PdfParser.prepareTextForAI(rawText);
        cards = await useCase.execute(
          deckId: deckId,
          input: text,
          inputType: AIInputType.pdfAI,
          maxCards: maxCards,
        );
      }

      state = AIGenerationState(generatedCards: cards);
      _ref.invalidate(deckProvider);
    } catch (e) {
      state = AIGenerationState(error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void reset() => state = const AIGenerationState();
}
```

- [ ] **Step 6: Criar stats_provider.dart**

```dart
// lib/presentation/providers/stats_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/review/get_stats.dart';
import 'repository_providers.dart';

final statsProvider = FutureProvider<List<DailyStats>>((ref) async {
  return ref.read(getStatsUseCaseProvider).getLast30Days();
});

final todayReviewCountProvider = FutureProvider<int>((ref) async {
  return ref.read(getStatsUseCaseProvider).getTodayCount();
});
```

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/providers/
git commit -m "feat: add Riverpod providers and ViewModels"
```

---

## Task 10: Tela de Onboarding

**Files:**
- Create: `lib/presentation/screens/onboarding/onboarding_screen.dart`

- [ ] **Step 1: Criar OnboardingScreen**

```dart
// lib/presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/app_user.dart';
import '../../providers/user_provider.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = AppUser(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(userProvider.notifier).saveUser(user);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_rounded, size: 64, color: colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'Bem-vindo ao\nAnaApp',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Flashcards inteligentes para aprender inglês.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Como você quer ser chamado?',
                    hintText: 'Seu nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, informe seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Começar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/onboarding/
git commit -m "feat: add onboarding screen"
```

---

## Task 11: Shell de Navegação e Home Screen

**Files:**
- Create: `lib/presentation/screens/home/home_screen.dart`
- Create: `lib/presentation/widgets/empty_state_widget.dart`
- Create: `lib/presentation/widgets/deck_card_widget.dart`
- Create: `lib/presentation/screens/decks/decks_screen.dart`

- [ ] **Step 1: Criar widgets reutilizáveis**

```dart
// lib/presentation/widgets/empty_state_widget.dart
import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/presentation/widgets/deck_card_widget.dart
import 'package:flutter/material.dart';
import '../../domain/entities/deck.dart';

class DeckCardWidget extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const DeckCardWidget({
    super.key,
    required this.deck,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.style_rounded,
                    color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (deck.description != null)
                      Text(deck.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(
                          label: '${deck.totalCards} cards',
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        if (deck.dueCards > 0)
                          _Chip(
                            label: '${deck.dueCards} para revisar',
                            color: colorScheme.errorContainer,
                            textColor: colorScheme.onErrorContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: colorScheme.error,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Chip(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
    );
  }
}
```

- [ ] **Step 2: Criar HomeScreen com NavigationBar**

```dart
// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../decks/decks_screen.dart';
import '../review/review_screen.dart';
import '../stats/stats_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/user_provider.dart';
import '../../providers/stats_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    _DashboardTab(),
    DecksScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Início'),
          NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style),
              label: 'Baralhos'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Estatísticas'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Configurações'),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final todayCount = ref.watch(todayReviewCountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: user.when(
          data: (u) => Text('Olá, ${u?.name ?? ''}!'),
          loading: () => const Text('AnaApp'),
          error: (_, __) => const Text('AnaApp'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 40,
                        color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayCount.when(
                            data: (c) => '$c revisões hoje',
                            loading: () => '...',
                            error: (_, __) => '0 revisões hoje',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Continue assim!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Criar DecksScreen**

```dart
// lib/presentation/screens/decks/decks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/deck_provider.dart';
import '../../widgets/deck_card_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../review/review_screen.dart';
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
```

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/screens/ lib/presentation/widgets/
git commit -m "feat: add home screen, navigation and decks screen"
```

---

## Task 12: Deck Detail e Review Session

**Files:**
- Create: `lib/presentation/screens/decks/deck_detail_screen.dart`
- Create: `lib/presentation/widgets/flashcard_flip_widget.dart`
- Create: `lib/presentation/widgets/rating_buttons_widget.dart`
- Create: `lib/presentation/screens/review/review_screen.dart`

- [ ] **Step 1: Criar FlashcardFlipWidget**

```dart
// lib/presentation/widgets/flashcard_flip_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';

class FlashcardFlipWidget extends StatefulWidget {
  final String front;
  final String back;
  final bool isFlipped;
  final VoidCallback onTap;

  const FlashcardFlipWidget({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  State<FlashcardFlipWidget> createState() => _FlashcardFlipWidgetState();
}

class _FlashcardFlipWidgetState extends State<FlashcardFlipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _animation = Tween<double>(begin: 0, end: pi).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(FlashcardFlipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped && !oldWidget.isFlipped) {
      _controller.forward();
    } else if (!widget.isFlipped && oldWidget.isFlipped) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isShowingBack = _animation.value > pi / 2;
          return Transform(
            transform: Matrix4.rotationY(_animation.value),
            alignment: Alignment.center,
            child: isShowingBack
                ? Transform(
                    transform: Matrix4.rotationY(pi),
                    alignment: Alignment.center,
                    child: _CardFace(
                      text: widget.back,
                      label: 'TRADUÇÃO',
                      isBack: true,
                    ),
                  )
                : _CardFace(
                    text: widget.front,
                    label: 'INGLÊS',
                    isBack: false,
                  ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String label;
  final bool isBack;

  const _CardFace(
      {required this.text, required this.label, required this.isBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: isBack ? colorScheme.secondaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isBack
                ? colorScheme.secondary.withOpacity(0.3)
                : colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isBack
                  ? colorScheme.onSecondaryContainer.withOpacity(0.6)
                  : colorScheme.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isBack
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurface,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isBack) ...[
            const SizedBox(height: 16),
            Text(
              'Toque para ver a tradução',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Criar RatingButtonsWidget**

```dart
// lib/presentation/widgets/rating_buttons_widget.dart
import 'package:flutter/material.dart';
import '../../../core/utils/sm2.dart';

class RatingButtonsWidget extends StatelessWidget {
  final void Function(CardRating) onRate;

  const RatingButtonsWidget({super.key, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RatingButton(
          label: 'Errei',
          sublabel: '< 1 dia',
          color: Theme.of(context).colorScheme.error,
          onTap: () => onRate(CardRating.again),
        ),
        _RatingButton(
          label: 'Difícil',
          sublabel: '~2 dias',
          color: Colors.orange,
          onTap: () => onRate(CardRating.hard),
        ),
        _RatingButton(
          label: 'Bom',
          sublabel: '~4 dias',
          color: Colors.green,
          onTap: () => onRate(CardRating.good),
        ),
        _RatingButton(
          label: 'Fácil',
          sublabel: '~7 dias',
          color: Colors.blue,
          onTap: () => onRate(CardRating.easy),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(sublabel,
                style: TextStyle(
                    color: color.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Criar ReviewScreen**

```dart
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
```

- [ ] **Step 4: Criar DeckDetailScreen**

```dart
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
    final cardsAsync = FutureProvider.autoDispose<List<Flashcard>>((ref) =>
        ref.read(flashcardRepositoryProvider).getCardsByDeck(deck.id));

    return Consumer(builder: (context, ref, _) {
      final cards = ref.watch(cardsAsync);

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
        body: cards.when(
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
    });
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/ lib/presentation/widgets/
git commit -m "feat: add review session, card flip animation and deck detail"
```

---

## Task 13: Tela de Geração por IA

**Files:**
- Create: `lib/presentation/screens/ai_generate/ai_generate_screen.dart`
- Create: `lib/presentation/widgets/api_key_info_banner.dart`

- [ ] **Step 1: Criar banner de API key**

```dart
// lib/presentation/widgets/api_key_info_banner.dart
import 'package:flutter/material.dart';
import '../screens/settings/settings_screen.dart';

class ApiKeyInfoBanner extends StatelessWidget {
  const ApiKeyInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.key_rounded,
              color: theme.colorScheme.onTertiaryContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'A IA usa sua chave de API OpenAI pessoal. '
              'Ela é armazenada apenas neste dispositivo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Criar AIGenerateScreen**

```dart
// lib/presentation/screens/ai_generate/ai_generate_screen.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/pdf_parser.dart';
import '../../../domain/entities/deck.dart';
import '../../providers/ai_generation_provider.dart';
import '../../widgets/api_key_info_banner.dart';

class AIGenerateScreen extends ConsumerStatefulWidget {
  final Deck deck;
  const AIGenerateScreen({super.key, required this.deck});

  @override
  ConsumerState<AIGenerateScreen> createState() => _AIGenerateScreenState();
}

class _AIGenerateScreenState extends ConsumerState<AIGenerateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _topicController = TextEditingController();
  final _textController = TextEditingController();
  Uint8List? _pdfBytes;
  String? _pdfName;
  PdfParseMode _parseMode = PdfParseMode.lineByLine;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiGenerationProvider);
    final notifier = ref.read(aiGenerationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gerar cards — ${widget.deck.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Tema'),
            Tab(icon: Icon(Icons.text_fields), text: 'Texto'),
            Tab(icon: Icon(Icons.picture_as_pdf_outlined), text: 'PDF'),
          ],
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: ApiKeyInfoBanner(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TopicTab(controller: _topicController),
                _TextTab(controller: _textController),
                _PdfTab(
                  pdfName: _pdfName,
                  parseMode: _parseMode,
                  onPickPdf: _pickPdf,
                  onModeChanged: (m) => setState(() => _parseMode = m),
                ),
              ],
            ),
          ),
          if (aiState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiState.error!,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (aiState.generatedCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${aiState.generatedCards.length} cards gerados e adicionados ao baralho!',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: aiState.isLoading ? null : () => _generate(notifier),
                icon: aiState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label:
                    Text(aiState.isLoading ? 'Gerando...' : 'Gerar cards'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _pdfBytes = result.files.first.bytes;
        _pdfName = result.files.first.name;
      });
    }
  }

  Future<void> _generate(AIGenerationNotifier notifier) async {
    final tab = _tabController.index;
    notifier.reset();

    switch (tab) {
      case 0:
        if (_topicController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Digite um tema')));
          return;
        }
        await notifier.generateFromTopic(
          deckId: widget.deck.id,
          topic: _topicController.text,
        );
      case 1:
        if (_textController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cole um texto')));
          return;
        }
        await notifier.generateFromText(
          deckId: widget.deck.id,
          text: _textController.text,
        );
      case 2:
        if (_pdfBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selecione um PDF')));
          return;
        }
        await notifier.generateFromPdf(
          deckId: widget.deck.id,
          pdfBytes: _pdfBytes!,
          parseMode: _parseMode,
        );
    }
  }
}

class _TopicTab extends StatelessWidget {
  final TextEditingController controller;
  const _TopicTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sugira um tema e a IA gerará os cards automaticamente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Tema',
              hintText: 'Ex: viagem ao exterior, entrevista de emprego...',
              prefixIcon: Icon(Icons.lightbulb_outline),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}

class _TextTab extends StatelessWidget {
  final TextEditingController controller;
  const _TextTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cole um texto em inglês e a IA extrairá frases para os cards.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                labelText: 'Texto',
                hintText: 'Cole o texto aqui...',
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfTab extends StatelessWidget {
  final String? pdfName;
  final PdfParseMode parseMode;
  final VoidCallback onPickPdf;
  final void Function(PdfParseMode) onModeChanged;

  const _PdfTab({
    required this.pdfName,
    required this.parseMode,
    required this.onPickPdf,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Modo de leitura do PDF:',
              style: theme.textTheme.labelLarge),
          RadioListTile<PdfParseMode>(
            value: PdfParseMode.lineByLine,
            groupValue: parseMode,
            onChanged: (v) => onModeChanged(v!),
            title: const Text('Linha a linha'),
            subtitle: const Text(
                'Linha ímpar = inglês, linha par = tradução\n(ideal para materiais do seu curso)'),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<PdfParseMode>(
            value: PdfParseMode.aiInterpreted,
            groupValue: parseMode,
            onChanged: (v) => onModeChanged(v!),
            title: const Text('IA interpreta'),
            subtitle: const Text('A IA analisa o texto e cria os cards'),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPickPdf,
            icon: const Icon(Icons.upload_file),
            label: Text(pdfName ?? 'Selecionar PDF'),
          ),
          if (pdfName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(pdfName!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/ai_generate/ lib/presentation/widgets/api_key_info_banner.dart
git commit -m "feat: add AI generation screen with topic, text and PDF modes"
```

---

## Task 14: Estatísticas e Configurações

**Files:**
- Create: `lib/presentation/screens/stats/stats_screen.dart`
- Create: `lib/presentation/screens/settings/settings_screen.dart`

- [ ] **Step 1: Criar StatsScreen**

```dart
// lib/presentation/screens/stats/stats_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stats_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final todayAsync = ref.watch(todayReviewCountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (stats) {
          final totalReviews =
              stats.fold<int>(0, (sum, s) => sum + s.reviewCount);
          final avgAccuracy = stats.isEmpty
              ? 0.0
              : stats.fold<double>(0, (sum, s) => sum + s.accuracy) /
                  stats.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Hoje',
                      value: todayAsync.when(
                          data: (c) => '$c',
                          loading: () => '...',
                          error: (_, __) => '0'),
                      icon: Icons.today_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Total (30d)',
                      value: '$totalReviews',
                      icon: Icons.layers_rounded,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Precisão',
                      value: '${(avgAccuracy * 100).round()}%',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Revisões nos últimos 30 dias',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              if (stats.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nenhuma revisão ainda'),
                ))
              else
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: stats
                              .map((s) => s.reviewCount)
                              .fold(0, (a, b) => a > b ? a : b)
                              .toDouble() *
                          1.2,
                      barGroups: stats.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.reviewCount.toDouble(),
                              color: theme.colorScheme.primary,
                              width: 6,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (val, _) => Text(
                              '${val.toInt()}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Criar SettingsScreen**

```dart
// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/repository_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _apiKeySaved = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final storage = ref.read(secureStorageProvider);
    final key = await storage.read(key: AppConstants.apiKeyStorageKey);
    if (key != null && mounted) {
      _apiKeyController.text = key;
      setState(() => _apiKeySaved = true);
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: AppConstants.apiKeyStorageKey, value: key);
    if (mounted) {
      setState(() => _apiKeySaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chave de API salva!')));
    }
  }

  Future<void> _clearApiKey() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: AppConstants.apiKeyStorageKey);
    _apiKeyController.clear();
    if (mounted) setState(() => _apiKeySaved = false);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Usuário
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Perfil', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  user.when(
                    data: (u) => Row(
                      children: [
                        CircleAvatar(
                          child: Text(u?.name.substring(0, 1).toUpperCase() ?? '?'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(u?.name ?? 'Usuário',
                              style: theme.textTheme.bodyLarge),
                        ),
                        TextButton(
                          onPressed: () => _showRenameDialog(context),
                          child: const Text('Editar'),
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Erro ao carregar usuário'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // API Key
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.key_rounded,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Chave de API OpenAI',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(width: 8),
                      if (_apiKeySaved)
                        Icon(Icons.check_circle,
                            size: 16, color: theme.colorScheme.primary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Como obter sua chave:',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1. Acesse platform.openai.com\n'
                          '2. Vá em "API Keys" → "Create new secret key"\n'
                          '3. Copie e cole abaixo\n\n'
                          'Sua chave é salva apenas neste dispositivo.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _apiKeyObscured,
                    decoration: InputDecoration(
                      labelText: 'sk-...',
                      hintText: 'Cole sua chave aqui',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_apiKeyObscured
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _apiKeyObscured = !_apiKeyObscured),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _saveApiKey,
                          child: const Text('Salvar chave'),
                        ),
                      ),
                      if (_apiKeySaved) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _clearApiKey,
                          child: const Text('Remover'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller =
        TextEditingController(text: ref.read(userProvider).value?.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nome'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(userProvider.notifier)
                    .updateName(controller.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/stats/ lib/presentation/screens/settings/
git commit -m "feat: add statistics screen and settings screen with API key management"
```

---

## Task 15: Import/Export

**Files:**
- Create: `lib/domain/usecases/export_import.dart`
- Modify: `lib/presentation/screens/settings/settings_screen.dart`

- [ ] **Step 1: Criar use case de export/import**

```dart
// lib/domain/usecases/export_import.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../entities/deck.dart';
import '../entities/flashcard.dart';
import '../repositories/deck_repository.dart';
import '../repositories/flashcard_repository.dart';
import '../../core/utils/sm2.dart';

class ExportImport {
  final DeckRepository _deckRepo;
  final FlashcardRepository _cardRepo;
  final Uuid _uuid;

  ExportImport({
    required DeckRepository deckRepo,
    required FlashcardRepository cardRepo,
    Uuid? uuid,
  })  : _deckRepo = deckRepo,
        _cardRepo = cardRepo,
        _uuid = uuid ?? const Uuid();

  Future<void> exportAll() async {
    final decks = await _deckRepo.getDecks();
    final List<Map<String, dynamic>> deckData = [];

    for (final deck in decks) {
      final cards = await _cardRepo.getCardsByDeck(deck.id);
      deckData.add({
        'id': deck.id,
        'name': deck.name,
        'description': deck.description,
        'createdAt': deck.createdAt.toIso8601String(),
        'cards': cards
            .map((c) => {
                  'id': c.id,
                  'front': c.front,
                  'back': c.back,
                  'createdAt': c.createdAt.toIso8601String(),
                  'easeFactor': c.easeFactor,
                  'interval': c.interval,
                  'repetitions': c.repetitions,
                  'dueDate': c.dueDate.toIso8601String(),
                })
            .toList(),
      });
    }

    final json = jsonEncode({'version': 1, 'decks': deckData});
    final bytes = Uint8List.fromList(utf8.encode(json));
    final now = DateTime.now();
    final fileName =
        'anaapp_backup_${now.year}${now.month}${now.day}.anaapp.json';

    if (kIsWeb) {
      // Web: trigger download
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: 'AnaApp Backup');
  }

  Future<int> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.first.bytes == null) return 0;

    final content = utf8.decode(result.files.first.bytes!);
    final data = jsonDecode(content) as Map<String, dynamic>;

    if (data['version'] != 1 || data['decks'] == null) {
      throw const FormatException('Arquivo de backup inválido.');
    }

    int imported = 0;
    final now = DateTime.now();

    for (final deckData in data['decks'] as List) {
      final deck = Deck(
        id: _uuid.v4(),
        name: deckData['name'] as String,
        description: deckData['description'] as String?,
        createdAt:
            DateTime.tryParse(deckData['createdAt'] as String? ?? '') ?? now,
      );
      await _deckRepo.createDeck(deck);

      final cardsList = (deckData['cards'] as List?) ?? [];
      final cards = cardsList.map<Flashcard>((c) {
        return Flashcard(
          id: _uuid.v4(),
          deckId: deck.id,
          front: c['front'] as String,
          back: c['back'] as String,
          createdAt:
              DateTime.tryParse(c['createdAt'] as String? ?? '') ?? now,
          easeFactor:
              (c['easeFactor'] as num?)?.toDouble() ?? SM2.initialEaseFactor,
          interval: (c['interval'] as int?) ?? 0,
          repetitions: (c['repetitions'] as int?) ?? 0,
          dueDate: DateTime.tryParse(c['dueDate'] as String? ?? '') ?? now,
        );
      }).toList();

      await _cardRepo.addCards(cards);
      imported += cards.length;
    }

    return imported;
  }
}
```

> **Nota:** Adicione `share_plus: ^10.0.0` e `path_provider: ^2.1.3` ao `pubspec.yaml` e rode `flutter pub get`.

- [ ] **Step 2: Adicionar provider para ExportImport**

Em `lib/presentation/providers/repository_providers.dart`, adicione no final:

```dart
import '../../domain/usecases/export_import.dart';

final exportImportProvider = Provider<ExportImport>((ref) => ExportImport(
      deckRepo: ref.read(deckRepositoryProvider),
      cardRepo: ref.read(flashcardRepositoryProvider),
    ));
```

- [ ] **Step 3: Adicionar botões de Export/Import na SettingsScreen**

Em `lib/presentation/screens/settings/settings_screen.dart`, adicione após o Card da API key:

```dart
const SizedBox(height: 12),
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dados', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.upload_rounded),
          title: const Text('Exportar backup'),
          subtitle: const Text('Salva todos os baralhos e cards'),
          onTap: () async {
            try {
              await ref.read(exportImportProvider).exportAll();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao exportar: $e')));
              }
            }
          },
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.download_rounded),
          title: const Text('Importar backup'),
          subtitle: const Text('Restaura baralhos de um arquivo .anaapp.json'),
          onTap: () async {
            try {
              final count = await ref.read(exportImportProvider).importFromFile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count cards importados!')));
                ref.invalidate(deckProvider);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao importar: $e')));
              }
            }
          },
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 4: Adicionar dependências**

Em `pubspec.yaml`, adicione:

```yaml
  share_plus: ^10.0.0
  path_provider: ^2.1.3
```

Rode:

```bash
flutter pub get
```

- [ ] **Step 5: Commit**

```bash
git add lib/domain/usecases/export_import.dart lib/presentation/ pubspec.yaml pubspec.lock
git commit -m "feat: add export/import backup functionality"
```

---

## Task 16: Verificação final e build

- [ ] **Step 1: Corrigir imports pendentes em app.dart**

`lib/app.dart` referencia `userProvider` e as telas. Verifique que todos os imports estão corretos:

```dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';
```

- [ ] **Step 2: Corrigir import de deckProvider em deck_detail_screen.dart**

Em `lib/presentation/screens/decks/deck_detail_screen.dart`, adicione:

```dart
import '../../providers/deck_provider.dart';
```

- [ ] **Step 3: Rodar analyze**

```bash
flutter analyze
```

Corrija quaisquer erros reportados antes de prosseguir.

- [ ] **Step 4: Build de verificação**

```bash
flutter build apk --debug
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 5: Commit final**

```bash
git add -A
git commit -m "chore: final import fixes and build verification"
```

---

## Sumário das Dependências Finais (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  sqflite: ^2.3.3+1
  path: ^1.9.0
  flutter_secure_storage: ^9.2.2
  http: ^1.2.1
  syncfusion_flutter_pdf: ^26.2.14
  file_picker: ^8.1.2
  dynamic_color: ^1.7.0
  fl_chart: ^0.68.0
  intl: ^0.19.0
  shared_preferences: ^2.3.2
  uuid: ^4.4.2
  share_plus: ^10.0.0
  path_provider: ^2.1.3
```
