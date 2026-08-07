import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('1. Acceptance of Terms'),
            _body(
              'By downloading, installing, or using MSE Market Connect ("the App"), '
              'you agree to be bound by these Terms of Service. If you do not agree '
              'to these terms, please do not use the App.',
            ),
            _sectionTitle('2. Description of Service'),
            _body(
              'MSE Market Connect provides a platform for accessing Malawi Stock '
              'Exchange (MSE) market data, news, portfolio management, and trading '
              'facilitation services. The App does not provide investment advice; '
              'all trading decisions are made solely by you.',
            ),
            _sectionTitle('3. User Accounts'),
            _body(
              '• You must provide accurate and complete registration information.\n'
              '• You are responsible for maintaining the confidentiality of your '
              'login credentials.\n'
              '• You must be at least 18 years old to use the App.\n'
              '• We reserve the right to suspend or terminate accounts that violate '
              'these terms.',
            ),
            _sectionTitle('4. Fees and Payments'),
            _body(
              'Some features require a paid subscription. You agree to pay all fees '
              'as described at the time of purchase. All payments are non‑refundable '
              'unless required by applicable law.',
            ),
            _sectionTitle('5. Limitation of Liability'),
            _body(
              'MSE Market Connect and its affiliates shall not be liable for any '
              'direct, indirect, incidental, or consequential damages arising from '
              'your use of the App, including but not limited to financial losses '
              'due to trading decisions, data inaccuracies, or service interruptions.',
            ),
            _sectionTitle('6. Intellectual Property'),
            _body(
              'All content, trademarks, and intellectual property within the App '
              'are owned by or licensed to MSE Market Connect. You may not reproduce, '
              'distribute, or create derivative works without our prior written consent.',
            ),
            _sectionTitle('7. Termination'),
            _body(
              'We may terminate or suspend your account at any time, without prior '
              'notice, for conduct that we believe violates these Terms or is harmful '
              'to other users, us, or third parties.',
            ),
            _sectionTitle('8. Governing Law'),
            _body(
              'These Terms shall be governed by and construed in accordance with the '
              'laws of Malawi. Any disputes arising from these terms shall be resolved '
              'in the courts of Malawi.',
            ),
            _sectionTitle('9. Changes to Terms'),
            _body(
              'We reserve the right to modify these Terms at any time. Changes will '
              'be effective immediately upon posting. Continued use of the App after '
              'changes constitutes acceptance of the new Terms.',
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
