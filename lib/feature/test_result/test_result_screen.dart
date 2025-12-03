import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models.dart';
import '../common/widgets/widgets.dart';

class TestResultScreen extends StatelessWidget {
  const TestResultScreen({
    super.key,
    required this.result,
    required this.test,
    required this.answers,
    this.autoSubmitted = false,
  });

  final TestResult result;
  final TestOption test;
  final Map<int, int> answers;
  final bool autoSubmitted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (autoSubmitted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Время вышло, попытка отправлена автоматически.',
                  style: TextStyle(color: Color(0xFF92400E)),
                ),
              ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Tag('${result.correct}/${result.totalQuestions} верно'),
                      const SizedBox(width: 8),
                      Tag('${result.scorePercent.toStringAsFixed(0)}%'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ответили: ${result.answered} из ${result.totalQuestions}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Время: ${_formatTime(result.durationSpentSeconds)}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Try to leave the results flow; pop to root first, then request app exit.
                  final navigator = Navigator.of(context);
                  navigator.popUntil((route) => route.isFirst);
                  SystemNavigator.pop();
                },
                child: const Text('На главную'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
