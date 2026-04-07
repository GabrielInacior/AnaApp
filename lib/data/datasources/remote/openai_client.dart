// lib/data/datasources/remote/openai_client.dart
import 'dart:convert';
import 'dart:typed_data';
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
    required String topic,
    int maxCards = 20,
  }) async {
    final systemPrompt = _buildSystemPrompt(topic, maxCards);

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

  String _buildSystemPrompt(String topic, int maxCards) {
    if (OpenAIConstants.isLanguageTopic(topic)) {
      return '''
Você é um especialista em criação de flashcards para aprendizado de $topic.
Dado um texto ou tema, gere até $maxCards flashcards no formato JSON.
Cada flashcard deve ter:
- "front": frase no idioma-alvo (natural, do cotidiano)
- "back": tradução natural em português brasileiro

Regras:
- Frases curtas e memoráveis (máximo 15 palavras)
- Traduções naturais em português brasileiro
- Variedade de estruturas gramaticais
- Foco em vocabulário e expressões úteis

Responda APENAS com um array JSON válido, sem markdown, sem explicações:
[{"front": "...", "back": "..."}, ...]
''';
    } else {
      return '''
Você é um especialista em criação de flashcards educacionais sobre $topic.
Dado um texto ou tema, gere até $maxCards flashcards no formato JSON.
Cada flashcard deve ter:
- "front": pergunta ou conceito
- "back": resposta ou explicação clara e objetiva

Regras:
- Perguntas diretas e objetivas
- Respostas concisas (máximo 2-3 frases)
- Cobrir os pontos mais importantes do tema
- Linguagem clara em português brasileiro

Responda APENAS com um array JSON válido, sem markdown, sem explicações:
[{"front": "...", "back": "..."}, ...]
''';
    }
  }

  /// Generate an image using DALL-E 2 for a flashcard.
  /// Returns the image as raw bytes (PNG).
  Future<Uint8List> generateImage({
    required String apiKey,
    required String prompt,
  }) async {
    final body = jsonEncode({
      'model': OpenAIConstants.dalleModel,
      'prompt': prompt,
      'n': 1,
      'size': OpenAIConstants.dalleSize,
      'response_format': 'b64_json',
    });

    final response = await _httpClient.post(
      Uri.parse(OpenAIConstants.imageEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode == 401) {
      throw const AIFailure('Chave de API inválida.');
    }
    if (response.statusCode == 429) {
      throw const AIFailure('Limite de requisições atingido.');
    }
    if (response.statusCode != 200) {
      throw AIFailure('Erro DALL-E (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final b64 = decoded['data'][0]['b64_json'] as String;
    return base64Decode(b64);
  }

  /// Build a prompt for DALL-E from card content
  static String buildImagePrompt(String front, String back) {
    final content = front.length > 60 ? front.substring(0, 60) : front;
    return 'Educational flashcard illustration: $content. Simple, clear, colorful, cute cartoon style, white background, no text.';
  }
}
