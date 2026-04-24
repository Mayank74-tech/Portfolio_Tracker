class NewsEntity {
  final String id;
  final String title;
  final String description;
  final String source;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;
  final List<String> relatedSymbols; // Symbols mentioned in the news

  NewsEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.relatedSymbols,
  });

  factory NewsEntity.fromJson(Map<String, dynamic> json) {
    return NewsEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      source: json['source'] as String,
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      relatedSymbols: (json['relatedSymbols'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source,
      'url': url,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'relatedSymbols': relatedSymbols,
    };
  }
}
