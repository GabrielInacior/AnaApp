// lib/data/datasources/remote/openai_client.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../core/constants/openai_constants.dart';
import '../../../core/errors/failures.dart';

class GeneratedCard {
  final String front;
  final String back;
  final String? tag;
  const GeneratedCard({required this.front, required this.back, this.tag});
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
    bool isPdfLineByLine = false,
    String? additionalInstructions,
    List<String> availableTags = const [],
  }) async {
    String systemPrompt;
    if (isPdfLineByLine) {
      systemPrompt = _buildPdfLineByLinePrompt(availableTags: availableTags);
    } else if (additionalInstructions != null &&
        additionalInstructions.trim().isNotEmpty) {
      systemPrompt = _buildPdfAIPrompt(maxCards, additionalInstructions.trim(),
          availableTags: availableTags);
    } else {
      systemPrompt =
          _buildSystemPrompt(topic, maxCards, availableTags: availableTags);
    }

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
                tag: c['tag'] as String?,
              ))
          .toList();
    } catch (_) {
      throw const AIFailure('Não foi possível interpretar a resposta da IA.');
    }
  }

  String _buildPdfLineByLinePrompt({List<String> availableTags = const []}) {
    final tagInstruction = _tagInstruction(availableTags);
    return '''
Você é um especialista em extrair flashcards de documentos bilíngues de estudo de idiomas.

O texto a seguir foi extraído de um PDF de estudos que contém pares bilíngues já prontos:
- Uma frase no idioma estrangeiro (ex: inglês, espanhol, francês, etc.)
- Seguida imediatamente pela tradução em português brasileiro

Sua tarefa:
1. Identifique TODOS os pares bilíngues no texto
2. Junte fragmentos de frases que foram quebrados em múltiplas linhas
3. front = frase completa no idioma estrangeiro
4. back = tradução completa em português brasileiro
5. Ignore completamente: títulos, cabeçalhos, rodapés, marcas d'água, números de página, strings codificadas
$tagInstruction
Regras:
- Extraia o MÁXIMO de pares possível — não limite a quantidade
- Mantenha as frases exatamente como estão no documento (não reescreva)
- Se uma frase está quebrada em 2-3 linhas, junte-a em uma frase completa
- NÃO invente ou adicione pares que não existem no texto

Responda APENAS com um array JSON válido, sem markdown, sem explicações:
[{"front": "...", "back": "...", "tag": "..."}, ...]
''';
  }

  String _buildPdfAIPrompt(int maxCards, String instructions,
      {List<String> availableTags = const []}) {
    final tagInstruction = _tagInstruction(availableTags);
    return '''
Você é um especialista em criação de flashcards a partir de documentos.
Dado o texto extraído de um documento (PDF ou slides), gere até $maxCards flashcards no formato JSON.

Instruções do usuário: $instructions
$tagInstruction
Regras:
- Siga as instruções do usuário como prioridade
- Crie cards claros e objetivos baseados no conteúdo do documento
- Respostas concisas (máximo 2-3 frases)
- Cubra os pontos mais importantes do texto

Responda APENAS com um array JSON válido, sem markdown, sem explicações:
[{"front": "...", "back": "...", "tag": "..."}, ...]
''';
  }

  String _buildSystemPrompt(String topic, int maxCards,
      {List<String> availableTags = const []}) {
    final tagInstruction = _tagInstruction(availableTags);
    if (OpenAIConstants.isLanguageTopic(topic)) {
      return '''
Você é um especialista em criação de flashcards para aprendizado de $topic.
Dado um texto ou tema, gere até $maxCards flashcards no formato JSON.
Cada flashcard deve ter:
- "front": frase no idioma-alvo (natural, do cotidiano)
- "back": tradução natural em português brasileiro
- "tag": categoria do card
$tagInstruction
Regras:
- Frases curtas e memoráveis (máximo 15 palavras)
- Traduções naturais em português brasileiro
- Variedade de estruturas gramaticais
- Foco em vocabulário e expressões úteis

Responda APENAS com um array JSON válido, sem markdown, sem explicações:
[{"front": "...", "back": "...", "tag": "..."}, ...]
''';
    } else {
      return '''
Você é um especialista em criação de flashcards educacionais sobre $topic.
Dado um texto ou tema, gere até $maxCards flashcards no formato JSON.
Cada flashcard deve ter:
- "front": pergunta ou conceito
- "back": resposta ou explicação clara e objetiva
- "tag": categoria do card
$tagInstruction
Regras:
- Perguntas diretas e objetivas
- Respostas concisas (máximo 2-3 frases)
- Cobrir os pontos mais importantes do tema
- Linguagem clara em português brasileiro

Responda APENAS com um array JSON válido, sem markdown, sem explicações:
[{"front": "...", "back": "...", "tag": "..."}, ...]
''';
    }
  }

  String _tagInstruction(List<String> availableTags) {
    if (availableTags.isEmpty) {
      return '''
Para o campo "tag", escolha o assunto mais adequado dentre estas opções:
Inglês, Espanhol, Francês, Matemática, Geografia, Cálculo, Física, Biologia, História, Química, Programação, Concursos, Direito, Filosofia, Medicina
''';
    }
    return '''
Para o campo "tag", use APENAS uma destas tags: ${availableTags.join(', ')}
Escolha a tag mais adequada ao conteúdo de cada card. Cada card deve ter exatamente uma dessas tags.
''';
  }

  /// Assign tags to existing cards based on their content.
  /// Returns a map of card ID → assigned tag.
  Future<Map<String, String>> assignTags({
    required String apiKey,
    required List<Map<String, String>> cards, // [{id, front, back}, ...]
    required List<String> availableTags,
  }) async {
    final tagList = availableTags.join(', ');
    final systemPrompt = '''
Você é um especialista em classificação de flashcards educacionais.

Você receberá uma lista de flashcards em JSON. Cada item tem "id", "front" (pergunta/frente) e "back" (resposta/verso).

Sua tarefa: para CADA card, leia atentamente o conteúdo de "front" E "back" e atribua a tag que MELHOR descreve o assunto específico daquele card.

Tags disponíveis: $tagList

DETECÇÃO DE IDIOMAS — CRÍTICO:
- Se o "front" está em um idioma estrangeiro (inglês, espanhol, francês, etc.) e o "back" é a tradução em português (ou vice-versa), isso é um card de ESTUDO DE IDIOMA
- Identifique QUAL idioma estrangeiro aparece: se o front está em inglês → tag "Inglês", se em espanhol → tag "Espanhol", se em francês → tag "Francês", etc.
- O idioma do conteúdo determina a tag, NÃO o assunto da frase. Ex: "The cat is on the table" / "O gato está na mesa" → tag "Inglês" (é estudo de inglês, não zoologia)
- Frases do cotidiano, vocabulário, expressões idiomáticas em outro idioma = estudo daquele idioma
- Apenas marque como a matéria específica (Biologia, História, etc.) se AMBOS front e back estão em português e discutem um conceito acadêmico

REGRAS CRÍTICAS:
- Analise o conteúdo REAL de cada card individualmente — não agrupe por proximidade na lista
- A tag deve refletir o assunto principal mencionado no front e back do card
- Se o front menciona "VueJS", a tag deve ser relacionada a VueJS/Programação, NÃO a React ou outro framework
- Se o front menciona "mitocôndria", a tag deve ser Biologia, não Química
- Leia palavras-chave específicas: nomes de tecnologias, conceitos, termos técnicos
- Em caso de dúvida entre duas tags, escolha a mais específica ao conteúdo do card
- CADA card deve receber exatamente UMA tag da lista acima

EXEMPLOS:
- front: "What time is it?", back: "Que horas são?" → Inglês
- front: "Je suis fatigué", back: "Eu estou cansado" → Francês
- front: "Hola, ¿cómo estás?", back: "Olá, como você está?" → Espanhol
- front: "Break a leg", back: "Boa sorte (expressão idiomática)" → Inglês
- front: "O que é fotossíntese?", back: "Processo de conversão de luz..." → Biologia
- front: "Qual a diferença entre let e const?", back: "let permite reatribuição..." → Programação

Responda APENAS com um array JSON válido, sem markdown, sem explicações:
[{"id": "...", "tag": "..."}, ...]
''';

    final userPrompt = jsonEncode(cards);

    final body = jsonEncode({
      'model': OpenAIConstants.model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': OpenAIConstants.maxTokens,
      'temperature': 0.3,
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
      final List<dynamic> results = jsonDecode(content.trim());
      final map = <String, String>{};
      for (final r in results) {
        if (r is Map<String, dynamic> && r['id'] != null && r['tag'] != null) {
          final tag = r['tag'] as String;
          if (availableTags.contains(tag)) {
            map[r['id'] as String] = tag;
          }
        }
      }
      return map;
    } catch (_) {
      throw const AIFailure('Não foi possível interpretar a resposta da IA.');
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
