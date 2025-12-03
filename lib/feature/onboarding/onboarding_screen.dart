import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/state/app_state.dart';
import '../onboarding/data/user_repository.dart';
import '../common/widgets/widgets.dart';
import '../test_list/test_list_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  LabeledValue<int>? _group;
  LabeledValue<int>? _course;

  final _userRepo = UserRepository();
  List<LabeledValue<int>> _groups = const [];
  List<LabeledValue<int>> _courses = const [];
  bool _loadingMeta = false;
  String? _metaError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _metaError = null;
    });
    try {
      final results = await Future.wait([
        _userRepo.fetchGroups(),
        _userRepo.fetchCourses(),
      ]);
      setState(() {
        _groups = results[0] as List<LabeledValue<int>>;
        _courses = results[1] as List<LabeledValue<int>>;
        _group = null;
        _course = null;
      });
    } catch (e) {
      setState(() {
        _metaError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loadingMeta = false);
      }
    }
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final profile = StudentProfile(
      firstName: _nameCtrl.text.trim(),
      lastName: _surnameCtrl.text.trim(),
      groupName: _group?.label ?? '',
      groupId: _group?.value,
      course: _course?.value ?? 1,
    );
    widget.appState.setProfile(profile);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestListScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMaxWidth(
          maxWidth: 640,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const BrandHeader(),
                const SizedBox(height: 22),
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Начало тестирования',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                        const SizedBox(height: 18),
                        Text('Имя', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Введите имя',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Укажите имя'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text('Фамилия', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _surnameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Введите фамилию',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Укажите фамилию'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text('Группа', style: _labelStyle),
                        const SizedBox(height: 6),
                        _loadingMeta
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(minHeight: 6),
                              )
                            : SelectField<LabeledValue<int>>(
                                hint: 'Выберите группу',
                                value: _group,
                                options: _groups,
                                labelBuilder: (opt) => opt.label,
                                onChanged: (v) => setState(() => _group = v),
                                validator: (value) =>
                                    value == null ? 'Выберите группу' : null,
                              ),
                        const SizedBox(height: 14),
                        Text('Курс', style: _labelStyle),
                        const SizedBox(height: 6),
                        _loadingMeta
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(minHeight: 6),
                              )
                            : SelectField<LabeledValue<int>>(
                                hint: 'Выберите курс',
                                value: _course,
                                options: _courses,
                                labelBuilder: (opt) => opt.label,
                                onChanged: (v) => setState(() => _course = v),
                                validator: (value) =>
                                    value == null ? 'Выберите курс' : null,
                              ),
                        if (_metaError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Не удалось загрузить группы/курсы. Использованы заглушки.',
                            style:
                                TextStyle(color: Colors.red.shade400, fontSize: 12),
                          ),
                          Text(
                            _metaError!,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _continue,
                            child: const Text('Продолжить'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _labelStyle = TextStyle(
  fontWeight: FontWeight.w600,
  color: Color(0xFF1F2937),
);
