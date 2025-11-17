import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article_model.dart';

class ArticleDetailPage extends StatelessWidget {
  final Article article;
  const ArticleDetailPage({super.key, required this.article});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                article.title,
                style: const TextStyle(fontSize: 16.0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Image.network(article.imageUrl, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.0,
                    children: article.tags
                        .map((tag) => Chip(label: Text('#$tag')))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    article.content.split('\n\n').first,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...article.content.split('\n\n').skip(1).map((paragraph) {
                    if (paragraph.startsWith(RegExp(r'[0-9]\.'))) {
                      return _buildSectionTitle(theme, paragraph);
                    }
                    return _buildParagraph(paragraph);
                  }),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Sumber Informasi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Artikel ini dirangkum dari ${article.sourceName}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.launch),
                    label: const Text('Baca di Situs Asli'),
                    onPressed: () => _launchURL(article.sourceUrl),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(fontSize: 16, height: 1.6),
      ),
    );
  }
}
