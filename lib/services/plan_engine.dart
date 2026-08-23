import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';

class PlanEngine {
  const PlanEngine();

  List<Recipe> recommendRecipes(
    List<Recipe> recipes,
    UserProfile profile, {
    String mealFilter = 'All',
  }) {
    final blocked = profile.avoidFoods
        .map((item) => item.toLowerCase())
        .toSet();
    final eligible = recipes.where((recipe) {
      if (!recipe.supportsDiet(profile.dietType)) return false;
      if (mealFilter != 'All' && recipe.mealType != mealFilter) return false;
      if (recipe.allergens.any(
        (item) => blocked.contains(item.toLowerCase()),
      )) {
        return false;
      }
      return true;
    }).toList();

    eligible.sort((a, b) {
      final aScore = _recipeScore(a, profile);
      final bScore = _recipeScore(b, profile);
      return bScore.compareTo(aScore);
    });
    return eligible;
  }

  int _recipeScore(Recipe recipe, UserProfile profile) {
    var score = recipe.goalTags.contains(profile.goal) ? 30 : 0;
    if (profile.goal == 'Build muscle') score += recipe.protein;
    if (profile.goal == 'Lose fat') {
      score += recipe.fiber * 2;
      score += recipe.protein;
      score -= recipe.calories ~/ 50;
    }
    if (profile.goal == 'Maintain weight') {
      score += recipe.fiber + recipe.protein;
    }
    if (recipe.tags.contains('Quick')) score += 3;
    return score;
  }

  WorkoutPlan buildWorkoutPlan(UserProfile profile) {
    const weekOrder = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final selectedDays =
        profile.availableWorkoutDays.where(weekOrder.contains).toSet().toList()
          ..sort(
            (first, second) =>
                weekOrder.indexOf(first).compareTo(weekOrder.indexOf(second)),
          );
    final availableDays = selectedDays.length >= 2
        ? selectedDays.take(6).toList()
        : suggestedWorkoutDays(profile.workoutDays);
    final dayCount = availableDays.length;
    final templates = switch (profile.goal) {
      'Build muscle' => _muscleTemplates,
      'Lose fat' => _fatLossTemplates,
      _ => _fitnessTemplates,
    };

    final days = List<WorkoutDay>.generate(dayCount, (index) {
      final template = templates[index % templates.length];
      final items = List<ExerciseItem>.from(template.exercises);
      final wantsHomeOnly =
          profile.equipment.length == 1 &&
          profile.equipment.contains('Bodyweight');
      final adjusted = wantsHomeOnly
          ? items.map(_bodyweightAlternative).toList()
          : items;
      return WorkoutDay(
        dayLabel: availableDays[index],
        title: template.title,
        subtitle: template.subtitle,
        durationMinutes: profile.sessionMinutes,
        exercises: _fitToDuration(adjusted, profile.sessionMinutes),
      );
    });

    return WorkoutPlan(goal: profile.goal, daysPerWeek: dayCount, days: days);
  }

  ExerciseItem _bodyweightAlternative(ExerciseItem exercise) {
    const swaps = {
      'Dumbbell goblet squat': ExerciseItem(
        name: 'Tempo bodyweight squat',
        detail: '4 × 12 · 3 sec down',
        focus: 'Quads · glutes',
        icon: '🦵',
      ),
      'One-arm dumbbell row': ExerciseItem(
        name: 'Prone Y-T-W raises',
        detail: '3 × 8 each shape',
        focus: 'Upper back',
        icon: '🪽',
      ),
      'Dumbbell Romanian deadlift': ExerciseItem(
        name: 'Single-leg hip hinge',
        detail: '3 × 10 each side',
        focus: 'Hamstrings · balance',
        icon: '⚖️',
      ),
      'Dumbbell shoulder press': ExerciseItem(
        name: 'Pike push-up',
        detail: '3 × 8-12',
        focus: 'Shoulders · triceps',
        icon: '🔺',
      ),
    };
    return swaps[exercise.name] ?? exercise;
  }

  List<ExerciseItem> _fitToDuration(List<ExerciseItem> exercises, int minutes) {
    final count = switch (minutes) {
      <= 20 => 4,
      <= 35 => 5,
      _ => 6,
    };
    return exercises.take(count).toList();
  }
}

