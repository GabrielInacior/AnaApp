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
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
        created_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        color_value INTEGER,
        tags TEXT
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
        front_image_path TEXT,
        back_image_path TEXT,
        queue INTEGER NOT NULL DEFAULT 0,
        card_type INTEGER NOT NULL DEFAULT 0,
        lapses INTEGER NOT NULL DEFAULT 0,
        remaining_steps INTEGER NOT NULL DEFAULT 0,
        pending_image INTEGER NOT NULL DEFAULT 0,
        tag TEXT,
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
    await db.execute('CREATE INDEX idx_cards_queue ON flashcards(queue)');
    await db.execute('CREATE INDEX idx_cards_type ON flashcards(card_type)');
    await db.execute('CREATE INDEX idx_logs_date ON review_logs(reviewed_at)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        name TEXT PRIMARY KEY,
        color_value INTEGER NOT NULL,
        is_predefined INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS deck_config (
        deck_id TEXT PRIMARY KEY,
        new_cards_per_day INTEGER NOT NULL DEFAULT 20,
        reviews_per_day INTEGER NOT NULL DEFAULT 200,
        learning_steps TEXT NOT NULL DEFAULT '1,10',
        graduating_interval INTEGER NOT NULL DEFAULT 1,
        easy_interval INTEGER NOT NULL DEFAULT 4,
        relearning_steps TEXT NOT NULL DEFAULT '10',
        lapse_threshold INTEGER NOT NULL DEFAULT 8,
        max_interval INTEGER NOT NULL DEFAULT 36500,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE decks ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE decks ADD COLUMN color_value INTEGER');
    }
    if (oldVersion < 3) {
      // Card images
      await db.execute('ALTER TABLE flashcards ADD COLUMN front_image_path TEXT');
      await db.execute('ALTER TABLE flashcards ADD COLUMN back_image_path TEXT');

      // Deck tags
      await db.execute('ALTER TABLE decks ADD COLUMN tags TEXT');

      // SM-2 upgrade: card states
      await db.execute('ALTER TABLE flashcards ADD COLUMN queue INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE flashcards ADD COLUMN card_type INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE flashcards ADD COLUMN lapses INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE flashcards ADD COLUMN remaining_steps INTEGER NOT NULL DEFAULT 0');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_queue ON flashcards(queue)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cards_type ON flashcards(card_type)');

      // Deck configuration table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS deck_config (
          deck_id TEXT PRIMARY KEY,
          new_cards_per_day INTEGER NOT NULL DEFAULT 20,
          reviews_per_day INTEGER NOT NULL DEFAULT 200,
          learning_steps TEXT NOT NULL DEFAULT '1,10',
          graduating_interval INTEGER NOT NULL DEFAULT 1,
          easy_interval INTEGER NOT NULL DEFAULT 4,
          relearning_steps TEXT NOT NULL DEFAULT '10',
          lapse_threshold INTEGER NOT NULL DEFAULT 8,
          max_interval INTEGER NOT NULL DEFAULT 36500,
          FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
        )
      ''');

      // Migrate existing reviewed cards to review queue
      await db.execute('''
        UPDATE flashcards SET queue = 2, card_type = 2
        WHERE repetitions > 0 AND interval_days > 0
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE flashcards ADD COLUMN pending_image INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE flashcards ADD COLUMN tag TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tags (
          name TEXT PRIMARY KEY,
          color_value INTEGER NOT NULL,
          is_predefined INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }
}
