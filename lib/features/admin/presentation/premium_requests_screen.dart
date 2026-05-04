import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/admin_premium_request_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumRequestsScreen extends StatefulWidget {
  const PremiumRequestsScreen({super.key});

  @override
  State<PremiumRequestsScreen> createState() => _PremiumRequestsScreenState();
}

class _PremiumRequestsScreenState extends State<PremiumRequestsScreen> {
  final _service = AdminPremiumRequestService();
  late Future<List<AdminPremiumRequestView>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getPendingRequests();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.getPendingRequests());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Requests')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AdminPremiumRequestView>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [Text('Failed to load requests.\n${snapshot.error}')],
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 40),
                  Center(child: Text('No pending premium requests.')),
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
                final email = x.profile?.email ?? x.request.userId;

                return Card(
                  child: ListTile(
                    title: Text(email),
                    subtitle: Text(
                      'MWK ${x.request.amount.toStringAsFixed(0)} • ${x.request.paymentMethod ?? 'method —'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final note = TextEditingController();

                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(email, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text('Request ID: ${x.request.id}'),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final url = await _service.getSignedReceiptUrl(
                                      x.request.receiptPath,
                                    );
                                    final uri = Uri.parse(url);
                                    await launchUrl(uri, mode: LaunchMode.platformDefault);
                                  },
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('View receipt'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: note,
                                decoration: const InputDecoration(
                                  labelText: 'Admin note (optional)',
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _service.approveRequest(
                                      requestId: x.request.id,
                                      userId: x.request.userId,
                                      adminNote: note.text.trim().isEmpty ? null : note.text.trim(),
                                      premiumDays: 30,
                                    );
                                    if (!mounted) return;
                                    await _refresh();
                                  },
                                  child: const Text('Approve (Premium 30 days)'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _service.rejectRequest(
                                      requestId: x.request.id,
                                      adminNote: note.text.trim().isEmpty ? null : note.text.trim(),
                                    );
                                    if (!mounted) return;
                                    await _refresh();
                                  },
                                  child: const Text('Reject'),
                                ),
                              ),
                            ],
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
