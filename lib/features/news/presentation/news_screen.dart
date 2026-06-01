import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/news_service.dart';
import 'package:mse_market_connect/shared/models/news_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NewsService();

    return Scaffold(
      appBar: AppBar(title: const Text('Market News')),
      body: FutureBuilder<List<NewsModel>>(
        future: service.getLatestNews(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final news = snapshot.data!;
          if (news.isEmpty) return const Center(child: Text('No news articles yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: news.length,
            itemBuilder: (context, i) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  if (news[i].sourceUrl != null) {
                    launchUrl(Uri.parse(news[i].sourceUrl!));
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (news[i].imageUrl != null)
                      Image.network(news[i].imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(news[i].category.toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                              Text(DateFormat('MMM dd, yyyy').format(news[i].publishedAt), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(news[i].title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(news[i].excerpt, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
