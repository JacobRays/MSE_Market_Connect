import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/ad_service.dart';
import 'package:mse_market_connect/core/services/subscription_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/brokers/presentation/broker_list_screen.dart';
import 'package:mse_market_connect/features/learning/presentation/learning_screen.dart';
import 'package:mse_market_connect/features/market/presentation/market_screen.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/news/presentation/news_screen.dart';
import 'package:mse_market_connect/features/portfolio/presentation/portfolio_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/settings_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/support_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/upgrade_screen.dart';
import 'package:mse_market_connect/features/trade/presentation/my_orders_screen.dart';
import 'package:mse_market_connect/features/home/presentation/quick_actions_screen.dart';
import 'package:mse_market_connect/features/home/presentation/widgets/ad_carousel.dart';
import 'package:mse_market_connect/shared/models/ad_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _expanded = false;
  bool _isPremium = false;

  final _tickerKey = GlobalKey<_NewsTickerState>();
  UniqueKey _adPanelKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final sub = await SubscriptionService().getOrCreateMySubscription();
      if (!mounted) return;
      setState(() {
        _isPremium = sub.isPremium;
      });
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    await _tickerKey.currentState?.refresh();
    await _checkPremiumStatus();
    setState(() {
      _adPanelKey = UniqueKey();
    });
  }

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
        child: Column(
          children: [
            AnimatedSlide(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              offset: _isPremium ? const Offset(0, -1.2) : Offset.zero,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isPremium ? 0.0 : 1.0,
                child: _PremiumBanner(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                    );
                    _checkPremiumStatus();
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _NewsTicker(key: _tickerKey),
                    const SizedBox(height: 14),
                    _AdPanel(key: _adPanelKey),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Actions',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _expanded = !_expanded),
                          child: Text(_expanded ? 'Collapse' : 'View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: _QuickActionsGrid(
                        key: ValueKey(shown.length),
                        actions: shown,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Premium banner (unchanged) ────────────────────────────────
class _PremiumBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _PremiumBanner({required this.onTap});

  @override
  _PremiumBannerState createState() => _PremiumBannerState();
}

class _PremiumBannerState extends State<_PremiumBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Transform.scale(
            scale: _pulse.value,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFFFC107)],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Action items (unchanged) ────────────────────────────
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
  const _QuickActionsGrid({required this.actions, super.key});

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
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bg,
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
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

class _AdPanel extends StatelessWidget {
  const _AdPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdModel>>(
      future: AdService().getActiveAds(limit: 5),
      builder: (context, snapshot) {
        final ads = snapshot.data ?? const <AdModel>[];
        return AdCarousel(ads: ads, hideMissingImages: true);
      },
    );
  }
}

// ─── Ticker item data class ────────────────────────────────────
class _TickerItem {
  final String symbol;
  final double price;
  final double changePercent; // already signed (+ for gain, - for loss)

  const _TickerItem({
    required this.symbol,
    required this.price,
    required this.changePercent,
  });
}

// ─── Coloured News Ticker ──────────────────────────────────────
class _NewsTicker extends StatefulWidget {
  const _NewsTicker({super.key});

  @override
  _NewsTickerState createState() => _NewsTickerState();
}

class _NewsTickerState extends State<_NewsTicker> {
  final _db = Supabase.instance.client;
  List<_TickerItem> _items = [];
  String _newsText = '';
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

  Future<void> refresh() async => _load();

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

      final items = (stocksRes as List).map((r) {
        final sym = (r['symbol'] ?? '').toString();
        final price = (r['price'] as num?)?.toDouble() ?? 0.0;
        final chg = (r['change_percent'] as num?)?.toDouble() ?? 0.0;
        return _TickerItem(symbol: sym, price: price, changePercent: chg);
      }).toList();

      if (!mounted) return;
      setState(() {
        _items = items;
        _newsText = newsTitles.map((t) => '• $t').join('     ');
      });
    } catch (_) {}
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

  /// Builds a [RichText] with coloured change percentages
  Widget _buildTickerText(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = darkMode ? Colors.white : AppTheme.primaryColor;

    List<InlineSpan> spans = [];

    // Add each stock with its coloured percentage
    for (final item in _items) {
      final gain = item.changePercent >= 0;
      final changeColor =
          gain ? AppTheme.gainColor : AppTheme.lossColor;
      final sign = gain ? '+' : '';
      final changeStr =
          '$sign${item.changePercent.toStringAsFixed(2)}%';

      spans.add(TextSpan(
        text: '${item.symbol} MWK ${item.price.toStringAsFixed(2)} (',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: defaultColor,
        ),
      ));
      spans.add(TextSpan(
        text: changeStr,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: changeColor,
        ),
      ));
      spans.add(TextSpan(
        text: ')     ',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: defaultColor,
        ),
      ));
    }

    // Add news headlines
    spans.add(TextSpan(
      text: _newsText.isEmpty ? '' : '     $_newsText',
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: defaultColor,
      ),
    ));

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: _Marquee(child: _buildTickerText(context)),
    );
  }
}

class _Marquee extends StatefulWidget {
  final Widget child;
  const _Marquee({required this.child});

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
    if (oldWidget.child != widget.child && _controller.hasClients) {
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
    // duplicate child to avoid blank gap during reset
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            widget.child,
            const SizedBox(width: 80),
            widget.child,
          ],
        ),
      ),
    );
  }
}
