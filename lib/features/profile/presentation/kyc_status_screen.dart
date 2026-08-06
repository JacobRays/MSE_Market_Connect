import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';

class KycStatusScreen extends StatelessWidget {
  final String kycStatus;
  const KycStatusScreen({super.key, required this.kycStatus});

  Color _statusColor() {
    switch (kycStatus.toLowerCase()) {
      case 'approved':
        return AppTheme.gainColor;
      case 'rejected':
        return AppTheme.lossColor;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Status')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              kycStatus == 'approved'
                  ? Icons.verified
                  : kycStatus == 'rejected'
                      ? Icons.cancel
                      : Icons.pending,
              size: 80,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              'KYC ${kycStatus.toUpperCase()}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              kycStatus == 'approved'
                  ? 'Your identity has been verified.'
                  : kycStatus == 'rejected'
                      ? 'Your verification was rejected. Please contact support.'
                      : 'Your KYC is under review. We will notify you once verified.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (kycStatus == 'pending')
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Documents'),
                onPressed: () {
                  // TODO: implement document upload
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document upload coming soon')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
