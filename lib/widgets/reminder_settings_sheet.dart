import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';
import 'shared_ui.dart';

class ReminderSettingsSheet extends StatefulWidget {
  const ReminderSettingsSheet({
    super.key,
    required this.initialSettings,
    required this.profile,
    required this.onTestNotification,
  });

  final ReminderSettings initialSettings;
  final UserProfile profile;
  final Future<bool> Function() onTestNotification;

  @override
  State<ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<ReminderSettingsSheet> {
  late ReminderSettings _settings;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _settings.hour, minute: _settings.minute),
      helpText: 'WHEN SHOULD NOURISH REMIND YOU?',
    );
    if (selected == null || !mounted) return;
    setState(
      () => _settings = _settings.copyWith(
        hour: selected.hour,
        minute: selected.minute,
      ),
    );
  }

  Future<void> _testNotification() async {
    setState(() => _testing = true);
    try {
      final allowed = await widget.onTestNotification();
      if (!mounted) return;
      showAppMessage(
        context,
        allowed
            ? 'Test notification sent.'
            : 'Notifications are off in Android settings. You can enable them whenever you’re ready.',
      );
    } catch (_) {
      if (mounted) {
        showAppMessage(
          context,
          'The test alert could not be sent right now. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          2,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/images/nourish_logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout reminders',
                        style: context.text.headlineMedium,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'A helpful nudge, only on your training days.',
                        style: TextStyle(color: AppPalette.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Material(
              color: AppPalette.ink,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                onTap: _chooseTime,
                borderRadius: BorderRadius.circular(25),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: AppPalette.lime,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.alarm_rounded),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WORKOUT TIME',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                fontSize: 9.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _settings.timeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_rounded, color: AppPalette.lime),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 5, 8, 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppPalette.line),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const _ReminderIcon(
                      icon: Icons.notifications_active_rounded,
                      color: AppPalette.coral,
                    ),
                    title: const Text(
                      'Workout-time alarm',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Sound and vibration · Android may ask once',
                      style: TextStyle(color: AppPalette.muted, fontSize: 11),
                    ),
                    value: _settings.alarmEnabled,
                    onChanged: (value) => setState(
                      () => _settings = _settings.copyWith(alarmEnabled: value),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const _ReminderIcon(
                      icon: Icons.energy_savings_leaf_rounded,
                      color: AppPalette.mint,
                    ),
                    title: const Text(
                      'Get-ready notification',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'A calm heads-up before your workout',
                      style: TextStyle(color: AppPalette.muted, fontSize: 11),
                    ),
                    value: _settings.advanceEnabled,
                    onChanged: (value) => setState(
                      () =>
                          _settings = _settings.copyWith(advanceEnabled: value),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _settings.advanceEnabled
                  ? Padding(
                      key: const ValueKey('advance-options'),
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remind me before',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 8,
                            children: [15, 30, 60]
                                .map(
                                  (minutes) => ChoiceChip(
                                    label: Text('$minutes min'),
                                    selected:
                                        _settings.advanceMinutes == minutes,
                                    onSelected: (_) => setState(
                                      () => _settings = _settings.copyWith(
                                        advanceMinutes: minutes,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-options')),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9F3),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Alerts repeat on ${widget.profile.availableWorkoutDays.join(', ')}. Change these days from Profile → Edit goals.',
                      style: const TextStyle(
                        color: AppPalette.inkSoft,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: _testing ? null : _testNotification,
              icon: _testing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notification_add_outlined),
              label: const Text('Send a test notification'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_settings),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                _settings.anyEnabled
                    ? 'Save reminders'
                    : 'Save with alerts off',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderIcon extends StatelessWidget {
  const _ReminderIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
