import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/daily_goal.dart';
import '../models/food_analysis.dart';
import '../models/recipe.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/plan_engine.dart';
import '../widgets/goal_celebration_dialog.dart';
import '../widgets/reminder_settings_sheet.dart';
import '../widgets/shared_ui.dart';
import 'dashboard_screen.dart';
import 'food_scan_screen.dart';
import 'nutrition_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'recipe_detail_screen.dart';
import 'workout_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.profile,
    required this.authService,
    required this.firestoreService,
    this.userPhotoUrl,
  });

  final UserProfile profile;
  final AuthService authService;
  final FirestoreService firestoreService;
  final String? userPhotoUrl;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _engine = PlanEngine();
  int _selectedIndex = 0;
  List<Recipe> _recipes = const [];
  WorkoutPlan? _plan;
  bool _loading = true;
  DailyNutrition _todayNutrition = const DailyNutrition();
  int _waterLoggedMl = 0;
  int _completedWorkouts = 0;
  bool _todayWorkoutCompleted = false;
  bool _todayGoalRecorded = false;
  bool _goalCheckInFlight = false;
  bool _reminderSettingsLoaded = false;
  bool _reminderSaveInProgress = false;
  Set<String> _completedDayKeys = const {};
  ReminderSettings _reminderSettings = const ReminderSettings();
  StreamSubscription<DailyNutrition>? _nutritionSubscription;
  StreamSubscription<int>? _waterSubscription;
  StreamSubscription<bool>? _todayWorkoutSubscription;
  StreamSubscription<int>? _workoutCountSubscription;
  StreamSubscription<bool>? _goalSubscription;
  StreamSubscription<Set<String>>? _completionDaysSubscription;
  StreamSubscription<ReminderSettings>? _reminderSubscription;

  @override
  void initState() {
    super.initState();
    _watchDailyProgress();
    _loadPlan();
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.uid != widget.profile.uid) {
      _todayWorkoutCompleted = false;
      _todayGoalRecorded = false;
      _completedDayKeys = const {};
      _reminderSettingsLoaded = false;
      _watchDailyProgress();
    }
    if (_planInputsChanged(oldWidget.profile, widget.profile)) {
      _loadPlan();
      if (_reminderSettingsLoaded) {
        unawaited(
          NotificationService.instance.scheduleWorkoutReminders(
            profile: widget.profile,
            settings: _reminderSettings,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nutritionSubscription?.cancel();
    _waterSubscription?.cancel();
    _todayWorkoutSubscription?.cancel();
    _workoutCountSubscription?.cancel();
    _goalSubscription?.cancel();
    _completionDaysSubscription?.cancel();
    _reminderSubscription?.cancel();
    super.dispose();
  }

  void _watchDailyProgress() {
    _nutritionSubscription?.cancel();
    _waterSubscription?.cancel();
    _todayWorkoutSubscription?.cancel();
    _workoutCountSubscription?.cancel();
    _goalSubscription?.cancel();
    _completionDaysSubscription?.cancel();
    _reminderSubscription?.cancel();
    _nutritionSubscription = widget.firestoreService
        .watchTodayNutrition(widget.profile.uid)
        .listen((nutrition) {
          if (!mounted) return;
          setState(() => _todayNutrition = nutrition);
          unawaited(_evaluateDailyGoal());
        });
    _waterSubscription = widget.firestoreService
        .watchTodayWater(widget.profile.uid)
        .listen((water) {
          if (!mounted) return;
          setState(() => _waterLoggedMl = water);
          unawaited(_evaluateDailyGoal());
        });
    _todayWorkoutSubscription = widget.firestoreService
        .watchTodayWorkoutComplete(widget.profile.uid)
        .listen((completed) {
          if (!mounted) return;
          setState(() => _todayWorkoutCompleted = completed);
          unawaited(_evaluateDailyGoal());
        });
    _workoutCountSubscription = widget.firestoreService
        .watchThisWeekWorkoutCount(widget.profile.uid)
        .listen((count) {
          if (mounted) setState(() => _completedWorkouts = count);
        });
    _goalSubscription = widget.firestoreService
        .watchTodayGoalCompleted(widget.profile.uid)
        .listen((completed) {
          if (!mounted) return;
          setState(() => _todayGoalRecorded = completed);
          if (!completed) unawaited(_evaluateDailyGoal());
        });
    _completionDaysSubscription = widget.firestoreService
        .watchCompletedDayKeys(widget.profile.uid)
        .listen((days) {
          if (mounted) setState(() => _completedDayKeys = days);
        });
    _reminderSubscription = widget.firestoreService
        .watchReminderSettings(widget.profile.uid)
        .listen((settings) {
          if (!mounted) return;
          final isFirstLoad = !_reminderSettingsLoaded;
          setState(() {
            _reminderSettings = settings;
            _reminderSettingsLoaded = true;
          });
          if (isFirstLoad && !_reminderSaveInProgress) {
            unawaited(
              NotificationService.instance.scheduleWorkoutReminders(
                profile: widget.profile,
                settings: settings,
              ),
            );
          }
        });
  }

  Future<void> _evaluateDailyGoal() async {
    if (!mounted || _todayGoalRecorded || _goalCheckInFlight) return;
    final todayLabel = const [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ][DateTime.now().weekday - 1];
    final evaluation = DailyGoalEvaluator.evaluate(
      profile: widget.profile,
      nutrition: _todayNutrition,
      waterLoggedMl: _waterLoggedMl,
      workoutScheduled: widget.profile.availableWorkoutDays.contains(
        todayLabel,
      ),
      workoutCompleted: _todayWorkoutCompleted,
    );
    if (!evaluation.isComplete) return;

    _goalCheckInFlight = true;
    try {
      final newlyCompleted = await widget.firestoreService
          .markTodayGoalComplete(widget.profile.uid);
      if (!mounted) return;
      setState(() {
        _todayGoalRecorded = true;
        _completedDayKeys = {
          ..._completedDayKeys,
          FirestoreService.dayKey(DateTime.now()),
        };
      });
      if (newlyCompleted) {
        await showGoalCelebration(context, name: widget.profile.name);
      }
    } catch (_) {
      // Progress remains visible and the next nutrition, water, or workout
      // update will safely try the private completion record again.
    } finally {
      _goalCheckInFlight = false;
    }
  }

  bool _planInputsChanged(UserProfile oldProfile, UserProfile newProfile) {
    return oldProfile.goal != newProfile.goal ||
        oldProfile.dietType != newProfile.dietType ||
        oldProfile.workoutDays != newProfile.workoutDays ||
        oldProfile.availableWorkoutDays.join('|') !=
            newProfile.availableWorkoutDays.join('|') ||
        oldProfile.sessionMinutes != newProfile.sessionMinutes ||
        oldProfile.avoidFoods.join('|') != newProfile.avoidFoods.join('|') ||
        oldProfile.equipment.join('|') != newProfile.equipment.join('|');
  }

  Future<void> _loadPlan() async {
    setState(() => _loading = true);
    try {
      final allRecipes = await widget.firestoreService.getRecipes();
      final recommended = _engine.recommendRecipes(allRecipes, widget.profile);
      final plan = _engine.buildWorkoutPlan(widget.profile);
      unawaited(
        widget.firestoreService
            .saveWorkoutPlan(widget.profile.uid, plan)
            .catchError((_) {}),
      );
      if (!mounted) return;
      setState(() {
        _recipes = recommended;
        _plan = plan;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _plan = _engine.buildWorkoutPlan(widget.profile);
        _loading = false;
      });
      showAppMessage(
        context,
        'Some cloud data could not be loaded. Showing your local plan.',
      );
    }
  }

  Future<void> _logScannedMeal(FoodAnalysis analysis) async {
    await widget.firestoreService.logScannedMeal(widget.profile.uid, analysis);
    if (mounted) setState(() => _selectedIndex = 0);
  }

  Future<void> _completeWorkout(WorkoutDay day) async {
    await widget.firestoreService.completeWorkout(widget.profile.uid, day);
    if (mounted) {
      setState(() => _todayWorkoutCompleted = true);
      unawaited(_evaluateDailyGoal());
    }
  }

  Future<void> _openReminderSettings() async {
    final updated = await showModalBottomSheet<ReminderSettings>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppPalette.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => ReminderSettingsSheet(
        initialSettings: _reminderSettings,
        profile: widget.profile,
        onGetPermissionState: NotificationService.instance.getPermissionState,
        onRequestNotificationPermission:
            NotificationService.instance.requestNotificationPermission,
        onRequestExactAlarmPermission:
            NotificationService.instance.requestExactAlarmPermission,
        onOpenNotificationSettings:
            NotificationService.instance.openNotificationSettings,
        onTestNotification: NotificationService.instance.showTestNotification,
      ),
    );
    if (updated == null || !mounted) return;

    setState(() => _reminderSettings = updated);
    _reminderSaveInProgress = true;
    try {
      final result = await NotificationService.instance
          .scheduleWorkoutReminders(profile: widget.profile, settings: updated);
      var cloudSynced = true;
      try {
        await widget.firestoreService
            .saveReminderSettings(widget.profile.uid, updated)
            .timeout(const Duration(seconds: 4));
      } on TimeoutException {
        // Firestore has already accepted the local write and will sync it when
        // the device reconnects. Local alarms should never wait on the cloud.
        cloudSynced = false;
      } catch (_) {
        cloudSynced = false;
      }
      if (!mounted) return;
      if (!cloudSynced) {
        showAppMessage(
          context,
          updated.anyEnabled
              ? 'Reminders are active on this device. Cloud backup will finish when you’re online.'
              : 'Workout alerts are off. Cloud backup will finish when you’re online.',
        );
      } else if (!updated.anyEnabled) {
        showAppMessage(
          context,
          'Workout alerts are off. Your chosen time is saved.',
        );
      } else if (!result.notificationsAllowed) {
        showAppMessage(
          context,
          'Your reminder is saved, but Android notifications are off for Nourish.',
        );
      } else if (updated.alarmEnabled && !result.exactTiming) {
        showAppMessage(
          context,
          'Reminders saved. Android may deliver them within a few minutes of your time.',
        );
      } else {
        showAppMessage(
          context,
          '${result.scheduledCount} reminders active for ${updated.timeLabel} on your workout days.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Nourish reminder scheduling failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        showAppMessage(
          context,
          'Your reminder could not be saved right now. Please try again.',
        );
      }
    } finally {
      _reminderSaveInProgress = false;
    }
  }

  void _openRecipe(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
    );
  }

  Future<void> _openWaterTracker() async {
    final amount = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log water', style: sheetContext.text.headlineMedium),
              const SizedBox(height: 5),
              Text(
                'Today: $_waterLoggedMl of ${widget.profile.waterTargetMl} ml',
                style: const TextStyle(color: AppPalette.muted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [150, 250, 350, 500]
                    .map(
                      (value) => ActionChip(
                        avatar: const Icon(Icons.water_drop_rounded, size: 17),
                        label: Text('+$value ml'),
                        onPressed: () => Navigator.pop(sheetContext, value),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _waterLoggedMl == 0
                    ? null
                    : () => Navigator.pop(sheetContext, -250),
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Undo 250 ml'),
              ),
            ],
          ),
        ),
      ),
    );
    if (amount == null) return;
    try {
      await widget.firestoreService.addWater(widget.profile.uid, amount);
    } catch (_) {
      if (mounted) showAppMessage(context, 'Could not update water right now.');
    }
  }

  Future<void> _editPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (editContext) => OnboardingScreen(
          initialProfile: widget.profile,
          onComplete: (updated) async {
            await widget.firestoreService.saveProfile(updated);
            if (editContext.mounted) Navigator.of(editContext).pop();
          },
        ),
      ),
    );
  }

  void _openProfile() => setState(() => _selectedIndex = 4);

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    if (_loading || plan == null) return const LoadingView();

    final screens = [
      DashboardScreen(
        profile: widget.profile,
        recipes: _recipes,
        workoutPlan: plan,
        nutrition: _todayNutrition,
        waterLoggedMl: _waterLoggedMl,
        completedWorkouts: _completedWorkouts,
        photoUrl: widget.userPhotoUrl,
        onProfileTap: _openProfile,
        onRecipeTap: _openRecipe,
        onNutritionTap: () => setState(() => _selectedIndex = 1),
        onScanTap: () => setState(() => _selectedIndex = 2),
        onWaterTap: _openWaterTracker,
        onWorkoutTap: () => setState(() => _selectedIndex = 3),
        onReminderTap: _openReminderSettings,
        remindersEnabled: _reminderSettings.anyEnabled,
      ),
      NutritionScreen(
        profile: widget.profile,
        recipes: _recipes,
        photoUrl: widget.userPhotoUrl,
        onProfileTap: _openProfile,
        onRecipeTap: _openRecipe,
      ),
      FoodScanScreen(onLogMeal: _logScannedMeal),
      WorkoutScreen(
        profile: widget.profile,
        plan: plan,
        photoUrl: widget.userPhotoUrl,
        onProfileTap: _openProfile,
        onCompleteWorkout: _completeWorkout,
      ),
      ProfileScreen(
        profile: widget.profile,
        photoUrl: widget.userPhotoUrl,
        onEditPlan: _editPlan,
        onSignOut: widget.authService.signOut,
        completedDayKeys: _completedDayKeys,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          decoration: BoxDecoration(
            color: AppPalette.ink.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppPalette.ink.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 13),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Today',
                selected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _NavItem(
                icon: Icons.restaurant_menu_rounded,
                label: 'Meals',
                selected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _NavItem(
                icon: Icons.center_focus_strong_rounded,
                label: 'Scan',
                selected: _selectedIndex == 2,
                emphasized: true,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _NavItem(
                icon: Icons.fitness_center_rounded,
                label: 'Workout',
                selected: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: _selectedIndex == 4,
                onTap: _openProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emphasized = false,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 210),
            decoration: BoxDecoration(
              color: selected
                  ? AppPalette.lime
                  : emphasized
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? AppPalette.ink
                      : Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppPalette.ink
                        : Colors.white.withValues(alpha: 0.52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
