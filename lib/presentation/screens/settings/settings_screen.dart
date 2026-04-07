// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/deck_provider.dart';

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

          const SizedBox(height: 12),

          // Dados
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
