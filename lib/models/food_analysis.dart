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

class NutritionSourceRef {
  const NutritionSourceRef({required this.title, required this.url});

  final String title;
  final String url;

  factory NutritionSourceRef.fromMap(Map<String, dynamic> map) {
    return NutritionSourceRef(
      title: map['title'] as String? ?? 'Nutrition source',
      url: map['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'title': title, 'url': url};
}

class ProductNutritionMatch {
  const ProductNutritionMatch({
    required this.productName,
    required this.brandName,
    required this.barcode,
    required this.servingLabel,
    required this.servingGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodiumMg,
    required this.matchConfidence,
    required this.nutritionSource,
    required this.sources,
    this.sourceNote = '',
    this.searchEntryPointHtml = '',
  });

  final String productName;
  final String brandName;
  final String barcode;
  final String servingLabel;
  final double servingGrams;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final int sodiumMg;
  final double matchConfidence;
  final String nutritionSource;
  final List<NutritionSourceRef> sources;
  final String sourceNote;
  final String searchEntryPointHtml;
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
    this.isPackagedFood = false,
    this.brandName = '',
    this.productName = '',
    this.barcode = '',
    this.nutritionSource = 'visualEstimate',
    this.sourceServing = '',
    this.sourceMatchConfidence = 0,
    this.sourceNote = '',
    this.sources = const [],
    this.searchEntryPointHtml = '',
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
  final bool isPackagedFood;
  final String brandName;
  final String productName;
  final String barcode;
  final String nutritionSource;
  final String sourceServing;
  final double sourceMatchConfidence;
  final String sourceNote;
  final List<NutritionSourceRef> sources;
  final String searchEntryPointHtml;

  bool get hasVerifiedOnlineNutrition =>
      nutritionSource == 'openFoodFacts' ||
      nutritionSource == 'googleSearch' ||
      nutritionSource == 'publicWebLabel';

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
      isPackagedFood: json['isPackagedFood'] as bool? ?? false,
      brandName: json['brandName'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      nutritionSource: json['nutritionSource'] as String? ?? 'visualEstimate',
      sourceServing: json['sourceServing'] as String? ?? '',
      sourceMatchConfidence: number('sourceMatchConfidence').clamp(0, 1),
      sourceNote: json['sourceNote'] as String? ?? '',
      sources: (json['sources'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (source) =>
                NutritionSourceRef.fromMap(Map<String, dynamic>.from(source)),
          )
          .toList(),
      searchEntryPointHtml: json['searchEntryPointHtml'] as String? ?? '',
    );
  }

  FoodAnalysis withProductMatch(ProductNutritionMatch match) {
    final displayName = [
      match.brandName.trim(),
      match.productName.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    return FoodAnalysis(
      isFood: true,
      mealName: displayName.isEmpty ? mealName : displayName,
      items: [
        FoodItemEstimate(
          name: displayName.isEmpty ? mealName : displayName,
          quantity: match.servingLabel,
          estimatedGrams: match.servingGrams,
        ),
      ],
      calories: match.calories,
      protein: match.protein,
      carbs: match.carbs,
      fat: match.fat,
      fiber: match.fiber,
      sugar: match.sugar,
      sodiumMg: match.sodiumMg,
      confidence: match.matchConfidence,
      assumptions: [
        'Values apply to ${match.servingLabel}. Confirm the exact flavour and how many servings you ate.',
      ],
      isPackagedFood: true,
      brandName: match.brandName,
      productName: match.productName,
      barcode: match.barcode,
      nutritionSource: match.nutritionSource,
      sourceServing: match.servingLabel,
      sourceMatchConfidence: match.matchConfidence,
      sourceNote: match.sourceNote,
      sources: match.sources,
      searchEntryPointHtml: match.searchEntryPointHtml,
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
      isPackagedFood: isPackagedFood,
      brandName: brandName,
      productName: productName,
      barcode: barcode,
      nutritionSource: nutritionSource,
      sourceServing: sourceServing,
      sourceMatchConfidence: sourceMatchConfidence,
      sourceNote: sourceNote,
      sources: sources,
      searchEntryPointHtml: searchEntryPointHtml,
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
    'isPackagedFood': isPackagedFood,
    'brandName': brandName,
    'productName': productName,
    'barcode': barcode,
    'nutritionSource': nutritionSource,
    'sourceServing': sourceServing,
    'sourceMatchConfidence': sourceMatchConfidence,
    'sourceNote': sourceNote,
    'sources': sources.map((source) => source.toMap()).toList(),
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
