import 'dart:async';
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
  FoodAnalysisService({
    GenerativeModel? primaryModel,
    GenerativeModel? fallbackModel,
  }) : _models = [
         primaryModel ?? _buildModel('gemini-3.7-flash'),
         fallbackModel ?? _buildModel('gemini-3.5-flash'),
       ];

  final List<GenerativeModel> _models;

  static GenerativeModel _buildModel(String modelName) {
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
      model: modelName,
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
      'Analyze this food photo. It may show a plated meal or packaged food. Return a '
      'conservative nutrition estimate for the complete visible serving. For packaged '
      'food, read the product name, visible claims, serving size, and nutrition label '
      'when available; never invent label values that are not visible. For meals, '
      'consider plate/bowl scale, item count, cooking method, and likely added oil. '
      'List each detected item and its estimated weight.',
    );
    if (hint.isNotEmpty) {
      prompt.write(
        ' The user added this context: "$hint". Use it only when the image supports it.',
      );
    }

    Object? lastError;
    StackTrace? lastStackTrace;
    for (var index = 0; index < _models.length; index++) {
      try {
        final response = await _models[index]
            .generateContent([
              Content.multi([
                TextPart(prompt.toString()),
                InlineDataPart(mimeType, imageBytes),
              ]),
            ])
            .timeout(const Duration(seconds: 55));
        final text = response.text;
        if (text == null || text.trim().isEmpty) {
          throw const FormatException('The model returned an empty response.');
        }
        final decoded = jsonDecode(text);
        if (decoded is! Map) {
          throw const FormatException('The model response was not an object.');
        }
        return FoodAnalysis.fromJson(Map<String, dynamic>.from(decoded));
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        debugPrint(
          'Food analysis attempt ${index + 1}/${_models.length} failed: $error',
        );
        if (index + 1 < _models.length && _canRetry(error)) {
          await Future<void>.delayed(Duration(milliseconds: 700 * (index + 1)));
          continue;
        }
        break;
      }
    }

    debugPrintStack(stackTrace: lastStackTrace);
    throw FoodAnalysisException(_friendlyError(lastError));
  }

  bool _canRetry(Object error) =>
      error is ServerException ||
      error is QuotaExceeded ||
      error is FirebaseAISdkException ||
      error is FormatException ||
      error is TimeoutException;

  String _friendlyError(Object? error) {
    if (error is QuotaExceeded) {
      return 'The food scanner is busy right now. Wait a minute, then tap Analyze again. [LIMIT]';
    }
    if (error is UnsupportedUserLocation) {
      return 'Food scanning is not available from this location. [REGION]';
    }
    if (error is InvalidApiKey || error is ServiceApiNotEnabled) {
      return 'The Nourish scan service needs an update. Install the latest APK and try again. [SETUP]';
    }
    if (error is TimeoutException) {
      return 'The photo upload timed out. Use a stable connection and tap Analyze again. [TIMEOUT]';
    }
    if (error is FormatException || error is FirebaseAISdkException) {
      return 'The result could not be read. Retake the photo in good light and try again. [RESULT]';
    }
    if (error is FirebaseAIException) {
      final message = error.message.toLowerCase();
      if (message.contains('permission') ||
          message.contains('app check') ||
          message.contains('attestation') ||
          message.contains('403')) {
        return 'Nourish could not verify this installation. Close and reopen the app, then try again. [VERIFY]';
      }
      if (message.contains('image') || message.contains('invalid argument')) {
        return 'This photo format could not be processed. Retake it with the Nourish camera and try again. [PHOTO]';
      }
    }
    return 'The AI service did not respond. Check your connection and tap Analyze again. [SERVER]';
  }
}

String detectImageMimeType(Uint8List bytes, {String filePath = ''}) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
    final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
    if (brand.startsWith('hei') || brand == 'mif1' || brand == 'msf1') {
      return 'image/heic';
    }
  }
  final lower = filePath.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}
