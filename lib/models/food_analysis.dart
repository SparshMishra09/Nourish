class FoodItemEstimate {
  const FoodItemEstimate({
    required this.name,
    required this.quantity,
    required this.estimatedGrams,
  });

  final String name;
  final String quantity;
  final double estimatedGrams;

  factory FoodItemEstimate.fromJson(Map<String, dynamic> json) {
    return FoodItemEstimate(
      name: json['name'] as String? ?? 'Unknown item',
      quantity: json['quantity'] as String? ?? 'Visible serving',
      estimatedGrams: (json['estimatedGrams'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap({double scale = 1}) => {
    'name': name,
    'quantity': quantity,
    'estimatedGrams': (estimatedGrams * scale).round(),
  };
}

class FoodAnalysis {
  const FoodAnalysis({
    required this.isFood,
    required this.mealName,
    required this.items,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodiumMg,
    required this.confidence,
    required this.assumptions,
    this.portionMultiplier = 1,
  });

  final bool isFood;
  final String mealName;
  final List<FoodItemEstimate> items;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final int sodiumMg;
  final double confidence;
  final List<String> assumptions;
  final double portionMultiplier;

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return FoodAnalysis(
      isFood: json['isFood'] as bool? ?? false,
      mealName: json['mealName'] as String? ?? 'Scanned meal',
      items: (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                FoodItemEstimate.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      calories: number('calories').round(),
      protein: number('protein'),
      carbs: number('carbs'),
      fat: number('fat'),
      fiber: number('fiber'),
      sugar: number('sugar'),
      sodiumMg: number('sodiumMg').round(),
      confidence: number('confidence').clamp(0, 1),
      assumptions: List<String>.from(
        (json['assumptions'] as List? ?? const []).whereType<String>(),
      ),
    );
  }

  FoodAnalysis scaled(double multiplier) {
    final safeMultiplier = multiplier.clamp(0.25, 3.0);
    return FoodAnalysis(
      isFood: isFood,
      mealName: mealName,
      items: items,
      calories: (calories * safeMultiplier).round(),
      protein: protein * safeMultiplier,
      carbs: carbs * safeMultiplier,
      fat: fat * safeMultiplier,
      fiber: fiber * safeMultiplier,
      sugar: sugar * safeMultiplier,
      sodiumMg: (sodiumMg * safeMultiplier).round(),
      confidence: confidence,
      assumptions: assumptions,
      portionMultiplier: safeMultiplier,
    );
  }

  Map<String, dynamic> toLogMap() => {
    'source': 'photoAnalysis',
    'name': mealName,
    'items': items.map((item) => item.toMap(scale: portionMultiplier)).toList(),
    'portionMultiplier': portionMultiplier,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
    'sodiumMg': sodiumMg,
    'confidence': confidence,
    'assumptions': assumptions,
  };
}

class DailyNutrition {
  const DailyNutrition({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.mealCount = 0,
  });

  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int mealCount;
}
