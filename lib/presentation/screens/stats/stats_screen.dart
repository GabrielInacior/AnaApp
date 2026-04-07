// lib/presentation/screens/stats/stats_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/stats_provider.dart';
import '../../../domain/usecases/review/get_stats.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  // Section 1 — Header
  late final Animation<double> _s1Opacity;
  late final Animation<Offset> _s1Slide;
  // Section 2 — Overview Cards
  late final Animation<double> _s2Opacity;
  late final Animation<Offset> _s2Slide;
  // Section 3 — Activity Chart
  late final Animation<double> _s3Opacity;
  late final Animation<Offset> _s3Slide;
  // Section 4 — Mastery Pie
  late final Animation<double> _s4Opacity;
  late final Animation<Offset> _s4Slide;
  // Section 5 — Rating Breakdown
  late final Animation<double> _s5Opacity;
  late final Animation<Offset> _s5Slide;
  // Section 6 — Week Forecast
  late final Animation<double> _s6Opacity;
  late final Animation<Offset> _s6Slide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _s1Opacity = _buildOpacity(0.0, 0.2);
    _s1Slide = _buildSlide(0.0, 0.2);

    _s2Opacity = _buildOpacity(0.1, 0.3);
    _s2Slide = _buildSlide(0.1, 0.3);

    _s3Opacity = _buildOpacity(0.2, 0.5);
    _s3Slide = _buildSlide(0.2, 0.5);

    _s4Opacity = _buildOpacity(0.35, 0.6);
    _s4Slide = _buildSlide(0.35, 0.6);

    _s5Opacity = _buildOpacity(0.5, 0.75);
    _s5Slide = _buildSlide(0.5, 0.75);

    _s6Opacity = _buildOpacity(0.65, 1.0);
    _s6Slide = _buildSlide(0.65, 1.0);

    _animController.forward();
  }

  Animation<double> _buildOpacity(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Animation<Offset> _buildSlide(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(fullStatsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerLow,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFFCE4EC),
                    Color(0xFFF3E5F5),
                    Color(0xFFEDE7F6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.3, 1.0],
                ),
        ),
        child: SafeArea(
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (stats) => _buildContent(context, stats),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FullStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // ── Section 1: Header ──
        _animatedSection(
          opacity: _s1Opacity,
          slide: _s1Slide,
          child: _buildHeader(theme, colorScheme),
        ),
        const SizedBox(height: 24),

        // ── Section 2: Overview Cards ──
        _animatedSection(
          opacity: _s2Opacity,
          slide: _s2Slide,
          child: _buildOverviewCards(context, stats),
        ),
        const SizedBox(height: 24),

        // ── Section 3: Activity Chart ──
        _animatedSection(
          opacity: _s3Opacity,
          slide: _s3Slide,
          child: _buildActivityChart(context, stats),
        ),
        const SizedBox(height: 24),

        // ── Section 4: Mastery Distribution ──
        _animatedSection(
          opacity: _s4Opacity,
          slide: _s4Slide,
          child: _buildMasterySection(context, stats),
        ),
        const SizedBox(height: 24),

        // ── Section 5: Rating Breakdown ──
        _animatedSection(
          opacity: _s5Opacity,
          slide: _s5Slide,
          child: _buildRatingSection(context, stats),
        ),
        const SizedBox(height: 24),

        // ── Section 6: Week Forecast ──
        _animatedSection(
          opacity: _s6Opacity,
          slide: _s6Slide,
          child: _buildForecastSection(context, stats),
        ),
      ],
    );
  }

  Widget _animatedSection({
    required Animation<double> opacity,
    required Animation<Offset> slide,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }

  // ============================================================
  // Section 1 — Header
  // ============================================================
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Acompanhe seu progresso de estudo',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Section 2 — Overview Cards (2x2 Grid)
  // ============================================================
  Widget _buildOverviewCards(BuildContext context, FullStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        // Hoje
        _OverviewCard(
          label: 'Hoje',
          value: '${stats.todayCount}',
          icon: Icons.today_rounded,
          gradientColors: isDark
              ? [colorScheme.surfaceContainerHigh, colorScheme.surfaceContainerHigh]
              : const [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
          iconColor: isDark ? colorScheme.primary : const Color(0xFFAD1457),
        ),
        // Sequência
        _OverviewCard(
          label: 'Sequência',
          value: '${stats.streakDays} dias',
          icon: Icons.local_fire_department_rounded,
          gradientColors: isDark
              ? [colorScheme.surfaceContainerHigh, colorScheme.surfaceContainerHigh]
              : const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          iconColor: isDark ? colorScheme.tertiary : const Color(0xFFE65100),
        ),
        // Total (30d)
        _OverviewCard(
          label: 'Total (30d)',
          value: '${stats.total30dReviews}',
          icon: Icons.layers_rounded,
          gradientColors: isDark
              ? [colorScheme.surfaceContainerHigh, colorScheme.surfaceContainerHigh]
              : const [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
          iconColor: isDark ? colorScheme.secondary : const Color(0xFF5E35B1),
        ),
        // Precisão
        _OverviewCard(
          label: 'Precisão',
          value: '${(stats.accuracy30d * 100).round()}%',
          icon: Icons.check_circle_outline_rounded,
          gradientColors: isDark
              ? [colorScheme.surfaceContainerHigh, colorScheme.surfaceContainerHigh]
              : const [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          iconColor: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
        ),
      ],
    );
  }

  // ============================================================
  // Section 3 — Activity Chart (30-day bar chart)
  // ============================================================
  Widget _buildActivityChart(BuildContext context, FullStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dailyStats = stats.dailyStats;

    final maxY = dailyStats.isEmpty
        ? 5.0
        : (dailyStats.map((s) => s.reviewCount).fold(0, (a, b) => a > b ? a : b).toDouble() * 1.2)
            .clamp(1.0, double.infinity);

    return _sectionContainer(
      isDark: isDark,
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context: context,
            icon: Icons.bar_chart_rounded,
            title: 'Atividade nos últimos 30 dias',
          ),
          const SizedBox(height: 20),
          if (dailyStats.isEmpty)
            _emptyChartMessage(context, 'Nenhum dado de atividade')
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barGroups: dailyStats.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.reviewCount.toDouble(),
                          gradient: isDark
                              ? LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.5),
                                    colorScheme.primary,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFF8BBD0),
                                    Color(0xFFD4A0B9),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                          width: dailyStats.length > 15 ? 6 : 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= dailyStats.length) {
                            return const SizedBox.shrink();
                          }
                          // Show label every 7th day
                          if (idx % 7 != 0 && idx != dailyStats.length - 1) {
                            return const SizedBox.shrink();
                          }
                          final date = dailyStats[idx].date;
                          final label = DateFormat('dd/MM').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Section 4 — Mastery Distribution (Pie Chart)
  // ============================================================
  Widget _buildMasterySection(BuildContext context, FullStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mastery = stats.mastery;
    final total = mastery.total;

    final sliceData = <_PieSliceData>[
      _PieSliceData(
        label: 'Novos',
        value: mastery.newCards,
        color: isDark ? const Color(0xFFE91E63) : const Color(0xFFF8BBD0),
      ),
      _PieSliceData(
        label: 'Aprendendo',
        value: mastery.learning,
        color: isDark ? const Color(0xFFFF7043) : const Color(0xFFFFCCBC),
      ),
      _PieSliceData(
        label: 'Jovens',
        value: mastery.young,
        color: isDark ? const Color(0xFF9575CD) : const Color(0xFFD1C4E9),
      ),
      _PieSliceData(
        label: 'Maduros',
        value: mastery.mature,
        color: isDark ? const Color(0xFF66BB6A) : const Color(0xFFC8E6C9),
      ),
    ];

    return _sectionContainer(
      isDark: isDark,
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context: context,
            icon: Icons.school_rounded,
            title: 'Distribuição de Domínio',
          ),
          const SizedBox(height: 20),
          if (total == 0)
            _emptyChartMessage(context, 'Nenhum card adicionado')
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sliceData.where((s) => s.value > 0).map((s) {
                    return PieChartSectionData(
                      value: s.value.toDouble(),
                      color: s.color,
                      radius: 45,
                      title: '',
                      showTitle: false,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Center total text
            Center(
              child: Text(
                '$total cards',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: sliceData.map((s) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.label} (${s.value})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Section 5 — Rating Breakdown
  // ============================================================
  Widget _buildRatingSection(BuildContext context, FullStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final rd = stats.ratingBreakdown;
    final total = rd.total;

    final items = <_RatingBarData>[
      _RatingBarData(label: 'Não lembro', value: rd.again, color: const Color(0xFFE57373)),
      _RatingBarData(label: 'Difícil', value: rd.hard, color: const Color(0xFFFFB74D)),
      _RatingBarData(label: 'Bom', value: rd.good, color: const Color(0xFFBA68C8)),
      _RatingBarData(label: 'Fácil', value: rd.easy, color: const Color(0xFF81C784)),
    ];

    return _sectionContainer(
      isDark: isDark,
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context: context,
            icon: Icons.assessment_rounded,
            title: 'Desempenho por Avaliação',
          ),
          const SizedBox(height: 20),
          if (total == 0)
            _emptyChartMessage(context, 'Nenhuma revisão realizada')
          else
            ...items.map((item) {
              final pct = total == 0 ? 0.0 : item.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        item.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 10,
                          backgroundColor: isDark
                              ? colorScheme.surfaceContainerHighest
                              : colorScheme.outlineVariant.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(item.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${(pct * 100).round()}%',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ============================================================
  // Section 6 — Week Forecast
  // ============================================================
  Widget _buildForecastSection(BuildContext context, FullStats stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final forecast = stats.weekForecast;

    const ptDayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    final maxY = forecast.isEmpty
        ? 5.0
        : (forecast.map((f) => f.dueCount).fold(0, (a, b) => a > b ? a : b).toDouble() * 1.2)
            .clamp(1.0, double.infinity);

    return _sectionContainer(
      isDark: isDark,
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context: context,
            icon: Icons.calendar_month_rounded,
            title: 'Previsão da Semana',
          ),
          const SizedBox(height: 20),
          if (forecast.isEmpty)
            _emptyChartMessage(context, 'Nenhum dado de previsão')
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barGroups: forecast.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.dueCount.toDouble(),
                          gradient: isDark
                              ? LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.4),
                                    colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFE1BEE7),
                                    Color(0xFFCE93D8),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= forecast.length) {
                            return const SizedBox.shrink();
                          }
                          // weekday: 1=Mon ... 7=Sun
                          final dayOfWeek = forecast[idx].date.weekday;
                          final label = ptDayNames[dayOfWeek - 1];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Shared helpers
  // ============================================================

  /// Section container with card-like styling.
  Widget _sectionContainer({
    required bool isDark,
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  /// Section header with gradient pill icon + title.
  Widget _sectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: isDark
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                  ),
            color: isDark
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? colorScheme.primary : const Color(0xFF5E35B1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Empty state message for chart sections.
  Widget _emptyChartMessage(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.insights_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// Overview Card widget
// ==============================================================================
class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? colorScheme.surfaceContainerHigh : null,
        borderRadius: BorderRadius.circular(22),
        border: isDark
            ? null
            : Border.all(
                color: gradientColors.last.withValues(alpha: 0.4),
              ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? iconColor.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? colorScheme.onSurface : iconColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? colorScheme.onSurfaceVariant
                  : iconColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// Data classes for internal use
// ==============================================================================
class _PieSliceData {
  final String label;
  final int value;
  final Color color;
  const _PieSliceData({required this.label, required this.value, required this.color});
}

class _RatingBarData {
  final String label;
  final int value;
  final Color color;
  const _RatingBarData({required this.label, required this.value, required this.color});
}
