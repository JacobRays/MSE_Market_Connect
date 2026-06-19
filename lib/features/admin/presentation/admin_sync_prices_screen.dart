import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/mse_price_sync_service.dart';

class AdminSyncPricesScreen extends StatefulWidget {
  const AdminSyncPricesScreen({super.key});

  @override
  State<AdminSyncPricesScreen> createState() => _AdminSyncPricesScreenState();
}

class _AdminSyncPricesScreenState extends State<AdminSyncPricesScreen> {
  final _svc = MsePriceSyncService();
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final count = await _svc.syncMainboardPrices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prices synced: $count stocks updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync MSE Prices (Admin)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: ListTile(
            leading: _syncing
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            title: const Text('Sync Mainboard Prices'),
            subtitle: const Text('Fetch from mse.co.mw/market/mainboard and update Supabase stocks'),
            onTap: _syncing ? null : _sync,
          ),
        ),
      ),
    );
  }
}
