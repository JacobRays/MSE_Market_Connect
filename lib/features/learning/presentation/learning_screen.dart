import 'package:flutter/material.dart';
import 'package:mse_market_connect/features/learning/presentation/learning_detail_screen.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  static const List<LearningArticle> _articles = [
    LearningArticle(
      title: 'What is the Malawi Stock Exchange (MSE)?',
      subtitle: 'A simple explanation of how MSE works.',
      paragraphs: [
        'The Malawi Stock Exchange (MSE) is the official marketplace where shares of listed companies are bought and sold in Malawi.',
        'When you buy shares, you become a part-owner of a company. Your return can come from price growth (capital gains) and dividends (profit sharing).',
        'MSE Market Connect helps you view market data and route your order request to a licensed broker. The broker executes the trade on the exchange.',
      ],
      bullets: [
        'Shares represent ownership in a company.',
        'Prices move based on demand, performance, and market news.',
        'Trades are executed by licensed brokers (not by this app).',
      ],
    ),
    LearningArticle(
      title: 'How to buy shares (step by step)',
      subtitle: 'From choosing a company to submitting an order request.',
      paragraphs: [
        'Step 1: Open the Market tab and select a company.',
        'Step 2: Review the price and daily change, then tap “Buy Shares”.',
        'Step 3: Enter the quantity and choose a licensed broker.',
        'Step 4: Submit your order request. The broker will process and execute it according to MSE rules.',
        'After execution, settlement typically happens after a number of business days (e.g., T+3).',
      ],
      bullets: [
        'Always understand brokerage fees before placing an order.',
        'Start small while learning how the market behaves.',
        'Keep records of confirmations and statements from your broker.',
      ],
    ),
    LearningArticle(
      title: 'Understanding dividends',
      subtitle: 'How companies pay shareholders.',
      paragraphs: [
        'Dividends are payments made by a company to its shareholders, usually from profits.',
        'Not every company pays dividends. Some reinvest profits into growth.',
        'Dividend announcements usually include the amount per share and payment date.',
      ],
      bullets: [
        'Dividends depend on company profitability and board decisions.',
        'Owning shares on the “record date” is important for eligibility.',
      ],
    ),
    LearningArticle(
      title: 'Risk: How to reduce investment risk',
      subtitle: 'Practical ideas for retail investors.',
      paragraphs: [
        'All investing involves risk. Share prices can go up or down.',
        'A common way to reduce risk is diversification: spreading your money across different companies or sectors.',
        'Avoid investing money you may need urgently. Investing is often best with a long-term mindset.',
      ],
      bullets: [
        'Diversify across multiple stocks.',
        'Focus on long-term fundamentals, not only daily movements.',
        'Keep learning and follow official announcements.',
      ],
    ),
    LearningArticle(
      title: 'Trading vs Investing',
      subtitle: 'Two approaches with different goals.',
      paragraphs: [
        'Trading is usually short-term buying and selling to profit from price movement.',
        'Investing is typically long-term ownership aiming for growth and dividends.',
        'Most beginners do better starting with investing principles and clear goals.',
      ],
      bullets: [
        'Trading is higher-frequency and often higher-risk.',
        'Investing is long-term and focuses on business performance.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Hub'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final article = _articles[index];

          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.menu_book),
              title: Text(article.title),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(article.subtitle),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LearningDetailScreen(article: article),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
