import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/admin_subscription_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';

class ManageSubscriptionsScreen extends StatefulWidget {
  const ManageSubscriptionsScreen({super.key});

  @override
  State<ManageSubscriptionsScreen> createState() =>
      _ManageSubscriptionsScreenState();
}

class _ManageSubscriptionsScreenState extends State<ManageSubscriptionsScreen> {
  final _service = AdminSubscriptionService();
  late Future<List<AdminUserSubscription>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminUserSubscription>> _load() async {
    final profiles = await _service.getAllProfiles();
    final userIds = profiles.map((p) => p.id).toList();
    final subsMap = await _service.getSubscriptionsByUserIds(userIds);

    return profiles.map((p) {
      return AdminUserSubscription(profile: p, subscription: subsMap[p.id]);
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _setPremium(String userId) async {
    await _service.setPremium(userId: userId, days: 30);
    await _refresh();
  }

  Future<void> _setFree(String userId) async {
    await _service.setFree(userId: userId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Upgrades')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminUserSubscription>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [Text('Failed to load users.\n${snapshot.error}')],
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 40),
                  Center(child: Text('No users found.')),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final x = items[index];

                final isPremium = x.isPremium;
                final chipColor = isPremium ? AppTheme.gainColor : Colors.grey;

                return Card(
                  child: ListTile(
                    title: Text(x.profile.email),
                    subtitle: Text('Plan: ${x.plan}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isPremium ? 'PREMIUM' : 'FREE',
                        style: TextStyle(
                          color: chipColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  x.profile.email,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await _setPremium(x.profile.id);
                                    },
                                    child: const Text('Set Premium (30 days)'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await _setFree(x.profile.id);
                                    },
                                    child: const Text('Set Free'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
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
