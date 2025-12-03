import 'dart:convert';

class StudentProfile {
  StudentProfile({
    required this.firstName,
    required this.lastName,
    required this.groupName,
    required this.course,
    this.groupId,
  });

  final String firstName;
  final String lastName;
  final String groupName;
  final int course;
  final int? groupId;
}

class TestOption {
  const TestOption({
    required this.id,
    required this.title,
    required this.teacher,
    required this.durationMinutes,
    required this.questionCount,
    required this.questions,
  });

  final String id;
  final String title;
  final String teacher;
  final int durationMinutes;
  final int questionCount;
  final List<Question> questions;

  factory TestOption.fromJson(Map<String, dynamic> json) {
    final questionList = (json['questions'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Question.fromJson)
            .toList() ??
        const <Question>[];
    return TestOption(
      id: (json['id'] ?? json['test_id'] ?? '').toString(),
      title: json['title'] ?? json['name'] ?? json['subject'] ?? '',
      teacher: json['teacher'] ?? json['teacher_name'] ?? 'Преподаватель',
      durationMinutes:
          _asInt(json['duration'] ?? json['duration_minutes'] ?? json['time_limit'], 60),
      questionCount: _asInt(json['question_count'] ?? json['question_limit'], questionList.length),
      questions: questionList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'teacher': teacher,
      'duration_minutes': durationMinutes,
      'question_count': questionCount,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}

class Question {
  const Question({
    required this.id,
    required this.title,
    required this.options,
    this.choiceIds = const [],
    this.correctOption,
  });

  final int id;
  final String title;
  final List<String> options;
  final List<int?> choiceIds;
  final int? correctOption;

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    List<String> options;
    List<int?> choiceIds = const [];
    if (rawChoices is List) {
      options = rawChoices
          .map((e) => e is Map<String, dynamic> ? (e['text'] ?? e['title'] ?? '').toString() : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      choiceIds =
          rawChoices.map((e) => e is Map<String, dynamic> ? _asIntNullable(e['choice_id'] ?? e['id']) : null).toList();
    } else {
      final optionsRaw =
          (json['options'] ?? json['variants'] ?? json['answers'] ?? json['answers_list'] ?? []) as List<dynamic>;
      options = optionsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return Question(
      id: _asInt(json['id'] ?? json['question_id'], 0),
      title: json['title'] ?? json['text'] ?? '',
      options:
          options.isEmpty ? const ['Вариант 1', 'Вариант 2', 'Вариант 3', 'Вариант 4'] : options,
      choiceIds: choiceIds,
      correctOption: json['correct_option'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'options': options,
      'correct_option': correctOption,
    };
  }
}

class AttemptAnswer {
  const AttemptAnswer({required this.questionId, required this.optionIndex, this.choiceId});

  final int questionId;
  final int optionIndex;
  final int? choiceId;

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'option_index': optionIndex,
        if (choiceId != null) 'choice_id': choiceId,
      };
}

class TestAttempt {
  TestAttempt({
    required this.testId,
    required this.answers,
    required this.durationSeconds,
    this.totalQuestions,
    this.profile,
  });

  final String testId;
  final List<AttemptAnswer> answers;
  final int durationSeconds;
  final int? totalQuestions;
  final StudentProfile? profile;

  Map<String, dynamic> toJson() => {
        'test_id': testId,
        'duration_seconds': durationSeconds,
        if (totalQuestions != null) 'question_limit': totalQuestions,
        'answers': answers.map((e) => e.toJson()).toList(),
        if (profile != null)
          'student': {
            'first_name': profile!.firstName,
            'last_name': profile!.lastName,
            'group_id': profile!.groupId,
            'group_name': profile!.groupName,
            'course': profile!.course,
          },
      };
}

class TestResult {
  const TestResult({
    required this.testId,
    required this.totalQuestions,
    required this.answered,
    required this.correct,
    required this.scorePercent,
    required this.durationSpentSeconds,
  });

  final String testId;
  final int totalQuestions;
  final int answered;
  final int correct;
  final double scorePercent;
  final int durationSpentSeconds;

  factory TestResult.fromJson(Map<String, dynamic> json) {
    final percent = (json['score_percent'] ?? json['score'] ?? 0).toDouble();
    return TestResult(
      testId: json['test_id']?.toString() ?? '',
      totalQuestions: json['total_questions'] ?? json['total'] ?? 0,
      answered: json['answered'] ?? json['answered_count'] ?? 0,
      correct: json['correct'] ?? json['correct_count'] ?? 0,
      scorePercent: percent,
      durationSpentSeconds: json['duration_spent'] ?? json['duration_seconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'test_id': testId,
        'total_questions': totalQuestions,
        'answered': answered,
        'correct': correct,
        'score_percent': scorePercent,
        'duration_spent': durationSpentSeconds,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

int _asInt(dynamic value, int fallback) {
  final parsed = _asIntNullable(value);
  return parsed ?? fallback;
}

int? _asIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
