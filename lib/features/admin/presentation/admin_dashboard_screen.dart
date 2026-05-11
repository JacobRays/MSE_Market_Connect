import 'package:flutter/material.dart';
import 'package:mse_market_connect/features/admin/presentation/manage_ads_screen.dart';
import 'package:mse_market_connect/features/admin/presentation/premium_requests_screen.dart';
import 'package:mse_market_connect/features/admin/presentation/manage_subscriptions_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: const Text('Premium Requests (Proof Uploads)'),
              subtitle: const Text('Review receipt, approve or reject with reason'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumRequestsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Manage Adverts'),
              subtitle: const Text('Create / activate / deactivate adverts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageAdsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Premium Plans (Advanced)'),
              subtitle: const Text('Manually set plans (use only if needed)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageSubscriptionsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Normal flow: user uploads proof → admin approves/rejects in Premium Requests.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
