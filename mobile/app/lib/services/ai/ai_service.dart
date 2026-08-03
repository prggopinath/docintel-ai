import 'dart:convert';

import 'package:dio/dio.dart';

import '../../shared/models/summary_response.dart';

class AiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://curly-space-umbrella-wr4xwv7wqv4xhgxww-8000.app.github.dev/api/v1",
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );

  Future<SummaryResponse> generateSummary(String text) async {
    try {
      print("Sending request to AI backend...");
      final response = await _dio.post(
        "/ai/summarize",
        data: {
          "text": text,
        },
      );
      print(response.data);
      //return SummaryResponse.fromJson(response.data);
    } catch (e) {
      return SummaryResponse(
        summary: "",
        success: false,
        error: e.toString(),
      );
    }
  }
}