import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';

class DocIntelApp extends StatelessWidget {
  const DocIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "DocIntel AI",
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}