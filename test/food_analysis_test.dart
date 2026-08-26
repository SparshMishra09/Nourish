import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/models/food_analysis.dart';
import 'package:nourish/services/food_analysis_service.dart';

void main() {
  test('parses structured food analysis and scales confirmed portion', () {
    final analysis = FoodAnalysis.fromJson({
      'isFood': true,
      'mealName': 'Rajma rice plate',
      'items': [
        {'name': 'Rajma', 'quantity': '1 cup', 'estimatedGrams': 220},
        {'name': 'Rice', 'quantity': '1 cup', 'estimatedGrams': 180},
      ],
      'calories': 620,
      'protein': 24,
      'carbs': 106,
      'fat': 12,
      'fiber': 18,
      'sugar': 7,
      'sodiumMg': 780,
      'confidence': 0.82,
      'assumptions': ['Moderate oil was assumed.'],
    });

    final half = analysis.scaled(0.5);

    expect(analysis.isFood, isTrue);
    expect(analysis.items, hasLength(2));
    expect(half.calories, 310);
    expect(half.protein, 12);
    expect(half.fiber, 9);
    expect(half.toLogMap()['source'], 'photoAnalysis');
  });

  test('clamps unsafe portion multipliers', () {
    const analysis = FoodAnalysis(
      isFood: true,
      mealName: 'Meal',
      items: [],
      calories: 400,
      protein: 20,
      carbs: 50,
      fat: 12,
      fiber: 7,
      sugar: 4,
      sodiumMg: 500,
      confidence: 0.7,
      assumptions: [],
    );

    expect(analysis.scaled(10).portionMultiplier, 3);
    expect(analysis.scaled(0).portionMultiplier, 0.25);
  });

  test(
    'parses packaged identity and replaces estimates with a verified label',
    () {
      final visual = FoodAnalysis.fromJson({
        'isFood': true,
        'mealName': 'Chocolate bar',
        'items': [
          {'name': 'Chocolate bar', 'quantity': '1 bar', 'estimatedGrams': 40},
        ],
        'calories': 230,
        'protein': 4,
        'carbs': 26,
        'fat': 13,
        'fiber': 2,
        'sugar': 18,
        'sodiumMg': 30,
        'confidence': 0.7,
        'assumptions': [],
        'isPackagedFood': true,
        'brandName': 'Example Foods',
        'productName': '70% Dark Chocolate',
        'barcode': '8901234567890',
      });
      final verified = visual.withProductMatch(
        const ProductNutritionMatch(
          productName: '70% Dark Chocolate',
          brandName: 'Example Foods',
          barcode: '8901234567890',
          servingLabel: '4 squares (30 g)',
          servingGrams: 30,
          calories: 170,
          protein: 3,
          carbs: 15,
          fat: 12,
          fiber: 4,
          sugar: 9,
          sodiumMg: 10,
          matchConfidence: 0.94,
          nutritionSource: 'openFoodFacts',
          sourceNote: 'Exact label record.',
          sources: [
            NutritionSourceRef(
              title: 'Product label',
              url: 'https://example.com/label',
            ),
          ],
        ),
      );

      expect(visual.isPackagedFood, isTrue);
      expect(verified.hasVerifiedOnlineNutrition, isTrue);
      expect(verified.calories, 170);
      expect(verified.sourceServing, '4 squares (30 g)');
      expect(verified.sources.single.title, 'Product label');
      expect(verified.scaled(2).calories, 340);
      expect(verified.scaled(2).nutritionSource, 'openFoodFacts');
      expect(verified.toLogMap()['barcode'], '8901234567890');
    },
  );

  test('detects the actual image format instead of trusting the file name', () {
    final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0x00]);
    final png = Uint8List.fromList([
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ]);
    final webp = Uint8List.fromList('RIFF0000WEBP'.codeUnits);
    final heic = Uint8List.fromList('0000ftypheic'.codeUnits);

    expect(detectImageMimeType(jpeg, filePath: 'photo.heic'), 'image/jpeg');
    expect(detectImageMimeType(png, filePath: 'photo.jpg'), 'image/png');
    expect(detectImageMimeType(webp), 'image/webp');
    expect(detectImageMimeType(heic), 'image/heic');
  });

  test(
    'temporary server failures use the next model without blaming internet',
    () {
      final error = FirebaseAIException(
        'Server Error [500]: model is currently experiencing high demand.',
      );
      final message = foodAnalysisErrorMessage(error);

      expect(message.toLowerCase(), isNot(contains('check your connection')));
      expect(message, isNot(contains('[SERVER]')));
      expect(message.toLowerCase(), contains('busy'));
      expect(shouldRetryFoodAnalysis(error), isTrue);
    },
  );

  test('configuration and region failures do not cycle through models', () {
    expect(shouldRetryFoodAnalysis(InvalidApiKey('bad key')), isFalse);
    expect(shouldRetryFoodAnalysis(UnsupportedUserLocation()), isFalse);
  });
}
