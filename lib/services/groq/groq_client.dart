import 'package:dio/dio.dart';

/// Thin wrapper over Groq's OpenAI-compatible chat completions endpoint.
/// The API key is supplied per-call from secure storage — never hardcoded.
class GroqClient {
  static const String _base = 'https://api.groq.com/openai/v1';
  static const String defaultModel = 'llama-3.3-70b-versatile';

  final Dio _dio;

  GroqClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _base,
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// Sends a chat completion. [messages] are `{role, content}` maps.
  /// Throws on network/auth failure so the caller can fall back gracefully.
  Future<String> complete({
    required String apiKey,
    required List<Map<String, String>> messages,
    String model = defaultModel,
    double temperature = 0.4,
    int maxTokens = 900,
  }) async {
    final res = await _dio.post(
      '/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': model,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'messages': messages,
      },
    );
    final content =
        res.data['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw const GroqException('Empty response from Groq');
    }
    return content.trim();
  }

  /// Quick auth/connectivity probe used by Settings to validate a pasted key.
  Future<bool> validateKey(String apiKey) async {
    try {
      await complete(
        apiKey: apiKey,
        messages: [
          {'role': 'user', 'content': 'ping'}
        ],
        maxTokens: 5,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

class GroqException implements Exception {
  final String message;
  const GroqException(this.message);
  @override
  String toString() => 'GroqException: $message';
}
