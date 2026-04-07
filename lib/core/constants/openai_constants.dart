class OpenAIConstants {
  OpenAIConstants._();

  static const String baseUrl = 'https://api.openai.com/v1';
  static const String chatEndpoint = '$baseUrl/chat/completions';
  static const String model = 'gpt-4o-mini';
  static const int maxTokens = 2000;
  static const double temperature = 0.3;
}
