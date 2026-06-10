import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../models/podcast_model.dart';

class GeminiService {
  final String apiKey;
  final Dio _dio = Dio();

  GeminiService({required this.apiKey});

  // --- Metadata Service ---
  Future<Map<String, dynamic>> fetchMetadata(String topic) async {
    const prompt = """
      You are an editor for a premium audio news app.
      For the topic: "{topic}", generate:
      1. A catchy, short headline (max 5 words).
      2. A 2-sentence intriguing summary.
      3. A visual prompt to generate a cover image (describe a scene, abstract, high quality).
      
      Output JSON format: {"title": "...", "description": "...", "imagePrompt": "...", "category": "..."}
    """;

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt.replaceFirst("{topic}", topic)}
              ]
            }
          ],
          "generationConfig": {
            "responseMimeType": "application/json",
          }
        },
      );

      final textResponse =
          response.data['candidates'][0]['content']['parts'][0]['text'];
      final data = jsonDecode(textResponse);

      final safePrompt = Uri.encodeComponent(data['imagePrompt'] ?? topic);
      final imageUrl =
          "https://image.pollinations.ai/prompt/$safePrompt?width=800&height=800&nologo=true&seed=${Random().nextInt(1000)}";

      return {
        "title": data['title'] ?? topic,
        "description": data['description'] ?? "Your daily update.",
        "imageUrl": imageUrl,
        "category": data['category'] ?? "General"
      };
    } catch (e) {
      print("Error fetching metadata: $e");
      return {
        "title": topic,
        "description": "Failed to load description.",
        "imageUrl": "",
        "category": "General"
      };
    }
  }

  // --- Script Generation ---
  Future<List<PodcastSegment>> generateScript(String topic) async {
    const scriptPrompt = """
      Create a detailed podcast script about "{topic}".
      Hosts: Alex (Energetic, curious) and Sarah (Calm Expert).
      Output strictly a JSON Array: [{"speaker": "Alex" | "Sarah", "text": "..."}].
    """;

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        data: {
          "contents": [
            {
              "parts": [
                {"text": scriptPrompt.replaceFirst("{topic}", topic)}
              ]
            }
          ],
          "generationConfig": {
            "responseMimeType": "application/json",
          }
        },
      );

      final textResponse =
          response.data['candidates'][0]['content']['parts'][0]['text'];
      final List<dynamic> data = jsonDecode(textResponse);

      return data.map((item) => PodcastSegment.fromJson(item)).toList();
    } catch (e) {
      print("Error generating script: $e");
      return [
        PodcastSegment(
            speaker: "Alex", text: "Sorry, I couldn't generate the script.")
      ];
    }
  }
}
