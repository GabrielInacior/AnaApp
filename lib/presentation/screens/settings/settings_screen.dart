// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/deck_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _apiKeySaved = false;

  late final AnimationController _animController;
  late final List<Animation<double>> _sectionOpacities;
  late final List<Animation<Offset>> _sectionSlides;

  @override
  void initState() {
    super.initState();
    _loadApiKey();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 5 sections: header, theme, api key, data, about
    _sectionOpacities = List.generate(5, (i) {
      final start = (i * 0.12).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _sectionSlides = List.generate(5, (i) {
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

  Future<void> _loadApiKey() async {
    final storage = ref.read(secureStorageProvider);
    final key = await storage.read(key: AppConstants.apiKeyStorageKey);
    if (key != null && mounted) {
      _apiKeyController.text = key;
      setState(() => _apiKeySaved = true);
    }
  }

  bool _isValidating = false;

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isValidating = true);

    // Test the API key with a minimal request
    final isValid = await _testApiKey(key);

    if (!mounted) return;
    setState(() => _isValidating = false);

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Chave de API invalida. Verifique e tente novamente.')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final storage = ref.read(secureStorageProvider);
    await storage.write(key: AppConstants.apiKeyStorageKey, value: key);
    if (mounted) {
      setState(() => _apiKeySaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Chave de API valida e salva!'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Test API key by calling the models endpoint
  Future<bool> _testApiKey(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
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
    _animController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Gradient Header with Avatar ──
          FadeTransition(
            opacity: _sectionOpacities[0],
            child: SlideTransition(
              position: _sectionSlides[0],
              child: _buildGradientHeader(theme, colorScheme, isDark, user),
            ),
          ),

          // ── Settings Sections ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                // ── Tema ──
                FadeTransition(
                  opacity: _sectionOpacities[1],
                  child: SlideTransition(
                    position: _sectionSlides[1],
                    child: _SettingsSectionContainer(
                      isDark: isDark,
                      icon: Icons.palette_rounded,
                      iconGradientColors: const [
                        Color(0xFFEDE7F6),
                        Color(0xFFD1C4E9),
                      ],
                      iconColor: const Color(0xFF5E35B1),
                      title: 'Aparencia',
                      child: _buildThemeToggle(
                          themeMode, theme, colorScheme, isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── API Key ──
                FadeTransition(
                  opacity: _sectionOpacities[2],
                  child: SlideTransition(
                    position: _sectionSlides[2],
                    child: _SettingsSectionContainer(
                      isDark: isDark,
                      icon: Icons.key_rounded,
                      iconGradientColors: const [
                        Color(0xFFFFF8E1),
                        Color(0xFFFFECB3),
                      ],
                      iconColor: const Color(0xFFF57F17),
                      title: 'Chave de API OpenAI',
                      trailing: _apiKeySaved
                          ? _buildSavedBadge(theme)
                          : null,
                      child:
                          _buildApiKeyContent(theme, colorScheme, isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Dados ──
                FadeTransition(
                  opacity: _sectionOpacities[3],
                  child: SlideTransition(
                    position: _sectionSlides[3],
                    child: _SettingsSectionContainer(
                      isDark: isDark,
                      icon: Icons.folder_rounded,
                      iconGradientColors: const [
                        Color(0xFFE8F5E9),
                        Color(0xFFC8E6C9),
                      ],
                      iconColor: const Color(0xFF2E7D32),
                      title: 'Dados',
                      child: _buildDataContent(theme, colorScheme),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Sobre ──
                FadeTransition(
                  opacity: _sectionOpacities[4],
                  child: SlideTransition(
                    position: _sectionSlides[4],
                    child: _SettingsSectionContainer(
                      isDark: isDark,
                      icon: Icons.info_outline_rounded,
                      iconGradientColors: const [
                        Color(0xFFE3F2FD),
                        Color(0xFFBBDEFB),
                      ],
                      iconColor: const Color(0xFF1565C0),
                      title: 'Sobre',
                      child: _buildAboutContent(theme, colorScheme),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Gradient Header
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGradientHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    AsyncValue<dynamic> user,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF3D2040),
                  Color(0xFF2D2040),
                  Color(0xFF252050),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFFFCE4EC),
                  Color(0xFFF3E5F5),
                  Color(0xFFEDE7F6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
          child: Column(
            children: [
              // Title row
              Row(
                children: [
                  Text(
                    'Ajustes',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.tertiaryContainer,
                          ],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFD4A0B9), Color(0xFFB39DDB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFFD4A0B9)
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: user.when(
                    data: (u) => Text(
                      u?.name.isNotEmpty == true
                          ? u!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                    error: (_, __) => const Icon(Icons.person_rounded,
                        color: Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // User name
              user.when(
                data: (u) => Text(
                  u?.name ?? 'Usuario',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => Text(
                  'Usuario',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              // Edit profile button
              TextButton.icon(
                onPressed: () => _showRenameDialog(context),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar perfil'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Saved Badge
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSavedBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 14, color: Colors.green[700]),
          const SizedBox(width: 4),
          Text('Salva',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Theme Toggle
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildThemeToggle(
    ThemeMode themeMode,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildThemeOption(
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
            icon: Icons.auto_awesome_rounded,
            label: 'Auto',
            isSelected: themeMode == ThemeMode.system,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(ThemeMode.system),
          ),
          const SizedBox(width: 4),
          _buildThemeOption(
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
            icon: Icons.wb_sunny_rounded,
            label: 'Claro',
            isSelected: themeMode == ThemeMode.light,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(ThemeMode.light),
          ),
          const SizedBox(width: 4),
          _buildThemeOption(
            theme: theme,
            colorScheme: colorScheme,
            isDark: isDark,
            icon: Icons.nightlight_round,
            label: 'Escuro',
            isSelected: themeMode == ThemeMode.dark,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected && !isDark
                ? const LinearGradient(
                    colors: [Color(0xFFFCE4EC), Color(0xFFF3E5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color:
                isSelected && isDark ? colorScheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color:
                          colorScheme.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // API Key Content
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildApiKeyContent(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info box with gradient background
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isDark
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFF8E1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isDark ? colorScheme.surfaceContainerHighest : null,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? null
                : Border.all(
                    color:
                        const Color(0xFFFFE0B2).withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFB74D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lightbulb_outline_rounded,
                    size: 16, color: Colors.orange[800]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como obter sua chave:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? colorScheme.onSurface
                            : const Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. Acesse platform.openai.com\n'
                      '2. Va em "API Keys" "Create new secret key"\n'
                      '3. Copie e cole abaixo\n\n'
                      'Sua chave e salva apenas neste dispositivo.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? colorScheme.onSurfaceVariant
                            : const Color(0xFF795548),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Text field
        TextField(
          controller: _apiKeyController,
          obscureText: _apiKeyObscured,
          decoration: InputDecoration(
            labelText: 'sk-...',
            hintText: 'Cole sua chave aqui',
            prefixIcon: const Icon(Icons.vpn_key_outlined),
            suffixIcon: IconButton(
              icon: Icon(_apiKeyObscured
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded),
              onPressed: () =>
                  setState(() => _apiKeyObscured = !_apiKeyObscured),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isValidating ? null : _saveApiKey,
                icon: _isValidating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isValidating ? 'Validando...' : 'Salvar chave'),
              ),
            ),
            if (_apiKeySaved) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _confirmClearApiKey(context),
                child: const Text('Remover'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Data Section
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDataContent(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildDataTile(
          theme: theme,
          colorScheme: colorScheme,
          icon: Icons.upload_rounded,
          title: 'Exportar backup',
          subtitle: 'Salva todos os baralhos e cards',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(exportImportProvider).exportAll();
            } catch (e) {
              messenger.showSnackBar(
                  SnackBar(content: Text('Erro ao exportar: $e')));
            }
          },
        ),
        Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            height: 20),
        _buildDataTile(
          theme: theme,
          colorScheme: colorScheme,
          icon: Icons.download_rounded,
          title: 'Importar backup',
          subtitle: 'Restaura baralhos de um arquivo .anaapp.json',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              final count =
                  await ref.read(exportImportProvider).importFromFile();
              messenger.showSnackBar(SnackBar(
                  content: Text('$count cards importados!')));
              ref.invalidate(deckProvider);
            } catch (e) {
              messenger.showSnackBar(
                  SnackBar(content: Text('Erro ao importar: $e')));
            }
          },
        ),
      ],
    );
  }

  Widget _buildDataTile({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(icon, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // About Section
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAboutContent(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'v1.0.0',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'AnaApp',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Flashcards inteligentes com IA para aprendizado de idiomas.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dialogs (all logic preserved)
  // ═══════════════════════════════════════════════════════════════════════════
  void _confirmClearApiKey(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover chave de API'),
        content: const Text(
            'Tem certeza que deseja remover sua chave de API? '
            'A geracao de flashcards por IA deixara de funcionar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              _clearApiKey();
            },
            child: const Text('Remover'),
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

// ==========================================================================
// Section Container with gradient icon background
// ==========================================================================
class _SettingsSectionContainer extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final List<Color> iconGradientColors;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SettingsSectionContainer({
    required this.isDark,
    required this.icon,
    required this.iconGradientColors,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? null
            : Border.all(
                color:
                    colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gradient icon background
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? null
                      : LinearGradient(
                          colors: iconGradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: isDark
                      ? colorScheme.primaryContainer
                          .withValues(alpha: 0.3)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: 18,
                    color: isDark ? colorScheme.primary : iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
