import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';

class ReminderSettingsSheet extends StatefulWidget {
  const ReminderSettingsSheet({
    super.key,
    required this.initialSettings,
    required this.profile,
    required this.onGetPermissionState,
    required this.onRequestNotificationPermission,
    required this.onRequestExactAlarmPermission,
    required this.onOpenNotificationSettings,
    required this.onTestNotification,
    required this.onTestAlarm,
  });

  final ReminderSettings initialSettings;
  final UserProfile profile;
  final Future<NotificationPermissionState> Function() onGetPermissionState;
  final Future<bool> Function() onRequestNotificationPermission;
  final Future<bool> Function() onRequestExactAlarmPermission;
  final Future<bool> Function() onOpenNotificationSettings;
  final Future<bool> Function() onTestNotification;
  final Future<bool> Function() onTestAlarm;

  @override
  State<ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<ReminderSettingsSheet>
    with WidgetsBindingObserver {
  late ReminderSettings _settings;
  NotificationPermissionState? _permissions;
  bool _checkingPermissions = true;
  bool _requestingPermissions = false;
  bool _testing = false;
  bool _testingAlarm = false;
  bool _saving = false;
  String? _statusMessage;
  bool _statusSuccess = false;

  bool get _busy =>
      _checkingPermissions ||
      _requestingPermissions ||
      _testing ||
      _testingAlarm ||
      _saving;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = widget.initialSettings;
    unawaited(_refreshPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPermissions());
    }
  }

  Future<void> _refreshPermissions() async {
    if (mounted) setState(() => _checkingPermissions = true);
    try {
      final permissions = await widget.onGetPermissionState();
      if (!mounted) return;
      setState(() {
        _permissions = permissions;
        _checkingPermissions = false;
      });
    } catch (error, stackTrace) {
      developer.log(
        'Permission state check failed',
        name: 'nourish.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('Nourish permission check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _checkingPermissions = false;
        _statusSuccess = false;
        _statusMessage =
            'Android access could not be checked. Close this panel and try again.';
      });
    }
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

  Future<bool> _ensureNotificationPermission() async {
    if (_permissions?.notificationsAllowed == true) return true;
    setState(() => _requestingPermissions = true);
    try {
      final allowed = await widget.onRequestNotificationPermission();
      if (!mounted) return false;
      await _refreshPermissions();
      if (!mounted) return false;
      if (allowed || _permissions?.notificationsAllowed == true) return true;

      final openSettings = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.notifications_off_outlined),
          title: const Text('Allow Nourish notifications'),
          content: const Text(
            'Android is blocking workout alerts. Open Nourish notification settings and turn on “Allow notifications”, then return here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await widget.onOpenNotificationSettings();
        await _refreshPermissions();
      }
      return _permissions?.notificationsAllowed == true;
    } catch (error, stackTrace) {
      debugPrint('Nourish notification permission request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _statusSuccess = false;
          _statusMessage =
              'Android could not open notification access. Please try again.';
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _requestingPermissions = false);
    }
  }

  Future<bool> _ensureExactAlarmPermission() async {
    if (_permissions?.exactAlarmsAllowed == true) return true;
    final continueToAndroid = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.alarm_rounded),
        title: const Text('Allow exact workout alarms'),
        content: const Text(
          'Android keeps precise alarms behind a separate switch. On the next screen, turn on “Allow setting alarms and reminders”, then come back to Nourish.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (continueToAndroid != true || !mounted) return false;

    setState(() => _requestingPermissions = true);
    try {
      final allowed = await widget.onRequestExactAlarmPermission();
      if (!mounted) return false;
      await _refreshPermissions();
      return allowed || _permissions?.exactAlarmsAllowed == true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusSuccess = false;
          _statusMessage =
              'Exact-alarm access could not be opened. Please try again.';
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _requestingPermissions = false);
    }
  }

  Future<void> _toggleAlarm(bool value) async {
    setState(() {
      _settings = _settings.copyWith(alarmEnabled: value);
      _statusMessage = null;
    });
    if (!value) return;
    if (!await _ensureNotificationPermission() || !mounted) return;
    await _ensureExactAlarmPermission();
  }

  Future<void> _toggleAdvance(bool value) async {
    setState(() {
      _settings = _settings.copyWith(advanceEnabled: value);
      _statusMessage = null;
    });
    if (value) await _ensureNotificationPermission();
  }

  Future<void> _testNotification() async {
    setState(() {
      _testing = true;
      _statusMessage = null;
    });
    try {
      if (!await _ensureNotificationPermission() || !mounted) {
        setState(() {
          _statusSuccess = false;
          _statusMessage =
              'Test not sent. Allow notifications above, then try once more.';
        });
        return;
      }
      final sent = await widget.onTestNotification();
      if (!mounted) return;
      setState(() {
        _statusSuccess = sent;
        _statusMessage = sent
            ? 'Test sent. Pull down your notification tray to see it.'
            : 'Test not sent. Android notifications are still blocked.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusSuccess = false;
          _statusMessage =
              'The test alert could not be sent right now. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _testAlarm() async {
    setState(() {
      _testingAlarm = true;
      _statusMessage = null;
    });
    try {
      if (!await _ensureNotificationPermission() || !mounted) {
        setState(() {
          _statusSuccess = false;
          _statusMessage =
              'Alarm test not started. Allow notifications, then try once more.';
        });
        return;
      }
      if (!await _ensureExactAlarmPermission() || !mounted) {
        setState(() {
          _statusSuccess = false;
          _statusMessage =
              'The scheduled test needs exact-alarm access. Allow it, then try again.';
        });
        return;
      }
      final sent = await widget.onTestAlarm();
      if (!mounted) return;
      setState(() {
        _statusSuccess = sent;
        _statusMessage = sent
            ? 'Scheduled test ready. It will ring in 10 seconds using your phone’s Alarm volume.'
            : 'Alarm test was not registered by Android. Check the access card and try again.';
      });
    } catch (error, stackTrace) {
      debugPrint('Nourish alarm sound test failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _statusSuccess = false;
          _statusMessage =
              'The alarm sound could not be tested right now. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _testingAlarm = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _statusMessage = null;
    });
    try {
      if (_settings.anyEnabled && !await _ensureNotificationPermission()) {
        if (!mounted) return;
        setState(() {
          _statusSuccess = false;
          _statusMessage =
              'Reminders were not saved because Android notifications are off.';
        });
        return;
      }
      if (_settings.alarmEnabled && !await _ensureExactAlarmPermission()) {
        if (!mounted) return;
        setState(() {
          _statusSuccess = false;
          _statusMessage =
              'The alarm was not saved. Allow exact alarms, or switch the workout-time alarm off.';
        });
        return;
      }
      if (mounted) Navigator.of(context).pop(_settings);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextAlarm = _settings.alarmEnabled
        ? nextWorkoutAlarmAt(
            workoutDays: widget.profile.availableWorkoutDays,
            hour: _settings.hour,
            minute: _settings.minute,
          )
        : null;
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
                onTap: _busy ? null : _chooseTime,
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
                      'Precise sound and vibration at your chosen time',
                      style: TextStyle(color: AppPalette.muted, fontSize: 11),
                    ),
                    value: _settings.alarmEnabled,
                    onChanged: _busy ? null : _toggleAlarm,
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
                    onChanged: _busy ? null : _toggleAdvance,
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
                                    onSelected: _busy
                                        ? null
                                        : (_) => setState(
                                            () =>
                                                _settings = _settings.copyWith(
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
            const SizedBox(height: 16),
            _PermissionCard(
              checking: _checkingPermissions,
              requesting: _requestingPermissions,
              notificationsAllowed: _permissions?.notificationsAllowed == true,
              showExactAlarm: _settings.alarmEnabled,
              exactAlarmsAllowed: _permissions?.exactAlarmsAllowed == true,
              onAllowNotifications: _busy
                  ? null
                  : _ensureNotificationPermission,
              onAllowExactAlarms: _busy ? null : _ensureExactAlarmPermission,
            ),
            const SizedBox(height: 14),
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
            if (nextAlarm != null) ...[
              const SizedBox(height: 12),
              _NextAlarmCard(alarmAt: nextAlarm),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              _InlineStatus(message: _statusMessage!, success: _statusSuccess),
            ],
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _busy ? null : _testNotification,
              icon: _testing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notification_add_outlined),
              label: const Text('Send a test notification'),
            ),
            if (_settings.alarmEnabled)
              TextButton.icon(
                onPressed: _busy ? null : _testAlarm,
                icon: _testingAlarm
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.alarm_on_rounded),
                label: const Text('Test scheduled alarm · 10 sec'),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppPalette.ink,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _settings.anyEnabled
                    ? 'Save active reminders'
                    : 'Save with alerts off',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextAlarmCard extends StatelessWidget {
  const _NextAlarmCard({required this.alarmAt});

  final DateTime alarmAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8FBD8), Color(0xFFF2F9E5)],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFD3EAB8)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppPalette.lime,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.alarm_on_rounded, color: AppPalette.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next alarm ${formatAlarmCountdown(alarmAt)}',
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatAlarmDayAndTime(alarmAt),
                  style: const TextStyle(
                    color: AppPalette.inkSoft,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppPalette.inkSoft),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.checking,
    required this.requesting,
    required this.notificationsAllowed,
    required this.showExactAlarm,
    required this.exactAlarmsAllowed,
    required this.onAllowNotifications,
    required this.onAllowExactAlarms,
  });

  final bool checking;
  final bool requesting;
  final bool notificationsAllowed;
  final bool showExactAlarm;
  final bool exactAlarmsAllowed;
  final Future<bool> Function()? onAllowNotifications;
  final Future<bool> Function()? onAllowExactAlarms;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Android access',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              if (checking || requesting)
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _PermissionRow(
            label: notificationsAllowed
                ? 'Notifications allowed'
                : 'Notifications are off',
            allowed: notificationsAllowed,
            buttonLabel: 'Allow',
            onPressed: notificationsAllowed ? null : onAllowNotifications,
          ),
          if (showExactAlarm) ...[
            const Divider(height: 20),
            _PermissionRow(
              label: exactAlarmsAllowed
                  ? 'Exact alarms allowed'
                  : 'Exact alarm access needed',
              allowed: exactAlarmsAllowed,
              buttonLabel: 'Allow exact',
              onPressed: exactAlarmsAllowed ? null : onAllowExactAlarms,
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.allowed,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String label;
  final bool allowed;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = allowed ? const Color(0xFF18865A) : AppPalette.coral;
    return Row(
      children: [
        Icon(
          allowed ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: color,
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: allowed ? AppPalette.inkSoft : color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        if (!allowed)
          TextButton(onPressed: onPressed, child: Text(buttonLabel)),
      ],
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.message, required this.success});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF18865A) : AppPalette.coral;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppPalette.inkSoft,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
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
