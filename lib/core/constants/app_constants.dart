class AppConstants {
  AppConstants._();

  static const String appName = 'AnaApp';
  static const int maxCardsPerSession = 20;
  static const int maxCardsPerAIGeneration = 50;
  static const String exportFileExtension = '.anaapp.json';
  static const String apiKeyStorageKey = 'openai_api_key';
  static const String userNamePrefKey = 'user_name';
  static const String customTagsPrefKey = 'custom_tags';
  static const String customTagColorsPrefKey = 'custom_tag_colors';
}