const _muscleTemplates = <WorkoutDay>[
  WorkoutDay(
    dayLabel: '',
    title: 'Upper body strength',
    subtitle: 'Controlled reps · 60 sec rest',
    durationMinutes: 35,
    exercises: [
      ExerciseItem(
        name: 'Push-up',
        detail: '4 × 8-15',
        focus: 'Chest · triceps',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'One-arm dumbbell row',
        detail: '4 × 10 each side',
        focus: 'Back · biceps',
        icon: '🪽',
      ),
      ExerciseItem(
        name: 'Dumbbell shoulder press',
        detail: '3 × 10-12',
        focus: 'Shoulders · triceps',
        icon: '🏋️',
      ),
      ExerciseItem(
        name: 'Close-grip push-up',
        detail: '3 × 8-12',
        focus: 'Triceps · chest',
        icon: '🔥',
      ),
      ExerciseItem(
        name: 'Reverse snow angel',
        detail: '3 × 12',
        focus: 'Upper back · posture',
        icon: '❄️',
      ),
      ExerciseItem(
        name: 'Dead bug',
        detail: '3 × 10 each side',
        focus: 'Core control',
        icon: '🪲',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Lower body power',
    subtitle: 'Strong legs · steady tempo',
    durationMinutes: 35,
    exercises: [
      ExerciseItem(
        name: 'Dumbbell goblet squat',
        detail: '4 × 10-12',
        focus: 'Quads · glutes',
        icon: '🦵',
      ),
      ExerciseItem(
        name: 'Dumbbell Romanian deadlift',
        detail: '4 × 10',
        focus: 'Hamstrings · glutes',
        icon: '⚡',
      ),
      ExerciseItem(
        name: 'Reverse lunge',
        detail: '3 × 10 each side',
        focus: 'Legs · balance',
        icon: '↩️',
      ),
      ExerciseItem(
        name: 'Glute bridge',
        detail: '3 × 15',
        focus: 'Glutes · core',
        icon: '🌉',
      ),
      ExerciseItem(
        name: 'Calf raise',
        detail: '3 × 18',
        focus: 'Calves',
        icon: '⬆️',
      ),
      ExerciseItem(
        name: 'Side plank',
        detail: '3 × 30 sec each',
        focus: 'Obliques',
        icon: '📐',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Full body builder',
    subtitle: 'Compound focus · quality first',
    durationMinutes: 35,
    exercises: [
      ExerciseItem(
        name: 'Dumbbell goblet squat',
        detail: '3 × 12',
        focus: 'Legs · core',
        icon: '🦵',
      ),
      ExerciseItem(
        name: 'Push-up',
        detail: '3 × max clean reps',
        focus: 'Chest · triceps',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'One-arm dumbbell row',
        detail: '3 × 12 each side',
        focus: 'Back · biceps',
        icon: '🪽',
      ),
      ExerciseItem(
        name: 'Dumbbell Romanian deadlift',
        detail: '3 × 12',
        focus: 'Posterior chain',
        icon: '⚡',
      ),
      ExerciseItem(
        name: 'Dumbbell shoulder press',
        detail: '3 × 10',
        focus: 'Shoulders',
        icon: '🏋️',
      ),
      ExerciseItem(
        name: 'Plank shoulder tap',
        detail: '3 × 16 total',
        focus: 'Core · stability',
        icon: '🧱',
      ),
    ],
  ),
];

const _fatLossTemplates = <WorkoutDay>[
  WorkoutDay(
    dayLabel: '',
    title: 'Full body metabolic',
    subtitle: '40 sec work · 20 sec reset',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'Squat to reach',
        detail: '4 × 40 sec',
        focus: 'Legs · cardio',
        icon: '🚀',
      ),
      ExerciseItem(
        name: 'Incline push-up',
        detail: '4 × 40 sec',
        focus: 'Upper body',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'Mountain climber',
        detail: '4 × 40 sec',
        focus: 'Core · cardio',
        icon: '⛰️',
      ),
      ExerciseItem(
        name: 'Reverse lunge',
        detail: '4 × 40 sec',
        focus: 'Legs · balance',
        icon: '↩️',
      ),
      ExerciseItem(
        name: 'Plank shoulder tap',
        detail: '4 × 40 sec',
        focus: 'Core · stability',
        icon: '🧱',
      ),
      ExerciseItem(
        name: 'Fast feet',
        detail: '4 × 40 sec',
        focus: 'Cardio · agility',
        icon: '👟',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Strength & sculpt',
    subtitle: '45 sec work · controlled form',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'Dumbbell goblet squat',
        detail: '3 × 12',
        focus: 'Quads · glutes',
        icon: '🦵',
      ),
      ExerciseItem(
        name: 'One-arm dumbbell row',
        detail: '3 × 12 each side',
        focus: 'Back · biceps',
        icon: '🪽',
      ),
      ExerciseItem(
        name: 'Dumbbell Romanian deadlift',
        detail: '3 × 12',
        focus: 'Hamstrings · glutes',
        icon: '⚡',
      ),
      ExerciseItem(
        name: 'Incline push-up',
        detail: '3 × 10-15',
        focus: 'Chest · triceps',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'Dead bug',
        detail: '3 × 10 each side',
        focus: 'Core control',
        icon: '🪲',
      ),
      ExerciseItem(
        name: 'Marching bridge',
        detail: '3 × 16 total',
        focus: 'Glutes · core',
        icon: '🌉',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Low-impact cardio',
    subtitle: 'Apartment friendly · no jumping',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'Power march',
        detail: '5 × 60 sec',
        focus: 'Cardio',
        icon: '🥁',
      ),
      ExerciseItem(
        name: 'Step jack',
        detail: '5 × 45 sec',
        focus: 'Full body',
        icon: '⭐',
      ),
      ExerciseItem(
        name: 'Knee drive',
        detail: '4 × 40 sec each',
        focus: 'Core · cardio',
        icon: '⬆️',
      ),
      ExerciseItem(
        name: 'Lateral step & reach',
        detail: '4 × 50 sec',
        focus: 'Agility',
        icon: '↔️',
      ),
      ExerciseItem(
        name: 'Standing mountain climber',
        detail: '4 × 45 sec',
        focus: 'Core · cardio',
        icon: '⛰️',
      ),
      ExerciseItem(
        name: 'Boxer shuffle',
        detail: '4 × 60 sec',
        focus: 'Cardio',
        icon: '🥊',
      ),
    ],
  ),
];

const _fitnessTemplates = <WorkoutDay>[
  WorkoutDay(
    dayLabel: '',
    title: 'Balanced full body',
    subtitle: 'Strength · movement · core',
    durationMinutes: 35,
    exercises: [
      ExerciseItem(
        name: 'Dumbbell goblet squat',
        detail: '3 × 12',
        focus: 'Legs · core',
        icon: '🦵',
      ),
      ExerciseItem(
        name: 'Push-up',
        detail: '3 × 8-15',
        focus: 'Chest · triceps',
        icon: '💪',
      ),
      ExerciseItem(
        name: 'One-arm dumbbell row',
        detail: '3 × 12 each side',
        focus: 'Back · biceps',
        icon: '🪽',
      ),
      ExerciseItem(
        name: 'Reverse lunge',
        detail: '3 × 10 each side',
        focus: 'Legs · balance',
        icon: '↩️',
      ),
      ExerciseItem(
        name: 'Dead bug',
        detail: '3 × 10 each side',
        focus: 'Core control',
        icon: '🪲',
      ),
      ExerciseItem(
        name: 'Power march',
        detail: '4 × 45 sec',
        focus: 'Cardio',
        icon: '🥁',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Mobility & core',
    subtitle: 'Restore range · move well',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'World’s greatest stretch',
        detail: '2 × 5 each side',
        focus: 'Hips · thoracic',
        icon: '🌍',
      ),
      ExerciseItem(
        name: '90/90 hip switch',
        detail: '3 × 8',
        focus: 'Hip mobility',
        icon: '🔄',
      ),
      ExerciseItem(
        name: 'Bird dog',
        detail: '3 × 10 each side',
        focus: 'Core · back',
        icon: '🐦',
      ),
      ExerciseItem(
        name: 'Side plank',
        detail: '3 × 25 sec each',
        focus: 'Obliques',
        icon: '📐',
      ),
      ExerciseItem(
        name: 'Glute bridge',
        detail: '3 × 15',
        focus: 'Glutes · core',
        icon: '🌉',
      ),
      ExerciseItem(
        name: 'Child’s pose breathing',
        detail: '2 × 60 sec',
        focus: 'Recovery',
        icon: '🌿',
      ),
    ],
  ),
  WorkoutDay(
    dayLabel: '',
    title: 'Cardio conditioning',
    subtitle: 'Steady intervals · finish fresh',
    durationMinutes: 30,
    exercises: [
      ExerciseItem(
        name: 'Power march',
        detail: '4 × 60 sec',
        focus: 'Cardio',
        icon: '🥁',
      ),
      ExerciseItem(
        name: 'Squat to reach',
        detail: '4 × 40 sec',
        focus: 'Full body',
        icon: '🚀',
      ),
      ExerciseItem(
        name: 'Step jack',
        detail: '4 × 45 sec',
        focus: 'Cardio',
        icon: '⭐',
      ),
      ExerciseItem(
        name: 'Mountain climber',
        detail: '4 × 35 sec',
        focus: 'Core · cardio',
        icon: '⛰️',
      ),
      ExerciseItem(
        name: 'Lateral step & reach',
        detail: '4 × 45 sec',
        focus: 'Agility',
        icon: '↔️',
      ),
      ExerciseItem(
        name: 'Standing cooldown flow',
        detail: '5 minutes',
        focus: 'Recovery',
        icon: '🌿',
      ),
    ],
  ),
];
