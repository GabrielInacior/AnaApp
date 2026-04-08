// lib/presentation/providers/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/deck_dao.dart';
import '../../data/datasources/local/deck_config_dao.dart';
import '../../data/datasources/local/flashcard_dao.dart';
import '../../data/datasources/local/review_dao.dart';
import '../../data/datasources/local/tag_dao.dart';
import '../../data/datasources/local/user_dao.dart';
import '../../data/datasources/remote/openai_client.dart';
import '../../data/repositories/deck_repository_impl.dart';
import '../../data/repositories/flashcard_repository_impl.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/deck_config.dart';
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
import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/export_import.dart';

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
final deckConfigDaoProvider =
    Provider<DeckConfigDAO>((ref) => DeckConfigDAO(ref.read(dbHelperProvider)));
final tagDaoProvider =
    Provider<TagDAO>((ref) => TagDAO(ref.read(dbHelperProvider)));

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
    Provider<GetStats>((ref) => GetStats(ref.read(reviewRepositoryProvider), ref.read(flashcardRepositoryProvider)));

final generateCardsUseCaseProvider =
    Provider<GenerateCardsFromInput>((ref) => GenerateCardsFromInput(
          aiClient: ref.read(openAIClientProvider),
          cardRepository: ref.read(flashcardRepositoryProvider),
          secureStorage: ref.read(secureStorageProvider),
        ));

final exportImportProvider = Provider<ExportImport>((ref) => ExportImport(
      deckRepo: ref.read(deckRepositoryProvider),
      cardRepo: ref.read(flashcardRepositoryProvider),
    ));

// Card list by deck (public, so AI generation provider can invalidate it)
final cardsByDeckProvider = FutureProvider.autoDispose
    .family<List<Flashcard>, String>((ref, deckId) {
  return ref.read(flashcardRepositoryProvider).getCardsByDeck(deckId);
});

// Deck configuration (for SM-2 scheduling)
final deckConfigProvider =
    FutureProvider.family<DeckConfig, String>((ref, deckId) {
  return ref.read(deckConfigDaoProvider).getConfig(deckId);
});

// All available tags (predefined + custom, DB-backed)
final allTagsProvider = StateNotifierProvider<AllTagsNotifier, List<String>>(
    (ref) => AllTagsNotifier(ref.read(tagDaoProvider)));

class AllTagsNotifier extends StateNotifier<List<String>> {
  final TagDAO _tagDao;
  final Map<String, int> _tagColors = {};
  bool _seeded = false;

  AllTagsNotifier(this._tagDao) : super([...AppColors.predefinedTags]) {
    _init();
  }

  Map<String, int> get tagColors => Map.unmodifiable(_tagColors);

  Future<void> _init() async {
    if (!_seeded) {
      await _tagDao.seedPredefinedTags();
      _seeded = true;
    }
    await _reload();
  }

  Future<void> _reload() async {
    final records = await _tagDao.getAllTags();
    final names = <String>[];
    _tagColors.clear();
    for (final r in records) {
      names.add(r.name);
      _tagColors[r.name] = r.colorValue;
    }
    state = names;
  }

  Future<void> addTag(String tag, {int? colorValue}) async {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) return;
    final color = colorValue ?? 0xFF90A4AE;
    await _tagDao.insertTag(trimmed, color);
    await _reload();
  }

  Future<int> countCardsWithTag(String tag) async {
    return _tagDao.countCardsWithTag(tag);
  }

  Future<void> deleteTag(String tag, {bool clearFromCards = false}) async {
    if (clearFromCards) {
      await _tagDao.clearTagFromCards(tag);
    }
    await _tagDao.deleteTag(tag);
    await _reload();
  }

  int? getTagColor(String tag) => _tagColors[tag];
}
