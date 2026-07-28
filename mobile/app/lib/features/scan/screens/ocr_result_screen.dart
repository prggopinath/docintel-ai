import 'package:flutter/material.dart';

class OcrResultScreen extends StatelessWidget {
  const OcrResultScreen({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OCR Result"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          text.isEmpty
              ? "No text detected."
              : text,
        ),
      ),
    );
  }
}