import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/admin_ad_service.dart';
import 'package:mse_market_connect/features/admin/presentation/ad_editor_screen.dart';
import 'package:mse_market_connect/shared/models/ad_model.dart';

class ManageAdsScreen extends StatefulWidget {
  const ManageAdsScreen({super.key});

  @override
  State<ManageAdsScreen> createState() => _ManageAdsScreenState();
}

class _ManageAdsScreenState extends State<ManageAdsScreen> {
  final _service = AdminAdService();
  late Future<List<AdModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllAds();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.getAllAds());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Adverts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdEditorScreen()),
          );
          if (!mounted) return;
          await _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [Text('Failed to load ads.\n${snapshot.error}')],
              );
            }

            final ads = snapshot.data ?? [];
            if (ads.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 50),
                  Center(child: Text('No adverts yet. Tap + to create one.')),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: ads.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ad = ads[index];
                return Card(
                  child: ListTile(
                    title: Text(ad.title),
                    subtitle: Text(
                      'Priority: ${ad.priority}  •  ${ad.isActive ? "Active" : "Inactive"}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AdEditorScreen(existing: ad)),
                      );
                      if (!mounted) return;
                      await _refresh();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
