// lib/services/gemini_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static Future<AnimalAssessment> analyzeAnimalPhoto(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    const prompt = '''
You are an expert wildlife veterinarian. Analyze this animal photo and respond ONLY with valid JSON (no markdown).
{
  "animalType": "string",
  "breed": "string or null",
  "estimatedAge": "string or null",
  "color": "string",
  "injuries": ["list"],
  "overallCondition": "Healthy / Minor Injuries / Moderate Injuries / Severe Injuries / Critical",
  "severityScore": 1-10,
  "urgencyLevel": "Routine / Urgent / Emergency / Code Red",
  "visibleSymptoms": ["list"],
  "recommendedActions": ["list"],
  "aiSummary": "2-3 sentence summary",
  "requiresImmediateVet": boolean,
  "estimatedWeight": "string or null"
}''';

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{'parts': [
          {'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}},
          {'text': prompt}
        ]}],
        'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 1024},
      }),
    );
    if (response.statusCode != 200) throw Exception('Gemini API error: ${response.statusCode}');
    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    return AnimalAssessment.fromJson(jsonDecode(cleaned) as Map<String, dynamic>);
  }
}

class AnimalAssessment {
  final String animalType, color, overallCondition, urgencyLevel, aiSummary;
  final String? breed, estimatedAge, estimatedWeight;
  final List<String> injuries, visibleSymptoms, recommendedActions;
  final int severityScore;
  final bool requiresImmediateVet;

  AnimalAssessment({
    required this.animalType, required this.color, required this.overallCondition,
    required this.urgencyLevel, required this.aiSummary, required this.injuries,
    required this.visibleSymptoms, required this.recommendedActions,
    required this.severityScore, required this.requiresImmediateVet,
    this.breed, this.estimatedAge, this.estimatedWeight,
  });

  factory AnimalAssessment.fromJson(Map<String, dynamic> j) => AnimalAssessment(
    animalType: j['animalType'] ?? 'Unknown', color: j['color'] ?? 'Unknown',
    overallCondition: j['overallCondition'] ?? 'Unknown',
    urgencyLevel: j['urgencyLevel'] ?? 'Routine',
    aiSummary: j['aiSummary'] ?? '',
    injuries: List<String>.from(j['injuries'] ?? []),
    visibleSymptoms: List<String>.from(j['visibleSymptoms'] ?? []),
    recommendedActions: List<String>.from(j['recommendedActions'] ?? []),
    severityScore: (j['severityScore'] as num?)?.toInt() ?? 1,
    requiresImmediateVet: j['requiresImmediateVet'] ?? false,
    breed: j['breed'], estimatedAge: j['estimatedAge'], estimatedWeight: j['estimatedWeight'],
  );

  Map<String, dynamic> toJson() => {
    'animalType': animalType, 'breed': breed, 'estimatedAge': estimatedAge,
    'color': color, 'injuries': injuries, 'overallCondition': overallCondition,
    'severityScore': severityScore, 'urgencyLevel': urgencyLevel,
    'visibleSymptoms': visibleSymptoms, 'recommendedActions': recommendedActions,
    'aiSummary': aiSummary, 'requiresImmediateVet': requiresImmediateVet,
    'estimatedWeight': estimatedWeight,
  };

  Color get urgencyColor {
    switch (urgencyLevel) {
      case 'Code Red': return const Color(0xFFE53935);
      case 'Emergency': return const Color(0xFFFF5722);
      case 'Urgent': return const Color(0xFFFF8F00);
      default: return const Color(0xFF43A047);
    }
  }
}
