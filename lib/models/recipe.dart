class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.dietType,
    required this.mealType,
    required this.emoji,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.prepMinutes,
    required this.servings,
    required this.tags,
    required this.goalTags,
    required this.allergens,
    required this.ingredients,
    required this.steps,
    this.imageAsset = '',
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final String description;
  final String dietType;
  final String mealType;
  final String emoji;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final int prepMinutes;
  final int servings;
  final List<String> tags;
  final List<String> goalTags;
  final List<String> allergens;
  final List<String> ingredients;
  final List<String> steps;
  final String imageAsset;
  final String imageUrl;

  bool get hasImage => imageAsset.isNotEmpty || imageUrl.isNotEmpty;

  bool get isComplete =>
      hasImage &&
      name.isNotEmpty &&
      description.isNotEmpty &&
      dietType.isNotEmpty &&
      mealType.isNotEmpty &&
      calories > 0 &&
      protein > 0 &&
      carbs > 0 &&
      fat > 0 &&
      fiber > 0 &&
      prepMinutes > 0 &&
      servings > 0 &&
      ingredients.length >= 3 &&
      steps.length >= 2;

  factory Recipe.fromMap(String id, Map<String, dynamic> map) {
    int integer(String key) => (map[key] as num?)?.round() ?? 0;
    List<String> strings(String key) =>
        List<String>.from(map[key] as List? ?? const <String>[]);

    return Recipe(
      id: id,
      name: map['name'] as String? ?? 'Untitled recipe',
      description: map['description'] as String? ?? '',
      dietType: map['dietType'] as String? ?? '',
      mealType: map['mealType'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '',
      calories: integer('calories'),
      protein: integer('protein'),
      carbs: integer('carbs'),
      fat: integer('fat'),
      fiber: integer('fiber'),
      prepMinutes: integer('prepMinutes'),
      servings: integer('servings'),
      tags: strings('tags'),
      goalTags: strings('goalTags'),
      allergens: strings('allergens'),
      ingredients: strings('ingredients'),
      steps: strings('steps'),
      imageAsset: map['imageAsset'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'dietType': dietType,
    'mealType': mealType,
    'emoji': emoji,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'prepMinutes': prepMinutes,
    'servings': servings,
    'tags': tags,
    'goalTags': goalTags,
    'allergens': allergens,
    'ingredients': ingredients,
    'steps': steps,
    'imageAsset': imageAsset,
    'imageUrl': imageUrl,
  };

  Recipe mergeWithFallback(Recipe fallback) => Recipe(
    id: id,
    name: name == 'Untitled recipe' || name.isEmpty ? fallback.name : name,
    description: description.isEmpty ? fallback.description : description,
    dietType: dietType.isEmpty ? fallback.dietType : dietType,
    mealType: mealType.isEmpty || mealType == 'Any meal'
        ? fallback.mealType
        : mealType,
    emoji: emoji.isEmpty ? fallback.emoji : emoji,
    calories: calories > 0 ? calories : fallback.calories,
    protein: protein > 0 ? protein : fallback.protein,
    carbs: carbs > 0 ? carbs : fallback.carbs,
    fat: fat > 0 ? fat : fallback.fat,
    fiber: fiber > 0 ? fiber : fallback.fiber,
    prepMinutes: prepMinutes > 0 ? prepMinutes : fallback.prepMinutes,
    servings: servings > 0 ? servings : fallback.servings,
    tags: tags.isEmpty ? fallback.tags : tags,
    goalTags: goalTags.isEmpty ? fallback.goalTags : goalTags,
    allergens: allergens.isEmpty ? fallback.allergens : allergens,
    ingredients: ingredients.isEmpty ? fallback.ingredients : ingredients,
    steps: steps.isEmpty ? fallback.steps : steps,
    imageAsset: imageAsset.isEmpty ? fallback.imageAsset : imageAsset,
    imageUrl: imageUrl.isEmpty ? fallback.imageUrl : imageUrl,
  );

  bool supportsDiet(String diet) {
    return switch (diet) {
      'Vegan' => dietType == 'Vegan',
      'Vegetarian' => dietType == 'Vegetarian' || dietType == 'Vegan',
      _ => true,
    };
  }
}
