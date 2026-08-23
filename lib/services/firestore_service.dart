import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/food_analysis.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? database})
    : _database = database ?? FirebaseFirestore.instance;

  final FirebaseFirestore _database;

  Stream<UserProfile?> watchProfile(String uid) {
    return _database.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : UserProfile.fromMap(uid, data);
    });
  }

  Future<UserProfile?> getProfile(String uid) async {
    final snapshot = await _database.collection('users').doc(uid).get();
    final data = snapshot.data();
    return data == null ? null : UserProfile.fromMap(uid, data);
  }

  Future<void> saveProfile(UserProfile profile) {
    return _database.collection('users').doc(profile.uid).set({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Recipe>> getRecipes() async {
    try {
      final snapshot = await _database.collection('recipes').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((document) => Recipe.fromMap(document.id, document.data()))
            .toList();
      }
    } on FirebaseException {
      // The bundled catalog keeps the experience useful when temporarily offline.
    }
    return loadBundledRecipes();
  }

  Future<List<Recipe>> loadBundledRecipes() async {
    final source = await rootBundle.loadString('assets/data/recipes.json');
    final records = jsonDecode(source) as List<dynamic>;
    return records.map((record) {
      final map = Map<String, dynamic>.from(record as Map);
      return Recipe.fromMap(map.remove('id') as String, map);
    }).toList();
  }

  Future<void> saveWorkoutPlan(String uid, WorkoutPlan plan) {
    return _database.collection('workoutPlans').doc(uid).set({
      ...plan.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<WorkoutPlan?> getWorkoutPlan(String uid) async {
    final snapshot = await _database.collection('workoutPlans').doc(uid).get();
    final data = snapshot.data();
    return data == null ? null : WorkoutPlan.fromMap(data);
  }

  Stream<DailyNutrition> watchTodayNutrition(String uid, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final start = DateTime(current.year, current.month, current.day);
    return _database
        .collection('users')
        .doc(uid)
        .collection('mealLogs')
        .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .snapshots()
        .map((snapshot) {
          var calories = 0;
          var protein = 0.0;
          var carbs = 0.0;
          var fat = 0.0;
          var fiber = 0.0;
          for (final document in snapshot.docs) {
            final data = document.data();
            calories += (data['calories'] as num?)?.round() ?? 0;
            protein += (data['protein'] as num?)?.toDouble() ?? 0;
            carbs += (data['carbs'] as num?)?.toDouble() ?? 0;
            fat += (data['fat'] as num?)?.toDouble() ?? 0;
            fiber += (data['fiber'] as num?)?.toDouble() ?? 0;
          }
          return DailyNutrition(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            mealCount: snapshot.docs.length,
          );
        });
  }

  Future<void> logScannedMeal(String uid, FoodAnalysis analysis) {
    return _database.collection('users').doc(uid).collection('mealLogs').add({
      ...analysis.toLogMap(),
      'dayKey': _dayKey(DateTime.now()),
      'loggedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> watchTodayWater(String uid, {DateTime? now}) {
    final key = _dayKey(now ?? DateTime.now());
    return _database
        .collection('users')
        .doc(uid)
        .collection('dailyStats')
        .doc(key)
        .snapshots()
        .map((snapshot) => (snapshot.data()?['waterMl'] as num?)?.round() ?? 0);
  }

  Future<void> addWater(String uid, int amountMl) async {
    final key = _dayKey(DateTime.now());
    final reference = _database
        .collection('users')
        .doc(uid)
        .collection('dailyStats')
        .doc(key);
    await _database.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final current = (snapshot.data()?['waterMl'] as num?)?.round() ?? 0;
      transaction.set(reference, {
        'waterMl': (current + amountMl).clamp(0, 10000),
        'dayKey': key,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> logMeal(String uid, Recipe recipe) {
    return _database.collection('users').doc(uid).collection('mealLogs').add({
      'recipeId': recipe.id,
      'name': recipe.name,
      'calories': recipe.calories,
      'protein': recipe.protein,
      'loggedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeWorkout(String uid, WorkoutDay day) {
    return _database
        .collection('users')
        .doc(uid)
        .collection('workoutLogs')
        .add({
          'title': day.title,
          'durationMinutes': day.durationMinutes,
          'exerciseCount': day.exercises.length,
          'completedAt': FieldValue.serverTimestamp(),
        });
  }

  static String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
