import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';
import 'package:url_launcher/url_launcher.dart';

class BrokerDetailScreen extends StatelessWidget {
  final BrokerModel broker;
  const BrokerDetailScreen({super.key, required this.broker});

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  Future<void> _launchOrCopy(
    BuildContext context,
    Uri uri, {
    String? fallbackCopy,
    String? label,
  }) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && fallbackCopy != null && label != null) {
        await _copy(context, fallbackCopy, label);
      }
    } catch (_) {
      if (fallbackCopy != null && label != null) {
        await _copy(context, fallbackCopy, label);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = (broker.phone ?? '').trim();
    final email = (broker.email ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: Text(broker.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    broker.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fee rate: ${(broker.feeRate * 100).toStringAsFixed(2)}%',
                  ),
                  if ((broker.address ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Address',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(broker.address!.trim()),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.call_outlined),
                  title: const Text('Phone'),
                  subtitle: Text(phone.isEmpty ? 'Not provided' : phone),
                  trailing: phone.isEmpty
                      ? null
                      : const Icon(Icons.chevron_right),
                  onTap: phone.isEmpty
                      ? null
                      : () => _launchOrCopy(
                          context,
                          Uri.parse('tel:$phone'),
                          fallbackCopy: phone,
                          label: 'Phone',
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(email.isEmpty ? 'Not provided' : email),
                  trailing: email.isEmpty
                      ? null
                      : const Icon(Icons.chevron_right),
                  onTap: email.isEmpty
                      ? null
                      : () => _launchOrCopy(
                          context,
                          Uri.parse('mailto:$email'),
                          fallbackCopy: email,
                          label: 'Email',
                        ),
                ),
              ],
            ),
          ),

          if ((broker.bankInstructions ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bank Instructions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(broker.bankInstructions!.trim()),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
