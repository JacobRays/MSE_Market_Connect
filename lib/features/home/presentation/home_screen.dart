import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/ad_service.dart';
import 'package:mse_market_connect/core/services/news_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/learning/presentation/learning_screen.dart';
import 'package:mse_market_connect/features/market/presentation/market_screen.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
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
        icon: Icons.track_changes_rounded,
        label: 'Watch',
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
            GridView.builder(
              itemCount: actions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, index) =>
                  _QuickAction3DCard(item: actions[index]),
            ),
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

class _QuickAction3DCard extends StatefulWidget {
  final _QuickActionData item;
  const _QuickAction3DCard({required this.item});
  @override
  State<_QuickAction3DCard> createState() => _QuickAction3DCardState();
}

class _QuickAction3DCardState extends State<_QuickAction3DCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.item.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: widget.item.gradient,
                ),
                child: Icon(widget.item.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                widget.item.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
