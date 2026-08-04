#!/usr/bin/env bash
set -Eeuo pipefail

FILE="lib/features/admin/presentation/admin_sync_prices_screen.dart"
[[ -f "$FILE" ]] || { echo "Missing: $FILE" >&2; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp -a "$FILE" "${FILE}.bak.${ts}"
echo "Backup: ${FILE}.bak.${ts}"

cat > "$FILE" << 'DART'
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/mse_price_sync_service.dart';
import 'package:mse_market_connect/core/services/price_sync_edge_service.dart';
import 'package:mse_market_connect/core/services/news_sync_service.dart';
import 'package:mse_market_connect/core/services/mse_sync_service.dart'; // web fallback (CORS-proxy)

class AdminSyncPricesScreen extends StatefulWidget {
  const AdminSyncPricesScreen({super.key});

  @override
  State<AdminSyncPricesScreen> createState() => _AdminSyncPricesScreenState();
}

class _AdminSyncPricesScreenState extends State<AdminSyncPricesScreen> {
  final _prices = MsePriceSyncService();      // mobile native scraper
  final _edge = PriceSyncEdgeService();       // web: edge function
  final _news = NewsSyncService();

  bool _syncingPrices = false;
  bool _syncingNews = false;

  Future<void> _syncPrices() async {
    setState(() => _syncingPrices = true);
    try {
      final int count;
      if (kIsWeb) {
        // Preferred: Edge Function (server-side scrape)
        try {
          count = await _edge.syncNow();
        } catch (e) {
          // Fallback: client-side CORS-proxy scraper (may be blocked, but we try once)
          final alt = MseSyncService();
          final altCount = await alt.syncPrices();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Edge failed; fallback used. Updated $altCount. Err: $e')),
          );
          setState(() => _syncingPrices = false);
          return;
        }
      } else {
        // Android/iOS
        count = await _prices.syncMainboardPrices();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prices synced: $count stocks updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Price sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncingPrices = false);
    }
  }

  Future<void> _syncNews() async {
    setState(() => _syncingNews = true);
    try {
      final count = await _news.syncBusinessNews();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('News synced: $count articles added/updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('News sync failed: $e')));
    } finally {
      if (mounted) setState(() => _syncingNews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (kIsWeb)
            Card(
              color: Colors.green.withOpacity(0.12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Web sync uses a Supabase Edge Function.\n'
                  'Click Sync to fetch prices now.',
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: _syncingPrices
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              title: const Text('Sync MSE Prices'),
              subtitle: const Text('Update stocks from MSE mainboard'),
              onTap: _syncingPrices ? null : _syncPrices,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: _syncingNews
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.newspaper_outlined),
              title: const Text('Sync Business News'),
              subtitle: const Text('Fetch latest business news (GDELT)'),
              onTap: _syncingNews ? null : _syncNews,
            ),
          ),
        ],
      ),
    );
  }
}
DART

echo "Patched: $FILE"
