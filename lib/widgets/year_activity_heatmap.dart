import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';

class YearActivityHeatmap extends StatefulWidget {
  const YearActivityHeatmap({
    super.key,
    required this.completedDayKeys,
    required this.year,
  });

  final Set<String> completedDayKeys;
  final int year;

  @override
  State<YearActivityHeatmap> createState() => _YearActivityHeatmapState();
}

class _YearActivityHeatmapState extends State<YearActivityHeatmap> {
  static const _cell = 10.0;
  static const _gap = 3.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealCurrentMonth());
  }

  @override
  void didUpdateWidget(covariant YearActivityHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _revealCurrentMonth(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealCurrentMonth() {
    if (!_scrollController.hasClients || widget.year != DateTime.now().year) {
      return;
    }
    final progress = (DateTime.now().month - 1) / 11;
    _scrollController.jumpTo(
      (_scrollController.position.maxScrollExtent * progress).clamp(
        0,
        _scrollController.position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(widget.year);
    final lastDay = DateTime(widget.year, 12, 31);
    final gridStart = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final gridEnd = lastDay.add(Duration(days: 7 - lastDay.weekday));
    final weekCount = gridEnd.difference(gridStart).inDays ~/ 7 + 1;
    final gridWidth = weekCount * (_cell + _gap) - _gap;
    final yearPrefix = '${widget.year}-';
    final completionCount = widget.completedDayKeys
        .where((key) => key.startsWith(yearPrefix))
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: AppPalette.lime,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.calendar_view_month_rounded,
                  color: AppPalette.ink,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completionCount completed days',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Your consistency, one day at a time',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    const SizedBox(height: 19),
                    ...List.generate(7, (index) {
                      final label = switch (index) {
                        0 => 'M',
                        2 => 'W',
                        4 => 'F',
                        _ => '',
                      };
                      return SizedBox(
                        height: _cell + _gap,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.38),
                              fontSize: 8.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: false,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: gridWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 19,
                            child: Stack(
                              children: List.generate(12, (monthIndex) {
                                final month = DateTime(
                                  widget.year,
                                  monthIndex + 1,
                                );
                                final weekOffset =
                                    month.difference(gridStart).inDays ~/ 7;
                                return Positioned(
                                  left: weekOffset * (_cell + _gap),
                                  child: Text(
                                    DateFormat('MMM').format(month),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.48,
                                      ),
                                      fontSize: 8.5,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(weekCount, (week) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: week == weekCount - 1 ? 0 : _gap,
                                ),
                                child: Column(
                                  children: List.generate(7, (weekday) {
                                    final date = gridStart.add(
                                      Duration(days: week * 7 + weekday),
                                    );
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: weekday == 6 ? 0 : _gap,
                                      ),
                                      child: _DayCell(
                                        date: date,
                                        year: widget.year,
                                        completed: widget.completedDayKeys
                                            .contains(_dateKey(date)),
                                        streakLevel: _streakLevel(date),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.swipe_rounded,
                      color: Colors.white.withValues(alpha: 0.38),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Swipe across the year',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.42),
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Less',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 5),
              ...const [
                Color(0xFF2B3734),
                Color(0xFF305C47),
                Color(0xFF388D61),
                Color(0xFF62D6B0),
                Color(0xFFB9F227),
              ].map(
                (color) => Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'More',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _streakLevel(DateTime date) {
    if (!widget.completedDayKeys.contains(_dateKey(date))) return 0;
    var streak = 1;
    for (var offset = 1; offset <= 3; offset++) {
      if (widget.completedDayKeys.contains(
        _dateKey(date.subtract(Duration(days: offset))),
      )) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.year,
    required this.completed,
    required this.streakLevel,
  });

  final DateTime date;
  final int year;
  final bool completed;
  final int streakLevel;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final isToday = DateUtils.isSameDay(date, today);
    final outsideYear = date.year != year;
    final isFuture = date.isAfter(today);
    final color = outsideYear
        ? Colors.transparent
        : completed
        ? switch (streakLevel) {
            1 => const Color(0xFF305C47),
            2 => const Color(0xFF388D61),
            3 => AppPalette.mint,
            _ => AppPalette.lime,
          }
        : isFuture
        ? Colors.white.withValues(alpha: 0.035)
        : Colors.white.withValues(alpha: 0.09);

    return Tooltip(
      message: outsideYear
          ? ''
          : '${DateFormat('EEE, d MMM').format(date)} · ${completed
                ? 'Plan complete'
                : isFuture
                ? 'Upcoming'
                : 'Not completed'}',
      child: Semantics(
        label: outsideYear
            ? null
            : '${DateFormat('d MMMM').format(date)}, ${completed ? 'daily plan completed' : 'not completed'}',
        child: Container(
          width: _YearActivityHeatmapState._cell,
          height: _YearActivityHeatmapState._cell,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
            border: isToday
                ? Border.all(color: AppPalette.lime, width: 1.1)
                : null,
          ),
        ),
      ),
    );
  }
}
