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
