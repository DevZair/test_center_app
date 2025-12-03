import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Block screenshots/recording at OS level where supported (Android/iOS).
  await ScreenProtector.preventScreenshotOn();
  runApp(const TestCenterApp());
}
