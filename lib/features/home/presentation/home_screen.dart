import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/learning/presentation/learning_screen.dart';
import 'package:mse_market_connect/features/market/presentation/market_screen.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/trade/presentation/my_orders_screen.dart';

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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MarketScreen()),
        ),
      ),
      _QuickActionData(
        icon: Icons.receipt_long_rounded,
        label: 'My Orders',
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
        ),
      ),
      _QuickActionData(
        icon: Icons.notifications_active_rounded,
        label: 'Alerts',
        gradient: const LinearGradient(
          colors: [Color(0xFFF9A825), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyAlertsScreen()),
        ),
      ),
      _QuickActionData(
        icon: Icons.school_rounded,
        label: 'Learn',
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LearningScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MSE Market Connect')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Track MSE prices, set alerts, and submit broker-routed order requests.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Use Alerts to set target prices and get notified when the price hits your level.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            GridView.builder(
              itemCount: actions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final item = actions[index];
                return _QuickAction3DCard(item: item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionData({
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
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.item.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF3F6FB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                // bottom shadow (depth)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                // top highlight (3D)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9),
                  blurRadius: 10,
                  offset: const Offset(-6, -6),
                ),
              ],
              border: Border.all(color: const Color(0xFFE6EDF7)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3D icon bubble
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: widget.item.gradient,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: Colors.white,
                      size: 26,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.item.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to open',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
