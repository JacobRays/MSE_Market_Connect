import 'package:flutter/material.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lessons = [
      'What is the Malawi Stock Exchange?',
      'How to buy shares step by step',
      'Understanding dividends',
      'How to reduce investment risk',
      'Difference between trading and investing',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Hub'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: lessons.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.menu_book),
                title: Text(lessons[index]),
                subtitle: const Text('Tap to read more'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          },
        ),
      ),
    );
  }
}
