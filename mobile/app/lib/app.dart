import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';

class DocIntelApp extends StatelessWidget {
  const DocIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "DocIntel AI",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const SplashScreen(),
    );
  }
}