import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/support_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _service = SupportService();
  final _subject = TextEditingController();
  final _message = TextEditingController();

  bool _submitting = false;
  String? _deletingId;
  late Future<List<Map<String, dynamic>>> _ticketsFuture;

  final List<Map<String, String>> _faqs = const [
    {
      'q': 'What are MSE trading hours?',
      'a': 'Trading happens Monday to Friday from 9:00 AM to 3:00 PM.',
    },
    {
      'q': 'How long does settlement take?',
      'a': 'Standard MSE settlement is T+3 (3 business days after trade).',
    },
    {
      'q': 'What are the fees?',
      'a':
          'Fees depend on your broker. Check the Broker list for indicative rates.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _service.getMyTickets();
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _reloadTickets() async {
    setState(() => _ticketsFuture = _service.getMyTickets());
    await _ticketsFuture;
  }

  Future<void> _send() async {
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.isEmpty || message.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await _service.submitTicket(subject, message);
      if (!mounted) return;

      _subject.clear();
      _message.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ticket sent to support')));

      // fire-and-forget refresh
      // ignore: discarded_futures
      _reloadTickets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending ticket: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDeleteTicket(String id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete ticket?'),
            content: const Text('This will remove the ticket from your list.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    setState(() => _deletingId = id);
    try {
      await _service.deleteTicket(id);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ticket deleted')));
      await _reloadTickets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting ticket: $e')));
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  String _formatWhen(BuildContext context, String createdAt) {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return createdAt;

    final loc = MaterialLocalizations.of(context);
    final date = loc.formatShortDate(dt);
    final time = loc.formatTimeOfDay(TimeOfDay.fromDateTime(dt));
    return '$date • $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: RefreshIndicator(
        onRefresh: _reloadTickets,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'MY TICKETS',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _ticketsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Failed to load tickets:\n${snapshot.error}'),
                    ),
                  );
                }

                final tickets = snapshot.data ?? [];
                if (tickets.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No tickets yet.\nIf you need help, create one below.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                return Column(
                  children: tickets.map((t) {
                    final id = (t['id'] ?? '').toString();
                    final subject = (t['subject'] ?? '').toString();
                    final status = (t['status'] ?? 'open').toString();
                    final createdAt = (t['created_at'] ?? '').toString();
                    final message = (t['message'] ?? '').toString();

                    return Card(
                      child: ExpansionTile(
                        title: Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${status.toUpperCase()} • ${_formatWhen(context, createdAt)}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(message),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: id.isEmpty || _deletingId == id
                                  ? null
                                  : () => _confirmDeleteTicket(id),
                              icon: _deletingId == id
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline, size: 18),
                              label: const Text(
                                'Delete',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 22),

            Text(
              'FAQ',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ..._faqs.map(
              (f) => Card(
                child: ExpansionTile(
                  title: Text(
                    f['q']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(f['a']!),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),
            Text(
              'CONTACT SUPPORT',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _subject,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _message,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Message'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _send,
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send Ticket'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Email: support@premiumrays.mw',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
