class ApiConstants {
  ApiConstants._();

  static const String yahooFinanceBaseUrl =
      'https://yahoo-finance15.p.rapidapi.com/api/v1';
  static const String finnhubBaseUrl = 'https://finnhub.io/api/v1';
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
  static const String fmpBaseUrl = 'https://financialmodelingprep.com/api/v3';
  static const String marketauxBaseUrl = 'https://api.marketaux.com/v1';
  static const String ollamaDefaultBaseUrl = 'http://localhost:11434';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
