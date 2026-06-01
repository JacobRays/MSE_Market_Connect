class NewsModel {
  final String title;
  final String excerpt;
  final String? imageUrl;
  final String category;
  final DateTime publishedAt;
  final String? sourceUrl;

  NewsModel({
    required this.title,
    required this.excerpt,
    this.imageUrl,
    required this.category,
    required this.publishedAt,
    this.sourceUrl,
  });

  factory NewsModel.fromMap(Map<String, dynamic> map) {
    return NewsModel(
      title: map['title'] ?? '',
      excerpt: map['excerpt'] ?? '',
      imageUrl: map['image_url'],
      category: map['category'] ?? 'Market News',
      publishedAt: DateTime.parse(map['published_at']),
      sourceUrl: map['source_url'],
    );
  }
}
