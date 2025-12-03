import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../common/widgets/widgets.dart';
import '../test_player/test_player_screen.dart';

class TestListScreen extends StatefulWidget {
  const TestListScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  @override
  void initState() {
    super.initState();
    widget.appState.loadTests();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.appState.profile?.firstName ?? 'Студент';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Выберите тест',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.appState,
        builder: (context, _) {
          final state = widget.appState;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Привет, $name 👋',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Просмотрите доступные варианты и начинайте, когда будете готовы.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                if (state.isLoadingTests)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                else if (state.testsError != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Не удалось загрузить тесты'),
                          const SizedBox(height: 6),
                          Text(state.testsError!, style: const TextStyle(color: Color(0xFF9CA3AF))),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: state.loadTests,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: state.tests.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final test = state.tests[index];
                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child:
                                        const Icon(Icons.menu_book_rounded, color: Color(0xFF1E73EC)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          test.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Преподаватель: ${test.teacher}',
                                          style: const TextStyle(color: Color(0xFF6B7280)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Tag('${test.durationMinutes} мин'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Вопросов: ${test.questionCount}',
                                      style: const TextStyle(color: Color(0xFF6B7280))),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TestPlayerScreen(
                                            test: test,
                                            appState: widget.appState,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Начать'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
