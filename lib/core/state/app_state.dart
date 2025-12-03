import 'package:flutter/foundation.dart';

import '../../feature/test/data/test_repository.dart';
import '../models.dart';
import '../sample_data.dart';

class AppState extends ChangeNotifier {
  AppState({TestRepository? repository}) : repository = repository ?? FastApiTestRepository();

  final TestRepository repository;

  StudentProfile? profile;
  List<TestOption> tests = sampleTests;
  bool isLoadingTests = false;
  String? testsError;

  Future<void> loadTests() async {
    isLoadingTests = true;
    testsError = null;
    notifyListeners();
    try {
      final courseId = profile?.course;
      tests = await repository.fetchTests(courseId: courseId);
    } catch (e) {
      testsError = e.toString();
    } finally {
      isLoadingTests = false;
      notifyListeners();
    }
  }

  Future<TestOption> loadTestDetail(String id) async {
    try {
      return await repository.fetchTestDetail(id);
    } catch (e) {
      testsError = e.toString();
      notifyListeners();
      return sampleTests.firstWhere((element) => element.id == id, orElse: () => sampleTests.first);
    }
  }

  void setProfile(StudentProfile next) {
    profile = next;
    notifyListeners();
  }
}
