import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';

class QuickActionsScreen extends StatelessWidget {
  final List<QuickActionItem> actions;

  const QuickActionsScreen({super.key, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Actions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _QuickActionsGrid(actions: actions),
      ),
    );
  }
}

class QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _QuickActionsGrid extends StatelessWidget {
  final List<QuickActionItem> actions;
  const _QuickActionsGrid({this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final crossAxisCount = c.maxWidth < 360 ? 3 : 4;

        return GridView.builder(
          itemCount: actions.length,
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
    final bg = AppTheme.primaryColor.withValues(alpha: 0.08);
    final border = AppTheme.primaryColor.withValues(alpha: 0.14);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // FLOATING CIRCLE WITH SHADOW
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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
