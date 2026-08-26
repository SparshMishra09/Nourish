import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nourish/models/food_analysis.dart';
import 'package:nourish/services/product_nutrition_lookup.dart';

void main() {
  test(
    'barcode label values are converted from 100 g to one serving',
    () async {
      final lookup = OpenFoodFactsProductLookup(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, contains('/8901234567890'));
          return http.Response(
            jsonEncode({
              'product': {
                'code': '8901234567890',
                'product_name': 'Dark Chocolate Protein Bar',
                'brands': 'Nourish Test Foods',
                'serving_size': '1 bar (40 g)',
                'serving_quantity': 40,
                'serving_quantity_unit': 'g',
                'nutriments': {
                  'energy-kcal_100g': 500,
                  'proteins_100g': 20,
                  'carbohydrates_100g': 50,
                  'fat_100g': 25,
                  'fiber_100g': 10,
                  'sugars_100g': 15,
                  'sodium_100g': 0.1,
                },
              },
            }),
            200,
          );
        }),
      );

      final match = await lookup.lookup(_visual(barcode: '8901234567890'));

      expect(match, isNotNull);
      expect(match!.calories, 200);
      expect(match.protein, 8);
      expect(match.carbs, 20);
      expect(match.fat, 10);
      expect(match.fiber, 4);
      expect(match.sugar, 6);
      expect(match.sodiumMg, 40);
      expect(match.servingLabel, '1 bar (40 g)');
      expect(match.nutritionSource, 'openFoodFacts');
    },
  );

  test('strict name search accepts the exact brand and product', () async {
    final lookup = OpenFoodFactsProductLookup(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.host, 'search.openfoodfacts.org');
        return http.Response(
          jsonEncode({
            'hits': [
              _searchProduct(
                brand: 'Nourish Test Foods',
                name: 'Dark Chocolate Protein Bar',
              ),
            ],
          }),
          200,
        );
      }),
    );

    final match = await lookup.lookup(_visual());

    expect(match, isNotNull);
    expect(match!.productName, 'Dark Chocolate Protein Bar');
    expect(match.matchConfidence, greaterThanOrEqualTo(0.9));
  });

  test('strict name search rejects a merely similar packaged food', () async {
    final lookup = OpenFoodFactsProductLookup(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'hits': [
              _searchProduct(
                brand: 'Another Company',
                name: 'Orange Cacao Fruit Bar',
              ),
            ],
          }),
          200,
        );
      }),
    );

    final match = await lookup.lookup(_visual());

    expect(match, isNull);
  });

  test(
    'serving-specific label fields take priority over per-100 g fields',
    () async {
      final lookup = OpenFoodFactsProductLookup(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'product': {
                'code': '8901234567890',
                'product_name': 'Dark Chocolate Protein Bar',
                'brands': 'Nourish Test Foods',
                'serving_size': '1 bar (50 g)',
                'serving_quantity': 50,
                'serving_quantity_unit': 'g',
                'nutriments': {
                  'energy-kcal_serving': 197,
                  'proteins_serving': 10.3,
                  'carbohydrates_serving': 22.6,
                  'fat_serving': 9,
                  'fiber_serving': 7.7,
                  'sugars_serving': 8.1,
                  'sodium_serving': 0.023,
                  'energy-kcal_100g': 999,
                  'proteins_100g': 99,
                  'carbohydrates_100g': 99,
                  'fat_100g': 99,
                },
              },
            }),
            200,
          );
        }),
      );

      final match = await lookup.lookup(_visual(barcode: '8901234567890'));

      expect(match, isNotNull);
      expect(match!.calories, 197);
      expect(match.protein, 10.3);
      expect(match.carbs, 22.6);
      expect(match.fat, 9);
      expect(match.fiber, 7.7);
      expect(match.sodiumMg, 23);
    },
  );

  test(
    'incomplete labels are rejected instead of mixing in an estimate',
    () async {
      final lookup = OpenFoodFactsProductLookup(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'product': {
                'code': '8901234567890',
                'product_name': 'Dark Chocolate Protein Bar',
                'brands': 'Nourish Test Foods',
                'serving_size': '1 bar (40 g)',
                'serving_quantity': 40,
                'nutriments': {'energy-kcal_100g': 500, 'proteins_100g': 20},
              },
            }),
            200,
          );
        }),
      );

      final match = await lookup.lookup(_visual(barcode: '8901234567890'));

      expect(match, isNull);
    },
  );

  test('an unavailable product database returns no match safely', () async {
    final lookup = OpenFoodFactsProductLookup(
      client: MockClient((request) async => http.Response('unavailable', 503)),
    );

    final match = await lookup.lookup(_visual(barcode: '8901234567890'));

    expect(match, isNull);
  });
}

FoodAnalysis _visual({String barcode = ''}) => FoodAnalysis(
  isFood: true,
  mealName: 'Nourish Test Foods Dark Chocolate Protein Bar',
  items: const [
    FoodItemEstimate(
      name: 'Dark Chocolate Protein Bar',
      quantity: '1 bar',
      estimatedGrams: 40,
    ),
  ],
  calories: 210,
  protein: 7,
  carbs: 21,
  fat: 11,
  fiber: 3,
  sugar: 7,
  sodiumMg: 55,
  confidence: 0.8,
  assumptions: const [],
  isPackagedFood: true,
  brandName: 'Nourish Test Foods',
  productName: 'Dark Chocolate Protein Bar',
  barcode: barcode,
);

Map<String, dynamic> _searchProduct({
  required String brand,
  required String name,
}) => {
  'code': '8901234567890',
  'product_name': name,
  'brands': [brand],
  'serving_size': '1 bar (40 g)',
  'serving_quantity': 40,
  'serving_quantity_unit': 'g',
  'nutriments': {
    'energy-kcal_100g': 500,
    'proteins_100g': 20,
    'carbohydrates_100g': 50,
    'fat_100g': 25,
  },
};
