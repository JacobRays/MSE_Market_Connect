import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/ad_service.dart';
import 'package:mse_market_connect/core/services/news_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/brokers/presentation/broker_list_screen.dart';
import 'package:mse_market_connect/features/learning/presentation/learning_screen.dart';
import 'package:mse_market_connect/features/market/presentation/market_screen.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/news/presentation/news_screen.dart';
import 'package:mse_market_connect/features/portfolio/presentation/portfolio_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/support_screen.dart';
import 'package:mse_market_connect/features/trade/presentation/my_orders_screen.dart';
import 'package:mse_market_connect/shared/models/ad_model.dart';
import 'package:mse_market_connect/shared/models/news_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.show_chart_rounded,
        label: 'Market',
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MarketScreen())),
      ),
      _QuickActionData(
        icon: Icons.receipt_long_rounded,
        label: 'My Orders',
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
      ),
      _QuickActionData(
        icon: Icons.star_rounded,
        label: 'Watchlist',
        gradient: const LinearGradient(
          colors: [Color(0xFFF9A825), Color(0xFFFFB300)],
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyAlertsScreen())),
      ),
      _QuickActionData(
        icon: Icons.school_rounded,
        label: 'Learn',
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LearningScreen())),
      ),
      _QuickActionData(
        icon: Icons.newspaper_rounded,
        label: 'News',
        gradient: const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF455A64)],
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NewsScreen())),
      ),
      _QuickActionData(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Portfolio',
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PortfolioScreen())),
      ),
      _QuickActionData(
        icon: Icons.support_agent_rounded,
        label: 'Support',
        gradient: const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF6D4C41)],
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
      ),
      _QuickActionData(
        icon: Icons.business_center_rounded,
        label: 'Brokers',
        gradient: const LinearGradient(
          colors: [Color(0xFF283593), Color(0xFF3949AB)],
        ),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BrokerListScreen())),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MSE Market Connect')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _NewsTicker(),
            const SizedBox(height: 14),
            const _AdPanel(),
            const SizedBox(height: 16),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions.map((a) => _QuickActionChip(item: a)).toList(),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _NewsTicker extends StatelessWidget {
  const _NewsTicker();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsModel>>(
      future: NewsService().getLatestNews(),
      builder: (context, snapshot) {
        String text = "Welcome to MSE Market Connect. Stay tuned for updates.";
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          text = snapshot.data!.map((n) => "• ${n.title}").join("   ");
        }
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdPanel extends StatelessWidget {
  const _AdPanel();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdModel>>(
      future: AdService().getActiveAds(limit: 5),
      builder: (context, snapshot) {
        final ads = snapshot.data ?? [];
        if (ads.isEmpty) {
          return const _AdCard(
            title: 'Advertise Here',
            subtitle: 'Reach all MSE investors',
            imageUrl: null,
          );
        }
        return SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) => _AdCard(
              title: ads[index].title,
              subtitle: ads[index].subtitle ?? 'Sponsored',
              imageUrl: ads[index].imageUrl,
            ),
          ),
        );
      },
    );
  }
}

class _AdCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  const _AdCard({required this.title, required this.subtitle, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Positioned.fill(
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: AppTheme.primaryColor),
                  )
                : Container(color: AppTheme.primaryColor),
          ),
          Container(color: Colors.black38),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  _QuickActionData({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}

class _QuickActionChip extends StatelessWidget {
  final _QuickActionData item;
  const _QuickActionChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: StadiumBorder(
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: item.onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
