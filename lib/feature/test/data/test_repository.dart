import 'package:dio/dio.dart';

import '../../../core/models.dart';
import '../../../core/sample_data.dart';
import '../../../core/network/dio_client.dart';

abstract class TestRepository {
  Future<List<TestOption>> fetchTests({int? courseId});

  Future<TestOption> fetchTestDetail(String id);

  Future<TestResult> submitAttempt(TestAttempt attempt);
}

class FastApiTestRepository implements TestRepository {
  FastApiTestRepository({Dio? dio})
      : _dio = dio ?? DioClient().dio,
        _paths = _ApiPaths();

  final Dio _dio;
  final _ApiPaths _paths;

  @override
  Future<List<TestOption>> fetchTests({int? courseId}) async {
    try {
      final res = await _dio.get(
        '/tests',
        queryParameters: {
          'course': courseId ?? 1,
          'page': 1,
          'size': 200,
        },
      );
      final raw = _extractList(res.data);
      if (raw.isEmpty) return sampleTests;
      return raw.map(TestOption.fromJson).toList();
    } catch (_) {
      // Fallback to bundled sample if API unavailable in dev or API пуст.
      return sampleTests;
    }
  }

  @override
  Future<TestOption> fetchTestDetail(String id) async {
    // Backend ожидает числовой test_id; для демо-id строк формата "psychology-001" сразу отдаём заглушку.
    if (int.tryParse(id) == null) {
      throw const FormatException('Non-numeric test id, skip remote detail');
    }
    try {
      final res = await _tryPaths(
        _paths.testDetail(id),
        (path) => _dio.get(path),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map<String, dynamic>) {
          return TestOption.fromJson(data['data'] as Map<String, dynamic>);
        }
        return TestOption.fromJson(data);
      }
      throw Exception('Unexpected payload');
    } catch (_) {
      // Try to find from list of sample tests.
      return sampleTests.firstWhere((element) => element.id == id, orElse: () => sampleTests.first);
    }
  }

  @override
  Future<TestResult> submitAttempt(TestAttempt attempt) async {
    final testNumeric = int.tryParse(attempt.testId) ?? 0;
    final payload = {
      'test_id': testNumeric,
      'first_name': attempt.profile?.firstName ?? '',
      'last_name': attempt.profile?.lastName ?? '',
      'group_id': _parseIntSafe(attempt.profile?.groupId) ?? 1,
      'course': attempt.profile?.course ?? 1,
      'answers': attempt.answers
          .map((a) => {
                'question_id': a.questionId,
                'choice_id': a.choiceId ?? a.optionIndex,
              })
          .toList(),
    };

    try {
      final res = await _dio.post(_paths.submitResult, data: payload);
      if (res.data is Map<String, dynamic>) {
        return _buildResultFromResponse(res.data as Map<String, dynamic>, attempt);
      }
      return _localFallbackResult(attempt);
    } catch (_) {
      return _localFallbackResult(attempt);
    }
  }

  Future<Response<dynamic>> _tryPaths(
    List<String> paths,
    Future<Response<dynamic>> Function(String path) request,
  ) async {
    DioException? lastError;
    for (final path in paths) {
      try {
        return await request(path);
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        // 404/422 -> пробуем следующий путь; остальное пробрасываем.
        if (code != 404 && code != 422) rethrow;
      }
    }
    if (lastError != null) throw lastError;
    throw Exception('No paths provided');
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      if (data['items'] is List) {
        return (data['items'] as List).whereType<Map<String, dynamic>>().toList();
      }
      if (data['results'] is List) {
        return (data['results'] as List).whereType<Map<String, dynamic>>().toList();
      }
      if (data['data'] is List) {
        return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
      }
      if (data['tests'] is List) {
        return (data['tests'] as List).whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  TestResult _localFallbackResult(TestAttempt attempt) {
    final total = attempt.totalQuestions ?? attempt.answers.length;
    final answered = attempt.answers.length;
    return TestResult(
      testId: attempt.testId,
      totalQuestions: total,
      answered: answered,
      correct: 0,
      scorePercent: 0,
      durationSpentSeconds: attempt.durationSeconds,
    );
  }

  TestResult _buildResultFromResponse(Map<String, dynamic> data, TestAttempt attempt) {
    final score = _parseIntSafe(data['score']) ?? 0;
    final totalFromApi =
        _parseIntSafe(data['question_limit']) ?? _parseIntSafe(data['total_questions']);
    final total = totalFromApi ?? attempt.totalQuestions ?? attempt.answers.length;
    final answered = attempt.answers.length;
    final correct = score;
    final percent = total == 0 ? 0.0 : (score / total) * 100.0;

    return TestResult(
      testId: attempt.testId,
      totalQuestions: total,
      answered: answered,
      correct: correct,
      scorePercent: percent,
      durationSpentSeconds: attempt.durationSeconds,
    );
  }
}

class _ApiPaths {
  List<String> testDetail(String id) => [
        '/tests/$id',
        '/tests/$id/',
      ];

  List<String> submitAttempt(String id) => [
        '/tests/$id/attempt',
        '/tests/$id/attempt/',
      ];

  String get submitResult => '/results/submit';
}

class _Endpoint {
  const _Endpoint(this.path, this.query);

  final String path;
  final Map<String, dynamic>? query;
}

int? _parseIntSafe(dynamic source) {
  if (source == null) return null;
  if (source is int) return source;
  if (source is String) {
    final match = RegExp(r'\d+').firstMatch(source);
    if (match != null) return int.tryParse(match.group(0)!);
    return int.tryParse(source);
  }
  return null;
}
