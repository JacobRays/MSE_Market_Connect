import 'package:flutter/material.dart';
import 'package:mse_market_connect/features/admin/presentation/admin_sync_prices_screen.dart';
import 'package:mse_market_connect/features/admin/presentation/broker_approvals_screen.dart';
import 'package:mse_market_connect/features/admin/presentation/manage_ads_screen.dart';
import 'package:mse_market_connect/features/admin/presentation/manage_subscriptions_screen.dart';
import 'package:mse_market_connect/features/admin/presentation/premium_requests_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- LIVE DATA ---
          const Text(
            'LIVE DATA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync with MSE Website'),
              subtitle: const Text('Fetch live prices and news'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminSyncPricesScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- APP MANAGEMENT ---
          const Text(
            'APP MANAGEMENT',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Manage Adverts'),
              subtitle: const Text('Add, edit, remove banners'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageAdsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.card_membership_outlined),
              title: const Text('Manage Subscriptions'),
              subtitle: const Text('View and manage user plans'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageSubscriptionsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Premium Requests'),
              subtitle: const Text('Approve premium upgrades'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PremiumRequestsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- BROKER MANAGEMENT ---
          const Text(
            'BROKER MANAGEMENT',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Approve Brokers'),
              subtitle: const Text('Review broker registrations'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BrokerApprovalsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
