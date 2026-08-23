import 'package:flutter_test/flutter_test.dart';
import 'package:nourish/models/food_analysis.dart';

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
}
