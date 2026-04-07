class OpenAIConstants {
  OpenAIConstants._();

  static const String baseUrl = 'https://api.openai.com/v1';
  static const String chatEndpoint = '$baseUrl/chat/completions';
  static const String imageEndpoint = '$baseUrl/images/generations';
  static const String model = 'gpt-4o-mini';
  static const String dalleModel = 'dall-e-2';
  static const String dalleSize = '256x256';
  static const int maxTokens = 4000;
  static const double temperature = 0.3;

  static const List<String> predefinedTopics = [
    'Inglês',
    'Espanhol',
    'Francês',
    'Matemática',
    'Geografia',
    'Cálculo',
    'Física',
    'Biologia',
    'História',
    'Química',
    'Programação',
    'Concursos',
    'Direito',
    'Filosofia',
    'Medicina',
  ];

  static const Set<String> languageTopics = {
    'Inglês',
    'Espanhol',
    'Francês',
    'Italiano',
    'Alemão',
    'Japonês',
    'Coreano',
    'Mandarim',
  };

  static bool isLanguageTopic(String topic) {
    final lower = topic.toLowerCase();
    return languageTopics.any((lang) => lang.toLowerCase() == lower);
  }
}
