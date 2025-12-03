import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenProtector.preventScreenshotOn();
  runApp(const TestCenterApp());
}
