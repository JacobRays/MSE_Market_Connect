import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('1. Introduction'),
            _body(
              'MSE Market Connect ("we", "our", or "us") is committed to protecting '
              'your privacy. This Privacy Policy explains how we collect, use, '
              'disclose, and safeguard your information when you use our mobile '
              'application and services.',
            ),
            _sectionTitle('2. Information We Collect'),
            _body(
              '• Personal Data: name, email address, phone number, and identity '
              'verification documents you provide during KYC.\n'
              '• Usage Data: device information, IP address, app usage statistics, '
              'and transaction history.\n'
              '• Financial Data: portfolio holdings, trade orders, and subscription '
              'details.',
            ),
            _sectionTitle('3. How We Use Your Information'),
            _body(
              'We use the collected data to:\n'
              '• Provide, operate, and maintain our services.\n'
              '• Process transactions and send related notifications.\n'
              '• Verify your identity and comply with legal obligations.\n'
              '• Improve user experience and develop new features.\n'
              '• Communicate with you about updates, offers, and promotions.',
            ),
            _sectionTitle('4. Data Sharing'),
            _body(
              'We do not sell your personal information. We may share data with:\n'
              '• Service providers who assist us in operating the app.\n'
              '• Regulatory authorities when required by law.\n'
              '• Third parties only with your explicit consent.',
            ),
            _sectionTitle('5. Data Security'),
            _body(
              'We implement industry‑standard security measures (encryption, '
              'access controls, regular audits) to protect your data. However, '
              'no method of transmission over the Internet is 100% secure.',
            ),
            _sectionTitle('6. Your Rights'),
            _body(
              'You have the right to:\n'
              '• Access, update, or delete your personal information.\n'
              '• Withdraw consent at any time.\n'
              '• Request a copy of your data in a portable format.\n'
              '• Object to processing of your data.\n'
              'To exercise these rights, contact us at support@msemarketconnect.mw.',
            ),
            _sectionTitle('7. Changes to This Policy'),
            _body(
              'We may update this Privacy Policy from time to time. We will notify '
              'you of any changes by posting the new policy on this page and '
              'updating the "Last updated" date below.',
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: January 2025',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _body(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        color: Colors.black87,
      ),
    );
  }
}
