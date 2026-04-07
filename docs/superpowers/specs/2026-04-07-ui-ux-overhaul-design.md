# AnaApp UI/UX Overhaul Design Spec

## Problem

The app's UI is "feio" (ugly) per user feedback. It fails the core requirement of being visually superior to AnkiDroid. Specific issues: bare-minimum home screen, no manual card creation, no deck favorites/colors, no theme toggle, hardcoded colors, crash risks, and overall lack of polish.

## Goals

1. Premium Material Design 3 aesthetic with rich typography and motion
2. Feature parity gaps filled: manual cards, favorites, colors, theme toggle
3. All hardcoded styles replaced with theme-derived values
4. Bug fixes for crashes and layout issues

## Design Decisions

### 1. Deck Entity Extensions

Add to `Deck`:
- `isFavorite` (bool, default false) — toggle favorite status
- `colorIndex` (int, default 0) — index into a predefined palette of 12 colors (0 = default/theme primary)

DB migration: bump version to 2, ALTER TABLE to add columns. Palette of 12 colors defined in `app_colors.dart`.

### 2. Theme System

- Add `ThemeModeNotifier` (StateNotifier) persisted to SharedPreferences
- Settings screen gets a 3-option segmented button: System / Light / Dark
- `app.dart` reads `themeModeProvider` to set `themeMode`
- Enhance `AppTheme` with custom `TextTheme` (Google Fonts is not required — use default M3 typography with weight customization)
- Add `NavigationBarThemeData`, `BottomSheetThemeData`, `DialogTheme` to theme
- Card elevation: 1 for light, 2 for dark (subtle depth)

### 3. Home Screen Redesign

Replace the single-card dashboard with a rich scrollable page:
- **Header section**: Greeting with avatar + motivational subtitle (dynamic based on time of day)
- **Quick Actions row**: "Revisar pendentes" + "Criar baralho" + "Gerar com IA" (3 action chips/cards)
- **Due Today summary card**: Total due across all decks, with breakdown per deck (top 3)
- **Recent Decks section**: Horizontal scrollable list of deck mini-cards (last 5 edited/created)
- **Streak / Stats card**: Today's reviews count + simple streak indicator (days consecutive)

### 4. Manual Card Creation

In `DeckDetailScreen`:
- Add a second FAB option or a "+" icon in the app bar to create cards manually
- Opens a bottom sheet with Front (English) + Back (Portuguese) text fields
- Validates non-empty, creates Flashcard with default SM-2 values and dueDate = now

### 5. Card List Improvements (Deck Detail)

- Add `Divider` between cards in the list
- Add swipe-to-delete on cards (Dismissible)
- Add edit functionality (tap card → bottom sheet with pre-filled text)
- Show card count and due count in a header above the list
- Empty state suggests both manual and AI creation

### 6. Deck Favorites & Color Coding

- DeckCardWidget shows a star icon (filled if favorite, outlined if not)
- Long press or menu to set deck color from palette
- DecksScreen sorts: favorites first, then by createdAt DESC
- Color indicator: left border accent stripe on the deck card (4px wide, rounded)

### 7. Bug Fixes

- Settings: Guard `substring(0,1)` on empty name
- Stats: Guard `maxY` against 0 (use `max(maxY, 1)`)
- Rating buttons: Use theme colors instead of `Colors.orange/green/blue`
- Delete button: Use `error` color scheme
- Flashcard flip: Use theme shadow color instead of `Colors.black`
- Stats accuracy: Use `theme.colorScheme.tertiary` instead of `Colors.green`
- API key banner: navigate to settings tab (index 3) instead of pushing duplicate screen
- Onboarding: Wrap in SingleChildScrollView for keyboard overflow
- Deck chip: Use `theme.textTheme.labelSmall` instead of hardcoded fontSize: 11

### 8. File Changes Summary

**Modified files** (no new files needed):
- `lib/domain/entities/deck.dart` — add isFavorite, colorIndex
- `lib/data/models/deck_model.dart` — add fields to fromMap/toMap/toEntity/fromEntity
- `lib/data/datasources/local/database_helper.dart` — version 2 migration
- `lib/data/datasources/local/deck_dao.dart` — update ordering
- `lib/core/theme/app_colors.dart` — add deckColors palette
- `lib/core/theme/app_theme.dart` — enhanced theme with TextTheme + component themes
- `lib/app.dart` — integrate themeModeProvider
- `lib/presentation/providers/theme_provider.dart` — **NEW** ThemeModeNotifier
- `lib/presentation/providers/deck_provider.dart` — add toggleFavorite, updateColor
- `lib/presentation/screens/home/home_screen.dart` — complete redesign
- `lib/presentation/screens/decks/decks_screen.dart` — sorting + color in create sheet
- `lib/presentation/screens/decks/deck_detail_screen.dart` — manual creation + dividers + edit/delete
- `lib/presentation/screens/settings/settings_screen.dart` — theme toggle + bug fixes
- `lib/presentation/screens/stats/stats_screen.dart` — theme color fixes
- `lib/presentation/screens/review/review_screen.dart` — completion screen AppBar
- `lib/presentation/screens/onboarding/onboarding_screen.dart` — SingleChildScrollView
- `lib/presentation/widgets/deck_card_widget.dart` — favorite star + color stripe
- `lib/presentation/widgets/rating_buttons_widget.dart` — theme colors
- `lib/presentation/widgets/flashcard_flip_widget.dart` — theme shadow
- `lib/presentation/widgets/api_key_info_banner.dart` — fix navigation
- `lib/domain/usecases/export_import.dart` — include isFavorite/colorIndex in export
