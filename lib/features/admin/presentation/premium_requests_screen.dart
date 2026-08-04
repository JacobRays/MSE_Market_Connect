import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/admin_premium_request_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum RequestFilter { pending, approved, rejected }

class PremiumRequestsScreen extends StatefulWidget {
  const PremiumRequestsScreen({super.key});

  @override
  State<PremiumRequestsScreen> createState() => _PremiumRequestsScreenState();
}

class _PremiumRequestsScreenState extends State<PremiumRequestsScreen> {
  final _service = AdminPremiumRequestService();
  RequestFilter _filter = RequestFilter.pending;

  late Future<List<AdminPremiumRequestView>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminPremiumRequestView>> _load() {
    final status = switch (_filter) {
      RequestFilter.pending => 'pending',
      RequestFilter.approved => 'approved',
      RequestFilter.rejected => 'rejected',
    };
    return _service.getRequestsByStatus(status);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openReceipt(
    AdminPremiumRequestView x, {
    required ScaffoldMessengerState messenger,
  }) async {
    try {
      final url = await _service.getSignedReceiptUrl(x.request.receiptPath);
      await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to open receipt: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium Requests')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<RequestFilter>(
              segments: const [
                ButtonSegment(
                  value: RequestFilter.pending,
                  label: Text('Pending'),
                ),
                ButtonSegment(
                  value: RequestFilter.approved,
                  label: Text('Approved'),
                ),
                ButtonSegment(
                  value: RequestFilter.rejected,
                  label: Text('Rejected'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (set) {
                setState(() {
                  _filter = set.first;
                  _future = _load();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
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
                      children: [
                        Text('Failed to load requests.\n${snapshot.error}'),
                      ],
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 40),
                        Center(child: Text('No ${_filter.name} requests.')),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final x = items[index];
                      final p = x.profile;

                      final email = p?.email ?? x.request.userId;
                      final name = (p?.fullName?.trim().isNotEmpty ?? false)
                          ? p!.fullName!
                          : null;
                      final phone = (p?.phone?.trim().isNotEmpty ?? false)
                          ? p!.phone!
                          : null;

                      return Card(
                        child: ListTile(
                          title: Text(email),
                          subtitle: Text(
                            'MWK ${x.request.amount.toStringAsFixed(0)} • ${x.request.paymentMethod ?? 'method —'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final note = TextEditingController(
                              text: x.request.adminNote ?? '',
                            );

                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => Padding(
                                padding: EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 16,
                                  bottom:
                                      16 +
                                      MediaQuery.of(context).viewInsets.bottom,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      email,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    if (name != null) ...[
                                      const SizedBox(height: 4),
                                      Text('Name: $name'),
                                    ],
                                    if (phone != null) ...[
                                      const SizedBox(height: 4),
                                      Text('Phone: $phone'),
                                    ],
                                    const SizedBox(height: 10),
                                    Text(
                                      'Status: ${x.request.status.toUpperCase()}',
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 52,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openReceipt(
                                          x,
                                          messenger: messenger,
                                        ),
                                        icon: const Icon(Icons.receipt_long),
                                        label: const Text('View payment proof'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: note,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Admin note / rejection reason',
                                        hintText: 'Required when rejecting',
                                      ),
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 12),

                                    if (_filter == RequestFilter.pending) ...[
                                      SizedBox(
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            try {
                                              await _service.approveRequest(
                                                requestId: x.request.id,
                                                userId: x.request.userId,
                                                adminNote:
                                                    note.text.trim().isEmpty
                                                    ? null
                                                    : note.text.trim(),
                                                premiumDays: 30,
                                              );
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text('Approved'),
                                                ),
                                              );
                                              await _refresh();
                                            } catch (e) {
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Approve failed: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text(
                                            'Approve (Premium 30 days)',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 52,
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            final reason = note.text.trim();
                                            if (reason.isEmpty) {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Rejection reason is required',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            Navigator.pop(context);
                                            try {
                                              await _service.rejectRequest(
                                                requestId: x.request.id,
                                                adminNote: reason,
                                              );
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text('Rejected'),
                                                ),
                                              );
                                              await _refresh();
                                            } catch (e) {
                                              if (!mounted) return;
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Reject failed: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text(
                                            'Reject (with reason)',
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
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
          ),
        ],
      ),
    );
  }
}
