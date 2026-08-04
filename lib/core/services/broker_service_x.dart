import 'package:mse_market_connect/core/services/broker_service.dart';
import 'package:mse_market_connect/shared/models/broker_model.dart';

extension BrokerServiceX on BrokerService {
  // Stronger dedupe: by id, normalized name (no corp suffix), or website/email domain.
  Future<List<BrokerModel>> getActiveBrokersUnique() async {
    final raw = await getActiveBrokers();

    final seenIds = <String>{};
    final seenNames = <String>{};
    final seenDomains = <String>{};
    final out = <BrokerModel>[];

    for (final b in raw) {
      final idKey = (b.id).toString().trim();
      final nameKey = _normName(b.name);
      final domainKey = _bestDomain(b);

      final isDup =
          (idKey.isNotEmpty && seenIds.contains(idKey)) ||
          (nameKey.isNotEmpty && seenNames.contains(nameKey)) ||
          (domainKey != null && seenDomains.contains(domainKey));

      if (!isDup) {
        out.add(b);
        if (idKey.isNotEmpty) seenIds.add(idKey);
        if (nameKey.isNotEmpty) seenNames.add(nameKey);
        if (domainKey != null) seenDomains.add(domainKey);
      }
    }

    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (raw.length != out.length) {
      // ignore: avoid_print
      print(
        'BrokerServiceX: removed ${raw.length - out.length} duplicate broker(s) (by id/name/domain).',
      );
    }
    return out;
  }

  String _normName(String s) {
    var n = s.trim().toLowerCase();
    // remove punctuation
    n = n.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    // expand common abbreviations first
    n = n.replaceAll(RegExp(r'\bltd\b'), 'limited');
    n = n.replaceAll(RegExp(r'\bco\b'), 'company');
    // remove corporate suffix words anywhere (esp. trailing)
    n = n.replaceAll(
      RegExp(r'\b(limited|plc|inc|corp|corporation|company|holdings?|group)\b'),
      '',
    );
    // collapse whitespace
    n = n.replaceAll(RegExp(r'\s+'), ' ').trim();
    return n;
  }

  String? _bestDomain(BrokerModel b) {
    final cands = <String?>[
      _extractDomainFromUrl(b.website),
      _extractDomainFromEmail(b.email),
      _extractDomainFromEmail(b.altEmail),
    ];
    for (final d in cands) {
      if (d != null && d.isNotEmpty) return d;
    }
    return null;
  }

  String? _extractDomainFromEmail(String? email) {
    if (email == null) return null;
    final e = email.trim().toLowerCase();
    if (e.isEmpty || !e.contains('@')) return null;
    final dom = e.split('@').last.replaceAll(RegExp(r'[^a-z0-9\.\-]'), '');
    return dom.isEmpty ? null : dom;
  }

  String? _extractDomainFromUrl(String? url) {
    if (url == null) return null;
    var u = url.trim();
    if (u.isEmpty) return null;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    try {
      final host = Uri.parse(u).host.toLowerCase();
      return host.isEmpty ? null : host;
    } catch (_) {
      return null;
    }
  }
}
