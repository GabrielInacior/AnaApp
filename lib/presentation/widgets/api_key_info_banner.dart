// lib/presentation/widgets/api_key_info_banner.dart
import 'package:flutter/material.dart';

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
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Acesse a aba Configurações para gerenciar sua chave API.')),
              );
            },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }
}
