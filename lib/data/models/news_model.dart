class NewsModel {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String url;
  final String? imageUrl;
  final String? category;
  final List<String> relatedSymbols;
  final DateTime? publishedAt;
  final double? sentimentScore; // -1.0 to 1.0
  final String? sentimentLabel; // 'bullish', 'bearish', 'neutral'

  const NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    this.imageUrl,
    this.category,
    required this.relatedSymbols,
    this.publishedAt,
    this.sentimentScore,
    this.sentimentLabel,
  });

  bool get isBullish =>
      sentimentLabel == 'Bullish' || (sentimentScore ?? 0) > 0.2;
  bool get isBearish =>
      sentimentLabel == 'Bearish' || (sentimentScore ?? 0) < -0.2;

  factory NewsModel.fromMap(Map<String, dynamic> map) {
    // Handle Alpha Vantage news feed format
    final tickerSentiments = map['ticker_sentiment'];
    final symbols = <String>[];
    double? sentimentScore;
    String? sentimentLabel;

    if (tickerSentiments is List && tickerSentiments.isNotEmpty) {
      for (final t in tickerSentiments) {
        if (t is Map && t['ticker'] != null) {
          symbols.add(t['ticker'].toString());
        }
      }
      final first = tickerSentiments.first;
      if (first is Map) {
        sentimentScore = _toDouble(first['ticker_sentiment_score']);
        sentimentLabel = first['ticker_sentiment_label']?.toString();
      }
    }

    // Overall sentiment fallback
    sentimentScore ??=
        _toDouble(map['overall_sentiment_score'] ?? map['sentiment_score']);
    sentimentLabel ??= map['overall_sentiment_label']?.toString() ??
        map['sentiment_label']?.toString();

    return NewsModel(
      id: map['id']?.toString() ?? map['url']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      summary: map['summary']?.toString() ?? map['content']?.toString() ?? '',
      source: map['source']?.toString() ??
          map['source_domain']?.toString() ??
          'Unknown',
      url: map['url']?.toString() ?? '',
      imageUrl: map['banner_image']?.toString() ?? map['image_url']?.toString(),
      category: map['category_within_source']?.toString() ??
          map['category']?.toString(),
      relatedSymbols: symbols.isNotEmpty
          ? symbols
          : (map['symbols'] is List ? List<String>.from(map['symbols']) : []),
      publishedAt: _parseDateTime(map['time_published'] ?? map['published_at']),
      sentimentScore: sentimentScore,
      sentimentLabel: sentimentLabel,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'summary': summary,
        'source': source,
        'url': url,
        if (imageUrl != null) 'image_url': imageUrl,
        if (category != null) 'category': category,
        'symbols': relatedSymbols,
        if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
        if (sentimentScore != null) 'sentiment_score': sentimentScore,
        if (sentimentLabel != null) 'sentiment_label': sentimentLabel,
      };

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    final s = value.toString();
    if (s.length == 15) {
      // Alpha Vantage format: 20240115T143000
      try {
        return DateTime(
          int.parse(s.substring(0, 4)),
          int.parse(s.substring(4, 6)),
          int.parse(s.substring(6, 8)),
          int.parse(s.substring(9, 11)),
          int.parse(s.substring(11, 13)),
          int.parse(s.substring(13, 15)),
        );
      } catch (_) {}
    }
    return DateTime.tryParse(s);
  }

  @override
  String toString() => 'NewsModel(title: $title, source: $source)';
}
