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

  final List<Map<String, String>> _faqs = [
    {'q': 'What are MSE trading hours?', 'a': 'Trading happens Monday to Friday from 9:00 AM to 3:00 PM.'},
    {'q': 'How long does settlement take?', 'a': 'Standard MSE settlement is T+3 (3 business days after trade).'},
    {'q': 'What are the fees?', 'a': 'The standard brokerage fee is approximately 2% of the trade value.'},
  ];

  Future<void> _send() async {
    if (_subject.text.isEmpty || _message.text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await _service.submitTicket(_subject.text, _message.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent to support!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          ..._faqs.map((f) => ExpansionTile(
            title: Text(f['q']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            children: [Padding(padding: const EdgeInsets.all(16), child: Text(f['a']!))],
          )),
          const SizedBox(height: 32),
          const Text('CONTACT US', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject')),
                  const SizedBox(height: 12),
                  TextField(controller: _message, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _send,
                      child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Message'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: Text('Email: support@premiumrays.mw', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}
