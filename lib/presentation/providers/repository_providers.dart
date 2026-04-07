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
