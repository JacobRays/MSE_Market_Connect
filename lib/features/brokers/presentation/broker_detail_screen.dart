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

  Uri? _safeUri(String? url) {
    final u = (url ?? '').trim();
    if (u.isEmpty) return null;
    if (u.startsWith('http://') || u.startsWith('https://'))
      return Uri.parse(u);
    return Uri.parse('https://$u');
  }

  Future<void> _open(
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
    final altPhone = (broker.altPhone ?? '').trim();
    final email = (broker.email ?? '').trim();
    final altEmail = (broker.altEmail ?? '').trim();
    final websiteUri = _safeUri(broker.website);
    final address = (broker.address ?? '').trim();
    final whatsappDigits = (broker.whatsapp ?? '')
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();

    final waUri = whatsappDigits.isEmpty
        ? null
        : Uri.parse(
            'https://wa.me/$whatsappDigits?text=${Uri.encodeComponent('Hello ${broker.name}, I found you on MSE Market Connect.')}',
          );

    final mapsUri = address.isEmpty
        ? null
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
          );

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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        label:
                            'Fee ${(broker.feeRate * 100).toStringAsFixed(2)}%',
                      ),
                      _Chip(label: broker.isActive ? 'Active' : 'Inactive'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Connect',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.call_outlined),
                  title: const Text('Call'),
                  subtitle: Text(phone.isEmpty ? 'Not provided' : phone),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: phone.isEmpty
                      ? null
                      : () => _open(
                          context,
                          Uri.parse('tel:$phone'),
                          fallbackCopy: phone,
                          label: 'Phone',
                        ),
                  onLongPress: phone.isEmpty
                      ? null
                      : () => _copy(context, phone, 'Phone'),
                ),
                if (altPhone.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.call_outlined),
                    title: const Text('Alt phone'),
                    subtitle: Text(altPhone),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _open(
                      context,
                      Uri.parse('tel:$altPhone'),
                      fallbackCopy: altPhone,
                      label: 'Alt phone',
                    ),
                    onLongPress: () => _copy(context, altPhone, 'Alt phone'),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('WhatsApp'),
                  subtitle: Text(
                    whatsappDigits.isEmpty ? 'Not provided' : whatsappDigits,
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: waUri == null
                      ? null
                      : () => _open(
                          context,
                          waUri!,
                          fallbackCopy: whatsappDigits,
                          label: 'WhatsApp',
                        ),
                  onLongPress: whatsappDigits.isEmpty
                      ? null
                      : () => _copy(context, whatsappDigits, 'WhatsApp'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(email.isEmpty ? 'Not provided' : email),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: email.isEmpty
                      ? null
                      : () => _open(
                          context,
                          Uri.parse('mailto:$email'),
                          fallbackCopy: email,
                          label: 'Email',
                        ),
                  onLongPress: email.isEmpty
                      ? null
                      : () => _copy(context, email, 'Email'),
                ),
                if (altEmail.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Alt email'),
                    subtitle: Text(altEmail),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _open(
                      context,
                      Uri.parse('mailto:$altEmail'),
                      fallbackCopy: altEmail,
                      label: 'Alt email',
                    ),
                    onLongPress: () => _copy(context, altEmail, 'Alt email'),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Website'),
                  subtitle: Text(
                    websiteUri == null ? 'Not provided' : websiteUri.toString(),
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: websiteUri == null
                      ? null
                      : () => _open(
                          context,
                          websiteUri!,
                          fallbackCopy: websiteUri.toString(),
                          label: 'Website',
                        ),
                ),
              ],
            ),
          ),

          if (address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Address',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(address),
                trailing: mapsUri == null
                    ? null
                    : const Icon(Icons.open_in_new),
                onTap: mapsUri == null
                    ? null
                    : () => _open(
                        context,
                        mapsUri!,
                        fallbackCopy: address,
                        label: 'Address',
                      ),
                onLongPress: () => _copy(context, address, 'Address'),
              ),
            ),
          ],

          if ((broker.bankInstructions ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(broker.bankInstructions!.trim()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
