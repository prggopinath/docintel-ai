class SummaryResponse {
  final String summary;

  final bool success;

  final String? error;

  const SummaryResponse({
    required this.summary,
    required this.success,
    this.error,
  });

  factory SummaryResponse.fromJson(Map<String, dynamic> json) {
    return SummaryResponse(
      summary: json["summary"] ?? "",
      success: json["success"] ?? false,
      error: json["error"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "summary": summary,
      "success": success,
      "error": error,
    };
  }
}