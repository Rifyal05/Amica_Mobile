import '../services/api_config.dart';

class Article {
  final int id;
  final String category;
  final String title;
  final String content;
  final String imageUrl;
  final int readTime;
  final List<String> tags;
  final String sourceName;
  final String sourceUrl;
  final bool isFeatured;
  final String createdAt;
  final String author;

  const Article({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.readTime,
    required this.tags,
    required this.sourceName,
    required this.sourceUrl,
    this.isFeatured = false,
    required this.createdAt,
    required this.author,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        parsedTags = List<String>.from(json['tags']);
      } else if (json['tags'] is String) {
        parsedTags = (json['tags'] as String)
            .split(',')
            .map((e) => e.trim())
            .toList();
      }
    }

    String rawImg = json['image_url'] ?? '';
    String finalImgUrl;

    if (rawImg.startsWith('http')) {
      finalImgUrl = rawImg;
    } else if (rawImg.isNotEmpty) {
      finalImgUrl = "${ApiConfig.baseUrl}/static/uploads/articles/$rawImg";
    } else {
      finalImgUrl = 'https://via.placeholder.com/400x200?text=No+Image';
    }

    int estimatedReadTime =
        json['read_time'] ??
        ((json['content']?.toString().split(' ').length ?? 0) / 200).ceil();

    return Article(
      id: json['id'] ?? 0,
      category: json['category'] ?? 'Umum',
      title: json['title'] ?? 'Tanpa Judul',
      content: json['content'] ?? '',
      imageUrl: finalImgUrl,
      readTime: estimatedReadTime < 1 ? 1 : estimatedReadTime,
      tags: parsedTags,
      sourceName: json['source_name'] ?? 'Amica Redaksi',
      sourceUrl: json['source_url'] ?? '',
      isFeatured: json['is_featured'] == true,
      createdAt: json['created_at'] ?? '',
      author: json['author'] ?? 'Admin',
    );
  }
}
