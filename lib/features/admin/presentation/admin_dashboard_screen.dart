import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/mse_sync_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _syncService = MseSyncService();
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      final sCount = await _syncService.syncPrices();
      final nCount = await _syncService.syncNews();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync Successful: $sCount stocks, $nCount news updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e')));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blue.shade50,
            child: ListTile(
              leading: _isSyncing 
                ? const CircularProgressIndicator() 
                : const Icon(Icons.sync, color: Colors.blue),
              title: const Text('Sync with MSE Website', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Fetch live prices and news from mse.co.mw'),
              onTap: _isSyncing ? null : _handleSync,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const ListTile(
            title: Text('App Management'),
            subtitle: Text('Manage Ads, User KYC, and Broker Requests'),
          ),
          // Add your other admin tiles here...
        ],
      ),
    );
  }
}
