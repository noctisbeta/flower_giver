import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/io_client.dart';
import 'package:meta/meta.dart';

@immutable
final class GeminiWrapper {
  GeminiWrapper({required String apiKey, this.httpClient})
    : model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        httpClient: httpClient,
      );

  final IOClient? httpClient;

  final GenerativeModel model;

  Future<String> customizedResponse(String name) async {
    final response = await model.generateContent([
      Content.text(
        'Write a cute story, no more than 2 sentences long, about a dragon giving a flower to $name.',
      ),
    ]);

    return response.text ?? 'No response';
  }

  Future<String> getGeminiResponse() async {
    final response = await model.generateContent([
      Content.text(
        'Write a story about a dragon and a knight, that ends with the dragon giving the knight a flower. The story should be quite short, no more than 2 sentences. Pick out fun names.',
      ),
    ]);

    return response.text ?? 'No response';
  }
}
