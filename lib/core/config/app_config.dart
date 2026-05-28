class AppConfig {
  const AppConfig({
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:4500/api/v1',
    ),
  });

  final String apiBaseUrl;
}
