// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/deck.dart';
import '../../../domain/usecases/review/get_stats.dart';
import '../../providers/deck_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/page_transitions.dart';
import '../ai_generate/ai_generate_screen.dart';
import '../decks/deck_detail_screen.dart';
import '../decks/decks_screen.dart';
import '../review/review_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  void _goToTab(int index) {
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(onNavigateToTab: _goToTab),
      const DecksScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    // Determine slide direction based on tab navigation
    final goingRight = _selectedIndex > _previousIndex;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          // Slide + fade
          final isIncoming =
              child.key == ValueKey(_selectedIndex);
          final slideBegin = isIncoming
              ? Offset(goingRight ? 0.06 : -0.06, 0)
              : Offset(goingRight ? -0.06 : 0.06, 0);

          return SlideTransition(
            position: Tween<Offset>(
              begin: slideBegin,
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() {
            _previousIndex = _selectedIndex;
            _selectedIndex = i;
          });
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Baralhos'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Estatisticas'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Ajustes'),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerStatefulWidget {
  final void Function(int) onNavigateToTab;

  const _DashboardTab({required this.onNavigateToTab});

  @override
  ConsumerState<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<_DashboardTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final List<Animation<double>> _opacities;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 5 sections: header, quick actions, due today, recent decks, stats preview
    _opacities = List.generate(5, (i) {
      final start = (i * 0.12).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _slides = List.generate(5, (i) {
      final start = (i * 0.12).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String _subtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Vamos aprender algo novo hoje?';
    if (hour < 18) return 'Continue brilhando nos estudos!';
    return 'Que tal uma revisao rapida?';
  }

  Widget _wrapSection(int index, Widget child) {
    return FadeTransition(
      opacity: _opacities[index],
      child: SlideTransition(
        position: _slides[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final todayCount = ref.watch(todayReviewCountProvider);
    final decks = ref.watch(deckProvider);
    final stats = ref.watch(statsProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userName = user.whenOrNull(data: (u) => u?.name) ?? '';
    final deckList = decks.whenOrNull(data: (d) => d) ?? <Deck>[];
    final statsList = stats.whenOrNull(data: (s) => s) ?? <DailyStats>[];

    final totalDue = deckList.fold<int>(0, (sum, d) => sum + d.dueCards);
    final decksWithDue = deckList.where((d) => d.dueCards > 0).toList()
      ..sort((a, b) => b.dueCards.compareTo(a.dueCards));

    final recentDecks = List<Deck>.of(deckList)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayRecent = recentDecks.take(5).toList();

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final last7 =
        statsList.where((s) => s.date.isAfter(sevenDaysAgo)).toList();
    final totalReviews7d =
        last7.fold<int>(0, (sum, s) => sum + s.reviewCount);
    final totalCorrect7d =
        last7.fold<int>(0, (sum, s) => sum + s.correctCount);
    final avgAccuracy =
        totalReviews7d == 0 ? 0.0 : totalCorrect7d / totalReviews7d;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER
              _wrapSection(0,
                _buildHeader(theme, colorScheme, userName)),
              const SizedBox(height: 28),

              // 2. QUICK ACTIONS
              _wrapSection(1,
                _buildQuickActions(
                  context, theme, colorScheme, deckList, decksWithDue)),
              const SizedBox(height: 24),

              // 3. DUE TODAY
              _wrapSection(2,
                _buildDueTodayCard(
                  context, theme, colorScheme, totalDue, decksWithDue, todayCount)),
              const SizedBox(height: 24),

              // 4. RECENT DECKS
              if (displayRecent.isNotEmpty)
                _wrapSection(3,
                  _buildRecentDecks(
                    context, theme, colorScheme, displayRecent)),
              if (displayRecent.isNotEmpty) const SizedBox(height: 24),

              // 5. STATS PREVIEW
              _wrapSection(4,
                _buildStatsPreview(
                  theme, colorScheme, totalReviews7d, avgAccuracy)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme, ColorScheme colorScheme, String userName,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}${userName.isNotEmpty ? ', $userName' : ''}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/AnaAppLogo.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<Deck> deckList,
    List<Deck> decksWithDue,
  ) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.play_circle_rounded,
            label: 'Revisar',
            gradient: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
            iconColor: colorScheme.onPrimaryContainer,
            labelColor: colorScheme.onPrimaryContainer,
            onTap: () {
              if (decksWithDue.isNotEmpty) {
                final deck = decksWithDue.first;
                Navigator.of(context).push(
                  SlideUpRoute(
                    page: ReviewScreen(
                      deckId: deck.id, deckName: deck.name),
                  ),
                ).then((_) {
                  ref.invalidate(deckProvider);
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nenhum cartao para revisar hoje!')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.add_circle_rounded,
            label: 'Criar',
            gradient: [
              colorScheme.secondaryContainer,
              colorScheme.secondaryContainer.withValues(alpha: 0.7),
            ],
            iconColor: colorScheme.onSecondaryContainer,
            labelColor: colorScheme.onSecondaryContainer,
            onTap: () => widget.onNavigateToTab(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.auto_awesome_rounded,
            label: 'IA',
            gradient: [
              colorScheme.tertiaryContainer,
              colorScheme.tertiaryContainer.withValues(alpha: 0.7),
            ],
            iconColor: colorScheme.onTertiaryContainer,
            labelColor: colorScheme.onTertiaryContainer,
            onTap: () {
              if (deckList.isNotEmpty) {
                Navigator.of(context).push(
                  FadeScaleRoute(
                    page: AIGenerateScreen(deck: deckList.first)),
                );
              } else {
                widget.onNavigateToTab(1);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDueTodayCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    int totalDue,
    List<Deck> decksWithDue,
    AsyncValue<int> todayCount,
  ) {
    final top3 = decksWithDue.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: totalDue == 0
          ? _buildAllDoneContent(theme, colorScheme)
          : _buildDueContent(context, theme, colorScheme, totalDue, top3),
    );
  }

  Widget _buildAllDoneContent(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.check_circle_rounded,
            size: 32,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Tudo em dia!',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Nenhum cartao pendente. Voce esta arrasando!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDueContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    int totalDue,
    List<Deck> top3,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$totalDue',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    totalDue == 1
                        ? 'cartao para revisar'
                        : 'cartoes para revisar',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Vamos manter o ritmo!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (top3.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...top3.map(
            (deck) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    SlideUpRoute(
                      page: DeckDetailScreen(deck: deck)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.getDeckColor(
                              deck.colorValue, brightness: theme.brightness),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          deck.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${deck.dueCards}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentDecks(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<Deck> displayRecent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Baralhos recentes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateToTab(1),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayRecent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final deck = displayRecent[index];
              return _RecentDeckMiniCard(
                deck: deck,
                colorScheme: colorScheme,
                theme: theme,
                onTap: () {
                  Navigator.of(context).push(
                    SlideUpRoute(
                      page: DeckDetailScreen(deck: deck)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPreview(
    ThemeData theme,
    ColorScheme colorScheme,
    int totalReviews7d,
    double avgAccuracy,
  ) {
    final accuracyPct = (avgAccuracy * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: 20,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Ultimos 7 dias',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalReviews7d',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalReviews7d == 1
                          ? 'revisao realizada'
                          : 'revisoes realizadas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$accuracyPct%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'precisao media',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.iconColor,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDeckMiniCard extends StatelessWidget {
  final Deck deck;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  const _RecentDeckMiniCard({
    required this.deck,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.getDeckColor(
        deck.colorValue, brightness: theme.brightness);

    return SizedBox(
      width: 155,
      child: Material(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  deck.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  '${deck.totalCards} ${deck.totalCards == 1 ? 'card' : 'cards'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
