import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/ad_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/brokers/presentation/broker_list_screen.dart';
import 'package:mse_market_connect/features/learning/presentation/learning_screen.dart';
import 'package:mse_market_connect/features/market/presentation/market_screen.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/news/presentation/news_screen.dart';
import 'package:mse_market_connect/features/portfolio/presentation/portfolio_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/settings_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/support_screen.dart';
import 'package:mse_market_connect/features/trade/presentation/my_orders_screen.dart';

import 'package:mse_market_connect/features/home/presentation/widgets/ad_carousel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.show_chart_rounded,
        label: 'Market',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MarketScreen())),
      ),
      _QuickActionItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Portfolio',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PortfolioScreen())),
      ),
      _QuickActionItem(
        icon: Icons.star_rounded,
        label: 'Watchlist',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyAlertsScreen())),
      ),
      _QuickActionItem(
        icon: Icons.newspaper_rounded,
        label: 'News',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NewsScreen())),
      ),
      _QuickActionItem(
        icon: Icons.receipt_long_rounded,
        label: 'My Orders',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
      ),
      _QuickActionItem(
        icon: Icons.school_rounded,
        label: 'Learn',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LearningScreen())),
      ),
      _QuickActionItem(
        icon: Icons.business_center_rounded,
        label: 'Brokers',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BrokerListScreen())),
      ),
      _QuickActionItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      // Extra actions shown only when expanded:
      _QuickActionItem(
        icon: Icons.support_agent_rounded,
        label: 'Support',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
      ),
    ];

    final shown = _expanded ? actions : actions.take(8).toList();

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
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Collapse' : 'View All'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              child: _QuickActionsGrid(actions: shown),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _QuickActionsGrid extends StatelessWidget {
  final List<_QuickActionItem> actions;
  const _QuickActionsGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    final iconColor = AppTheme.primaryColor;
    final bg = AppTheme.primaryColor.withValues(alpha: 0.08);
    final border = AppTheme.primaryColor.withValues(alpha: 0.14);

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
          itemBuilder: (context, i) {
            final item = actions[i];
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
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NewsTicker extends StatefulWidget {
  const _NewsTicker();

  @override
  State<_NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<_NewsTicker> {
  final _db = Supabase.instance.client;
  String _text = 'Welcome to MSE Market Connect. Stay tuned for updates.';
  RealtimeChannel? _newsChannel;
  RealtimeChannel? _stocksChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _listen();
  }

  @override
  void dispose() {
    if (_newsChannel != null) _db.removeChannel(_newsChannel!);
    if (_stocksChannel != null) _db.removeChannel(_stocksChannel!);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final newsRes = await _db
          .from('news')
          .select('title')
          .order('published_at', ascending: false)
          .limit(10);

      final stocksRes = await _db
          .from('stocks')
          .select('symbol, price, change_percent')
          .eq('is_active', true)
          .order('symbol', ascending: true)
          .limit(16);

      final newsTitles = (newsRes as List)
          .map((r) => (r['title'] ?? '').toString().trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final prices = (stocksRes as List).map((r) {
        final sym = (r['symbol'] ?? '').toString();
        final price = (r['price'] as num?)?.toDouble() ?? 0.0;
        final chg = (r['change_percent'] as num?)?.toDouble() ?? 0.0;
        final sign = chg >= 0 ? '+' : '';
        return '$sym MWK ${price.toStringAsFixed(2)} ($sign${chg.toStringAsFixed(2)}%)';
      }).toList();

      final parts = <String>[];
      if (prices.isNotEmpty) parts.addAll(prices);
      if (newsTitles.isNotEmpty) parts.addAll(newsTitles.map((t) => '• $t'));

      if (!mounted) return;
      setState(() {
        _text = parts.isEmpty ? _text : parts.join('     ');
      });
    } catch (_) {
      // keep current text
    }
  }

  void _listen() {
    _newsChannel = _db
        .channel('ticker-news')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'news',
          callback: (_) => _load(),
        )
        .subscribe();

    _stocksChannel = _db
        .channel('ticker-stocks')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'stocks',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _Marquee(text: _text),
    );
  }
}

class _Marquee extends StatefulWidget {
  final String text;
  const _Marquee({required this.text});

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> {
  final _controller = ScrollController();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didUpdateWidget(covariant _Marquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && _controller.hasClients) {
      _controller.jumpTo(0);
    }
    if (!_running) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _start() {
    if (_running) return;
    _running = true;

    () async {
      while (mounted) {
        if (!_controller.hasClients) {
          await Future.delayed(const Duration(milliseconds: 120));
          continue;
        }

        final max = _controller.position.maxScrollExtent;
        if (max <= 0) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        // Scroll duration based on content length (keeps consistent speed)
        const double pxPerSecond = 7.0;
        final ms = ((max / pxPerSecond) * 1000).toInt().clamp(45000, 240000);

        await _controller.animateTo(
          max,
          duration: Duration(milliseconds: ms),
          curve: Curves.linear,
        );

        if (!mounted) break;
        _controller.jumpTo(0);
        await Future.delayed(const Duration(milliseconds: 900));
      }
    }();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = '${widget.text}     ${widget.text}     ${widget.text}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdPanel extends StatelessWidget {
  const _AdPanel();

  Widget build(BuildContext context) {
    return FutureBuilder<List<AdModel>>(
      future: AdService().getActiveAds(limit: 5),
      builder: (context, snapshot) {
        final ads = snapshot.data ?? [];
        return AdCarousel(ads: ads, hideMissingImages: true);
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

class _AdCarousel extends StatefulWidget {
  final List<AdModel> ads;
  const _AdCarousel({required this.ads});

  @override
  State<_AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<_AdCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _restartAutoSlide();
  }

  @override
  void didUpdateWidget(covariant _AdCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads.length != widget.ads.length) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
      _restartAutoSlide();
    }
  }

  void _restartAutoSlide() {
    _timer?.cancel();
    if (widget.ads.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;
      if (widget.ads.isEmpty) return;

      _index = (_index + 1) % widget.ads.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = widget.ads;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: ads.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _AdCard(
              title: ads[i].title,
              subtitle: ads[i].subtitle ?? 'Sponsored',
              imageUrl: ads[i].imageUrl,
            ),
          ),
        ),
        if (ads.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(ads.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: active ? 18 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
