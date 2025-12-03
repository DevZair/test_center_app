import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AnswerCache {
  const AnswerCache(this.prefs);

  final SharedPreferences prefs;

  static const _key = 'test_center_drafts';

  static Future<AnswerCache> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AnswerCache(prefs);
  }

  Future<Map<int, int>> load(String testId) async {
    final raw = prefs.getString(_composeKey(testId));
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(int.parse(key), value as int));
  }

  Future<void> save(String testId, Map<int, int> answers) async {
    final encoded = jsonEncode(answers.map((key, value) => MapEntry(key.toString(), value)));
    await prefs.setString(_composeKey(testId), encoded);
  }

  Future<void> clear(String testId) async {
    await prefs.remove(_composeKey(testId));
  }

  String _composeKey(String testId) => '$_key::$testId';
}
