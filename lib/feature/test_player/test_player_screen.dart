import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/state/app_state.dart';
import '../common/widgets/widgets.dart';
import '../test/data/answer_cache.dart';
import '../test_result/test_result_screen.dart';

class TestPlayerScreen extends StatefulWidget {
  const TestPlayerScreen({super.key, required this.test, required this.appState});

  final TestOption test;
  final AppState appState;

  @override
  State<TestPlayerScreen> createState() => _TestPlayerScreenState();
}

class _TestPlayerScreenState extends State<TestPlayerScreen> {
  late final PageController _pageController;
  late TestOption _test;
  int _currentIndex = 0;
  final Map<int, int> _answers = {};
  Timer? _timer;
  late int _remainingSeconds;
  bool _submitting = false;
  AnswerCache? _cache;

  @override
  void initState() {
    super.initState();
    _test = widget.test;
    _pageController = PageController();
    _remainingSeconds = (_test.durationMinutes <= 0 ? 60 : _test.durationMinutes) * 60;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _cache = await AnswerCache.create();
    // Ensure we have full test detail with full question list.
    final needsDetail =
        _test.questions.isEmpty || (_test.questionCount > _test.questions.length && _test.questionCount > 0);
    if (needsDetail) {
      try {
        final detailed = await widget.appState.loadTestDetail(_test.id);
        if (!mounted) return;
        setState(() => _test = detailed);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить тест')),
        );
      }
    }
    final saved = await _cache!.load(_test.id);
    if (saved.isNotEmpty) {
      if (!mounted) return;
      setState(() => _answers.addAll(saved));
    }
    _startTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _finish(auto: true);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _selectOption(Question question, int optionIndex) async {
    setState(() => _answers[question.id] = optionIndex);
    if (_cache != null) {
      await _cache!.save(_test.id, _answers);
    }
  }

  Future<void> _finish({bool auto = false}) async {
    if (!auto) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Завершить тест?'),
          content: const Text('Вы уверены, что хотите завершить попытку?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Продолжить'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Завершить'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();

    final attempt = TestAttempt(
      testId: _test.id,
      durationSeconds: (_test.durationMinutes * 60 - _remainingSeconds).clamp(0, 999999),
      totalQuestions: _test.questionCount > 0 ? _test.questionCount : _test.questions.length,
      answers: _answers.entries.map((e) {
        final question =
            _test.questions.firstWhere((q) => q.id == e.key, orElse: () => _test.questions.first);
        final choiceId = (question.choiceIds.length > e.value) ? question.choiceIds[e.value] : null;
        return AttemptAnswer(questionId: e.key, optionIndex: e.value, choiceId: choiceId);
      }).toList(),
      profile: widget.appState.profile,
    );

    TestResult result;
    try {
      result = await widget.appState.repository.submitAttempt(attempt);
    } catch (_) {
      result = _localResult(attempt);
    }

    if (_cache != null) {
      await _cache!.clear(_test.id);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TestResultScreen(
          result: result,
          test: _test,
          answers: _answers,
          autoSubmitted: auto,
        ),
      ),
    );
  }

  TestResult _localResult(TestAttempt attempt) {
    if (_test.questions.isEmpty) {
      return TestResult(
        testId: attempt.testId,
        totalQuestions: attempt.answers.length,
        answered: attempt.answers.length,
        correct: 0,
        scorePercent: 0,
        durationSpentSeconds: attempt.durationSeconds,
      );
    }
    final correct = attempt.answers.where((ans) {
      final question =
          _test.questions.firstWhere((q) => q.id == ans.questionId, orElse: () => _test.questions.first);
      return question.correctOption != null && question.correctOption == ans.optionIndex;
    }).length;
    final total = _test.questions.length;
    final percent = total == 0 ? 0.0 : (correct / total) * 100.0;
    return TestResult(
      testId: attempt.testId,
      totalQuestions: total,
      answered: attempt.answers.length,
      correct: correct,
      scorePercent: percent,
      durationSpentSeconds: attempt.durationSeconds,
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _test.questions.length;
    final progress = total == 0 ? 0.0 : (_currentIndex + 1) / total;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_test.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Время: ${_test.durationMinutes} мин  |  Вопросов: $total',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Осталось',
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: ElevatedButton(
              onPressed: _submitting ? null : () => _finish(auto: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Завершить'),
            ),
          ),
        ],
      ),
      body: total == 0
          ? const Center(
              child: Text(
                'Нет вопросов для этого теста',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final isActive = index == _currentIndex;
                      final isDone = _answers.containsKey(_test.questions[index].id);
                      return GestureDetector(
                        onTap: () => _goTo(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : isDone
                                    ? const Color(0xFFE0F2FE)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : isDone
                                      ? const Color(0xFF1E73EC)
                                      : const Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemCount: _test.questions.length,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemCount: _test.questions.length,
                    itemBuilder: (context, index) {
                      final question = _test.questions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Tag('Вопрос ${index + 1} из $total'),
                                  const SizedBox(width: 8),
                                  const Tag('Один ответ'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                question.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
                              ),
                              const SizedBox(height: 14),
                              if (question.options.isEmpty)
                                const Text(
                                  'Ответы не переданы от сервера.',
                                  style: TextStyle(color: Color(0xFF9CA3AF)),
                                )
                              else
                                ...List.generate(question.options.length, (optionIndex) {
                                  final isSelected = _answers[question.id] == optionIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: OptionTile(
                                      label: question.options[optionIndex],
                                      selected: isSelected,
                                      onTap: () => _selectOption(question, optionIndex),
                                    ),
                                  );
                                }),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(0xFF1E73EC),
                                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                                      ),
                                      child: const Text('Назад'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          _currentIndex < total - 1 ? () => _goTo(_currentIndex + 1) : null,
                                      child: const Text('Следующий'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.9)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ответы: ${_answers.length}/$total',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                          Text(
                            'Осталось: ${_formatTime(_remainingSeconds)}',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
