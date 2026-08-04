import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';

class CompanyLogo extends StatelessWidget {
  final String symbol;
  final String? logoUrl;
  final double size;

  const CompanyLogo({
    super.key,
    required this.symbol,
    required this.logoUrl,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final url = (logoUrl ?? '').trim();
    final letter = symbol.isNotEmpty ? symbol[0].toUpperCase() : '?';

    if (url.isEmpty) return _fallback(letter);

    return ClipOval(
      child: Container(
        height: size,
        width: size,
        color: Colors.white,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(letter),
        ),
      ),
    );
  }

  Widget _fallback(String letter) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryColor.withValues(alpha: 0.10),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
