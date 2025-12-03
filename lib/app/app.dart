import 'package:flutter/material.dart';

import '../core/state/app_state.dart';
import '../core/theme/app_theme.dart';
import '../feature/onboarding/onboarding_screen.dart';

class TestCenterApp extends StatelessWidget {
  const TestCenterApp({super.key});

  static final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) =>
          SelectionContainer.disabled(child: child ?? const SizedBox.shrink()),
      home: OnboardingScreen(appState: _appState),
    );
  }
}
