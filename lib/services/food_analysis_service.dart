import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../models/food_analysis.dart';

class FoodAnalysisException implements Exception {
  const FoodAnalysisException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FoodAnalysisService {
  FoodAnalysisService({GenerativeModel? model})
    : _model = model ?? _buildModel();

  final GenerativeModel _model;

  static GenerativeModel _buildModel() {
    final responseSchema = Schema.object(
      properties: {
        'isFood': Schema.boolean(
          description: 'True only when the image clearly contains edible food.',
        ),
        'mealName': Schema.string(
          description: 'A concise name for the complete visible meal.',
        ),
        'items': Schema.array(
          minItems: 0,
          maxItems: 8,
          items: Schema.object(
            properties: {
              'name': Schema.string(description: 'Detected food item.'),
              'quantity': Schema.string(
                description: 'Human-readable visible portion, such as 1 cup.',
              ),
              'estimatedGrams': Schema.number(
                description: 'Estimated edible weight in grams.',
                minimum: 0,
              ),
            },
          ),
        ),
        'calories': Schema.integer(
          description: 'Total kcal for the complete visible serving.',
          minimum: 0,
        ),
        'protein': Schema.number(
          description: 'Total protein grams.',
          minimum: 0,
        ),
        'carbs': Schema.number(
          description: 'Total carbohydrate grams.',
          minimum: 0,
        ),
        'fat': Schema.number(description: 'Total fat grams.', minimum: 0),
        'fiber': Schema.number(
          description: 'Total dietary fibre grams.',
          minimum: 0,
        ),
        'sugar': Schema.number(description: 'Total sugar grams.', minimum: 0),
        'sodiumMg': Schema.integer(
          description: 'Total sodium in milligrams.',
          minimum: 0,
        ),
        'confidence': Schema.number(
          description:
              'Overall identification and portion confidence from 0 to 1.',
          minimum: 0,
          maximum: 1,
        ),
        'assumptions': Schema.array(
          minItems: 0,
          maxItems: 5,
          items: Schema.string(
            description: 'Important uncertainty about portion or preparation.',
          ),
        ),
      },
      propertyOrdering: const [
        'isFood',
        'mealName',
        'items',
        'calories',
        'protein',
        'carbs',
        'fat',
        'fiber',
        'sugar',
        'sodiumMg',
        'confidence',
        'assumptions',
      ],
    );

    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.7-flash',
      generationConfig: GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 4096,
        responseMimeType: 'application/json',
        responseSchema: responseSchema,
      ),
      systemInstruction: Content.system(
        'You are Nourish food vision, a conservative nutrition estimation assistant. '
        'Identify only food visibly supported by the image. Estimate the edible portion '
        'of every component, including oils, sauces, drinks, and garnishes when visible. '
        'Use familiar Indian dish names when appropriate. Nutrition must total the entire '
        'visible serving, not 100 g. Never claim medical certainty. If the photo is unclear '
        'or portion size is ambiguous, lower confidence and explain the assumption. If the '
        'image is not food, set isFood false and all nutrient values to zero.',
      ),
    );
  }

  Future<FoodAnalysis> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String contextHint = '',
  }) async {
    if (imageBytes.isEmpty) {
      throw const FoodAnalysisException('The selected image is empty.');
    }
    final hint = contextHint.trim();
    final prompt = StringBuffer(
      'Analyze this meal photo. Return a conservative nutrition estimate for the '
      'complete visible serving. Consider plate/bowl scale, item count, cooking method, '
      'and likely added oil. List each detected item and its estimated weight.',
    );
    if (hint.isNotEmpty) {
      prompt.write(
        ' The user added this context: "$hint". Use it only when the image supports it.',
      );
    }

    try {
      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt.toString()),
          InlineDataPart(mimeType, imageBytes),
        ]),
      ]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const FoodAnalysisException(
          'The food analyzer returned no result. Try a clearer photo.',
        );
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const FoodAnalysisException(
          'The food analyzer returned an unreadable result.',
        );
      }
      return FoodAnalysis.fromJson(Map<String, dynamic>.from(decoded));
    } on FoodAnalysisException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Food analysis request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const FoodAnalysisException(
        'Food analysis is temporarily unavailable. Check your connection and try again.',
      );
    }
  }
}
