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

  factory Recipe.fromMap(String id, Map<String, dynamic> map) {
    int integer(String key) => (map[key] as num?)?.round() ?? 0;
    List<String> strings(String key) =>
        List<String>.from(map[key] as List? ?? const <String>[]);

    return Recipe(
      id: id,
      name: map['name'] as String? ?? 'Untitled recipe',
      description: map['description'] as String? ?? '',
      dietType: map['dietType'] as String? ?? 'Vegetarian',
      mealType: map['mealType'] as String? ?? 'Any meal',
      emoji: map['emoji'] as String? ?? '🥗',
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
  };

  bool supportsDiet(String diet) {
    return switch (diet) {
      'Vegan' => dietType == 'Vegan',
      'Vegetarian' => dietType == 'Vegetarian' || dietType == 'Vegan',
      _ => true,
    };
  }
}
