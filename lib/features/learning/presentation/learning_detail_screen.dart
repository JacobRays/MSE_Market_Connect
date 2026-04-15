import 'package:flutter/material.dart';

class LearningArticle {
  final String title;
  final String subtitle;
  final List<String> paragraphs;
  final List<String> bullets;

  const LearningArticle({
    required this.title,
    required this.subtitle,
    required this.paragraphs,
    this.bullets = const [],
  });
}

class LearningDetailScreen extends StatelessWidget {
  final LearningArticle article;

  const LearningDetailScreen({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                article.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ...article.paragraphs.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    p,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              if (article.bullets.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Key points',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                ...article.bullets.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(
                          child: Text(
                            b,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Disclaimer: This content is for education only and is not financial advice. '
                    'MSE Market Connect routes order requests to licensed brokers and does not execute trades.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
