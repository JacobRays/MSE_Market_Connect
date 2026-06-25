import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrokerApprovalsScreen extends StatefulWidget {
  const BrokerApprovalsScreen({super.key});

  @override
  State<BrokerApprovalsScreen> createState() => _BrokerApprovalsScreenState();
}

class _BrokerApprovalsScreenState extends State<BrokerApprovalsScreen> {
  final _db = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    // Expected table: broker_users (user_id, broker_id, is_approved, created_at)
    // Join profile + broker to show names
    final res = await _db
        .from('broker_users')
        .select(
          'id, user_id, broker_id, is_approved, created_at, profiles(full_name,email,phone), brokers(name)',
        )
        .order('created_at', ascending: false);

    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _approve(Map<String, dynamic> row) async {
    final id = row['id'];
    final userId = row['user_id'];

    await _db.from('broker_users').update({'is_approved': true}).eq('id', id);

    // Optional: set user profile role to 'broker' when approved
    // If you prefer to keep role as investor and only use broker_users.is_approved, tell me and I’ll remove this.
    await _db.from('profiles').update({'role': 'broker'}).eq('id', userId);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Broker approved')));
    await _refresh();
  }

  Future<void> _reject(Map<String, dynamic> row) async {
    final id = row['id'];
    await _db.from('broker_users').delete().eq('id', id);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request rejected')));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broker Approvals')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [Text('Failed to load:\n${snap.error}')],
              );
            }

            final rows = (snap.data ?? []);
            final pending = rows
                .where((r) => r['is_approved'] != true)
                .toList();

            if (pending.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 40),
                  Center(child: Text('No pending broker requests.')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = pending[i];
                final p = (r['profiles'] as Map<String, dynamic>?) ?? {};
                final b = (r['brokers'] as Map<String, dynamic>?) ?? {};

                final fullName = (p['full_name'] ?? 'User').toString();
                final email = (p['email'] ?? '').toString();
                final phone = (p['phone'] ?? '').toString();
                final brokerName = (b['name'] ?? 'Broker').toString();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text('Broker: $brokerName'),
                        if (email.isNotEmpty) Text(email),
                        if (phone.isNotEmpty) Text(phone),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _reject(r),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _approve(r),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
