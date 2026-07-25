import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocIntelApp extends StatelessWidget {
  const DocIntelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DocIntel AI',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'DocIntel AI',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}