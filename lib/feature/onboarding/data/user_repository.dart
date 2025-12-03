import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class LabeledValue<T> {
  const LabeledValue({required this.value, required this.label});

  final T value;
  final String label;
}

class UserRepository {
  UserRepository({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  Future<List<LabeledValue<int>>> fetchGroups() async {
    try {
      // Рабочий эндпоинт только /groups/.
      final res = await _dio.get('/groups/');
      return _extractNamedInt(res.data);
    } catch (_) {
      return const [
        LabeledValue(value: 1, label: 'ИИ-241'),
        LabeledValue(value: 2, label: 'ITM-241'),
      ];
    }
  }

  Future<List<LabeledValue<int>>> fetchCourses() async {
    // API для курсов отсутствует, используем дефолтный список.
    return const [
      LabeledValue(value: 1, label: '1 курс'),
      LabeledValue(value: 2, label: '2 курс'),
      LabeledValue(value: 3, label: '3 курс'),
      LabeledValue(value: 4, label: '4 курс'),
    ];
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
        if (code != 404 && code != 422) rethrow;
      }
    }
    if (lastError != null) throw lastError;
    throw Exception('No paths provided');
  }

  List<LabeledValue<int>> _extractNamedInt(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => LabeledValue<int>(
              value: (e['id'] ?? e['value'] ?? 0) as int,
              label: (e['name'] ?? e['title'] ?? e['label'] ?? '').toString(),
            ),
          )
          .where((e) => e.label.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
