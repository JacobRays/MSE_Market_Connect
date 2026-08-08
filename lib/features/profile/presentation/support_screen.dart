import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/support_service.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';

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

  final List<Map<String, dynamic>> _faqs = const [
    {
      'q': 'What are MSE trading hours?',
      'a': 'Trading happens Monday–Friday from 9:00 AM to 3:00 PM.',
      'icon': Icons.access_time,
    },
    {
      'q': 'How long does settlement take?',
      'a': 'Standard MSE settlement is T+3 (3 business days after trade).',
      'icon': Icons.timer,
    },
    {
      'q': 'What are the fees?',
      'a': 'Fees depend on your broker. Check the Broker list for indicative rates.',
      'icon': Icons.monetization_on,
    },
    {
      'q': 'How do I reset my password?',
      'a': 'Go to Profile → Change Password. Enter your old and new password.',
      'icon': Icons.lock,
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket sent successfully')),
      );
      _reloadTickets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending ticket: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDeleteTicket(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ticket?'),
        content: const Text('This will remove the ticket from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _deletingId = id);
    try {
      await _service.deleteTicket(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket deleted')),
      );
      await _reloadTickets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting ticket: $e')),
      );
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    final loc = MaterialLocalizations.of(context);
    return '${loc.formatShortDate(dt)} • ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(dt))}';
  }

  Widget _statusBadge(String status) {
    final upper = status.toUpperCase();
    Color color;
    switch (status.toLowerCase()) {
      case 'open':
        color = Colors.orange;
        break;
      case 'closed':
        color = AppTheme.gainColor;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        upper,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
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
            // ─── Tickets Section ─────────────────
            _sectionTitle(context, 'MY TICKETS'),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _ticketsFuture,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snap.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Failed to load tickets:\n${snap.error}'),
                    ),
                  );
                }

                final tickets = snap.data ?? [];
                if (tickets.isEmpty) {
                  return Card(
                    color: Colors.grey[50],
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No tickets yet.\nCreate one below if you need help.'),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: tickets.map((t) {
                    final id = t['id']?.toString() ?? '';
                    final subject = t['subject']?.toString() ?? '';
                    final status = t['status']?.toString() ?? 'open';
                    final createdAt = t['created_at']?.toString() ?? '';
                    final message = t['message']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: const Icon(Icons.support_agent, color: AppTheme.primaryColor),
                        title: Text(subject, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Row(
                          children: [
                            _statusBadge(status),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDate(createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(message, style: const TextStyle(fontSize: 14)),
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
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Delete', style: TextStyle(fontSize: 13)),
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

            const SizedBox(height: 24),

            // ─── FAQ Section ─────────────────
            _sectionTitle(context, 'FAQ'),
            const SizedBox(height: 8),
            ..._faqs.map((f) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ExpansionTile(
                    leading: Icon(f['icon'] as IconData, color: AppTheme.primaryColor),
                    title: Text(f['q'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(f['a'] as String, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 24),

            // ─── Contact Support Form ─────────────────
            _sectionTitle(context, 'CONTACT SUPPORT'),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _subject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _message,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        prefixIcon: Icon(Icons.message),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _send,
                        icon: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        label: const Text('Send Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Contact Details ─────────────────
            _sectionTitle(context, 'REACH US'),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email, color: AppTheme.primaryColor),
                      title: const Text('Email'),
                      subtitle: const Text('support@premiumrays.mw'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone, color: AppTheme.primaryColor),
                      title: const Text('Phone'),
                      subtitle: const Text('+265 888 123 456'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                      title: const Text('Office'),
                      subtitle: const Text('Blantyre, Malawi'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
