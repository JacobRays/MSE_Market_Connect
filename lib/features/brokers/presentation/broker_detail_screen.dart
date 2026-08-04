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
    if (u.startsWith('http://') || u.startsWith('https://')) {
      return Uri.parse(u);
    }
    return Uri.parse('https://$u');
  }

  List<String> _splitList(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return const [];
    return s
        .split(RegExp(r'[,/]|(\s{2,})'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  // Key by last 9 digits (Malawi local number) to dedupe variants like "+265 999 123 456" vs "0999 123 456"
  String _mwPhoneKey(String s) {
    final d = _digitsOnly(s);
    if (d.isEmpty) return '';
    return d.length >= 9 ? d.substring(d.length - 9) : d;
  }

  // Normalize to E.164 (+265 + last 9 digits)
  String _toE164Mw(String s) {
    final d = _digitsOnly(s);
    if (d.isEmpty) return '';
    final last9 = d.length >= 9 ? d.substring(d.length - 9) : d;
    return '+265$last9';
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
    // Phones (primary + alt), deduped
    final rawPhones = <String>[
      ..._splitList(broker.phone),
      ..._splitList(broker.altPhone),
    ];

    final seenPhoneKeys = <String>{};
    final phoneItems = <_PhoneItem>[];
    for (final p in rawPhones) {
      final key = _mwPhoneKey(p);
      if (key.isEmpty || !seenPhoneKeys.add(key)) continue;
      final e164 = _toE164Mw(p);
      if (e164.isEmpty) continue;
      phoneItems.add(_PhoneItem(display: p, tel: e164));
    }

    // Emails (primary + alt), case-insensitive dedupe
    final emails = <String>[
      ..._splitList(broker.email),
      ..._splitList(broker.altEmail),
    ];

    final emailSet = <String>{};
    final uniqueEmails = <String>[];
    for (final e in emails) {
      final key = e.toLowerCase();
      if (key.isEmpty || !emailSet.add(key)) continue;
      uniqueEmails.add(e);
    }

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

    // Build phone tiles with separators (no trailing divider)
    final phoneTiles = phoneItems
        .expand(
          (it) => [
            ListTile(
              leading: const Icon(Icons.call_outlined),
              title: const Text('Call'),
              subtitle: Text(it.display),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _open(
                context,
                Uri.parse('tel:${it.tel}'),
                fallbackCopy: it.tel,
                label: 'Phone',
              ),
              onLongPress: () => _copy(context, it.tel, 'Phone'),
            ),
            const Divider(height: 1),
          ],
        )
        .toList();
    if (phoneTiles.isNotEmpty) phoneTiles.removeLast();

    // Build email tiles with separators (no trailing divider)
    final emailTiles = uniqueEmails
        .expand(
          (e) => [
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(e),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _open(
                context,
                Uri.parse('mailto:$e'),
                fallbackCopy: e,
                label: 'Email',
              ),
              onLongPress: () => _copy(context, e, 'Email'),
            ),
            const Divider(height: 1),
          ],
        )
        .toList();
    if (emailTiles.isNotEmpty) emailTiles.removeLast();

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
                if (phoneItems.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.call_outlined),
                    title: Text('Call'),
                    subtitle: Text('Not provided'),
                  )
                else
                  ...phoneTiles,

                const Divider(height: 1),

                // WhatsApp
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
                          waUri,
                          fallbackCopy: whatsappDigits,
                          label: 'WhatsApp',
                        ),
                  onLongPress: whatsappDigits.isEmpty
                      ? null
                      : () => _copy(context, whatsappDigits, 'WhatsApp'),
                ),

                const Divider(height: 1),

                // Emails (primary + alts)
                if (uniqueEmails.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.email_outlined),
                    title: Text('Email'),
                    subtitle: Text('Not provided'),
                  )
                else
                  ...emailTiles,

                const Divider(height: 1),

                // Website
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
                          websiteUri,
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
                        mapsUri,
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

class _PhoneItem {
  final String display; // as provided (nice to show)
  final String tel; // normalized E.164 for dialing/copying
  const _PhoneItem({required this.display, required this.tel});
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
