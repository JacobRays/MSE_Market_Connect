import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/ad_service.dart';
import 'package:mse_market_connect/core/services/news_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/brokers/presentation/broker_list_screen.dart';
import 'package:mse_market_connect/features/home/presentation/quick_actions_screen.dart';
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
    final actions = <QuickActionItem>[
      QuickActionItem(
        icon: Icons.show_chart_rounded,
        label: 'Market',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MarketScreen())),
      ),
      QuickActionItem(
        icon: Icons.receipt_long_rounded,
        label: 'My Orders',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
      ),
      QuickActionItem(
        icon: Icons.star_rounded,
        label: 'Watchlist',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyAlertsScreen())),
      ),
      QuickActionItem(
        icon: Icons.school_rounded,
        label: 'Learn',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LearningScreen())),
      ),
      QuickActionItem(
        icon: Icons.newspaper_rounded,
        label: 'News',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NewsScreen())),
      ),
      QuickActionItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Portfolio',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PortfolioScreen())),
      ),
      QuickActionItem(
        icon: Icons.support_agent_rounded,
        label: 'Support',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
      ),
      QuickActionItem(
        icon: Icons.business_center_rounded,
        label: 'Brokers',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BrokerListScreen())),
      ),
    ];

    final homeActions = actions.take(8).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('MSE Market Connect')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _NewsTicker(),
            const SizedBox(height: 14),
            const _AdPanel(),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuickActionsScreen(actions: actions),
                    ),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _HomeQuickActionsGrid(actions: homeActions),
          ],
        ),
      ),
    );
  }
}

class _HomeQuickActionsGrid extends StatelessWidget {
  final List<QuickActionItem> actions;
  const _HomeQuickActionsGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final crossAxisCount = c.maxWidth < 360 ? 3 : 4;
        return GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, i) => _QuickActionCircle(item: actions[i]),
        );
      },
    );
  }
}

class _QuickActionCircle extends StatelessWidget {
  final QuickActionItem item;
  const _QuickActionCircle({required this.item});

  @override
  Widget build(BuildContext context) {
    final iconColor = AppTheme.primaryColor;
    final bg = AppTheme.primaryColor.withOpacity(0.08);
    final border = AppTheme.primaryColor.withOpacity(0.14);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: border),
            ),
            child: Icon(item.icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _NewsTicker extends StatelessWidget {
  const _NewsTicker();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: NewsService().getLatestNews(),
      builder: (context, snapshot) {
        String text = "Welcome to MSE Market Connect. Stay tuned for updates.";
        if (snapshot.hasData) {
          final items = snapshot.data!;
          if (items.isNotEmpty) {
            text = items.map((n) => "• ${n.title}").join("   ");
          }
        }
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
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
