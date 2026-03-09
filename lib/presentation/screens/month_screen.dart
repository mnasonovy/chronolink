import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../domain/event.dart';
import '../state/events_controller.dart';
import '../state/selected_day_provider.dart';

class MonthScreen extends ConsumerStatefulWidget {
  const MonthScreen({super.key});

  @override
  ConsumerState<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends ConsumerState<MonthScreen> {
  static const List<String> _weekdayLabels = <String>[
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _visibleMonth = DateTime(now.year, now.month, 1);
    });

    ref.read(selectedDayProvider.notifier).setDay(today);
  }

  DateTime _gridStart(DateTime monthStart) {
    final shift = monthStart.weekday - DateTime.monday;
    return monthStart.subtract(Duration(days: shift));
  }

  List<DateTime> _buildMonthGrid(DateTime visibleMonth) {
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final start = _gridStart(monthStart);
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  int _eventCountForDay(List<Event> events, DateTime day) {
    final normalizedDay = dateOnly(day);
    var count = 0;

    for (final event in events) {
      if (dateOnly(event.startDateTime) == normalizedDay) {
        count++;
      }
    }

    return count;
  }

  String _monthTitle(DateTime month) {
    const months = <String>[
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];

    return '${months[month.month - 1]} ${month.year}';
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsControllerProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final selectedDayNotifier = ref.read(selectedDayProvider.notifier);

    final gridDays = _buildMonthGrid(_visibleMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Месяц'),
        actions: [
          IconButton(
            tooltip: 'Главный экран',
            onPressed: () => context.go(AppRoute.home),
            icon: const Icon(Icons.home_outlined),
          ),
          IconButton(
            tooltip: 'Неделя',
            onPressed: () => context.go(AppRoute.week),
            icon: const Icon(Icons.view_week_outlined),
          ),
          IconButton(
            tooltip: 'День',
            onPressed: () => context.go(AppRoute.day),
            icon: const Icon(Icons.calendar_view_day_outlined),
          ),
          IconButton(
            tooltip: 'Сегодня',
            onPressed: _goToday,
            icon: const Icon(Icons.my_location_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              _MonthHeader(
                title: _monthTitle(_visibleMonth),
                onPrev: _prevMonth,
                onNext: _nextMonth,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final label in _weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: eventsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Text('Ошибка: $error'),
                  ),
                  data: (events) {
                    return GridView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: gridDays.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder: (context, index) {
                        final day = gridDays[index];
                        final normalizedDay = dateOnly(day);

                        final isCurrentMonth = day.month == _visibleMonth.month;
                        final isToday = normalizedDay == dateOnly(DateTime.now());
                        final isSelected = normalizedDay == dateOnly(selectedDay);

                        final eventCount = _eventCountForDay(events, day);

                        final colors = _dayCellColors(
                          isCurrentMonth: isCurrentMonth,
                          isToday: isToday,
                          isSelected: isSelected,
                        );

                        return _DayCell(
                          day: day,
                          textColor: colors.textColor,
                          borderColor: colors.borderColor,
                          fillColor: colors.fillColor,
                          eventCount: eventCount,
                          isSelected: isSelected,
                          isToday: isToday,
                          onTap: () {
                            selectedDayNotifier.setDay(day);
                            context.go(AppRoute.day);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _DayCellColors _dayCellColors({
    required bool isCurrentMonth,
    required bool isToday,
    required bool isSelected,
  }) {
    Color borderColor = AppColors.border;
    Color fillColor = AppColors.surface;

    if (isSelected) {
      fillColor = AppColors.primarySoft;
      borderColor = AppColors.primary;
    } else if (isToday) {
      fillColor = AppColors.todayBadge;
      borderColor = AppColors.accent;
    }

    final textColor =
    isCurrentMonth ? AppColors.textPrimary : AppColors.textMuted;

    return _DayCellColors(
      borderColor: borderColor,
      fillColor: fillColor,
      textColor: textColor,
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.onPrev,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Предыдущий месяц',
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Следующий месяц',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.textColor,
    required this.borderColor,
    required this.fillColor,
    required this.eventCount,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final Color textColor;
  final Color borderColor;
  final Color fillColor;
  final int eventCount;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : (isToday ? 1.2 : 1),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Text(
                '${day.day}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isToday && !isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (eventCount > 0)
              Positioned(
                right: 0,
                bottom: 0,
                child: _EventDotsIndicator(count: eventCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventDotsIndicator extends StatelessWidget {
  const _EventDotsIndicator({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final dotsCount = count >= 3 ? 3 : count;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        dotsCount,
            (index) => Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCellColors {
  const _DayCellColors({
    required this.borderColor,
    required this.fillColor,
    required this.textColor,
  });

  final Color borderColor;
  final Color fillColor;
  final Color textColor;
}