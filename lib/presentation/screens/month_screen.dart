import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/event.dart';
import '../state/events_controller.dart';
import '../state/selected_day_provider.dart';

class MonthScreen extends ConsumerStatefulWidget {
  const MonthScreen({super.key});

  @override
  ConsumerState<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends ConsumerState<MonthScreen> {
  late DateTime _visibleMonth; // всегда 1-е число месяца

  static const _weekdaysRu = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

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

  String _monthTitleRu(DateTime month) {
    const months = [
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

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _gridStart(DateTime monthStart) {
    final shift = monthStart.weekday - DateTime.monday; // 0..6
    return monthStart.subtract(Duration(days: shift));
  }

  List<DateTime> _buildMonthGrid(DateTime visibleMonth) {
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final start = _gridStart(monthStart);
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  int _eventCountForDay(List<Event> events, DateTime day) {
    final d = _dateOnly(day);
    var count = 0;
    for (final e in events) {
      if (_dateOnly(e.startDateTime) == d) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsControllerProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    final gridDays = _buildMonthGrid(_visibleMonth);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Месяц'),
        actions: [
          IconButton(
            tooltip: 'Неделя',
            onPressed: () => context.go('/week'),
            icon: const Icon(Icons.view_week_outlined),
          ),
          IconButton(
            tooltip: 'День',
            onPressed: () => context.go('/day'),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Предыдущий месяц',
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _monthTitleRu(_visibleMonth),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Следующий месяц',
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  for (final w in _weekdaysRu)
                    Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: eventsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Ошибка: $e')),
                  data: (events) {
                    return GridView.builder(
                      physics: const ClampingScrollPhysics(),
                      itemCount: gridDays.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        // ✅ чуть более “квадратные” клетки + запас на индикатор
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, index) {
                        final day = gridDays[index];

                        final isCurrentMonth = day.month == _visibleMonth.month;
                        final isToday = _dateOnly(day) == _dateOnly(DateTime.now());
                        final isSelected = _dateOnly(day) == _dateOnly(selectedDay);

                        final count = _eventCountForDay(events, day);

                        Color borderColor = cs.outlineVariant;
                        Color? fillColor;

                        if (isSelected) {
                          fillColor = cs.primaryContainer.withValues(alpha: 0.55);
                          borderColor = cs.primary.withValues(alpha: 0.6);
                        } else if (isToday) {
                          fillColor = cs.secondaryContainer.withValues(alpha: 0.45);
                          borderColor = cs.secondary.withValues(alpha: 0.6);
                        } else {
                          fillColor = cs.surface.withValues(alpha: 0.0);
                        }

                        final textColor = isCurrentMonth
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.35);

                        return _DayCell(
                          day: day,
                          textColor: textColor,
                          borderColor: borderColor,
                          fillColor: fillColor,
                          eventCount: count,
                          onTap: () {
                            ref.read(selectedDayProvider.notifier).setDay(day);
                            context.go('/day');
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
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.textColor,
    required this.borderColor,
    required this.fillColor,
    required this.eventCount,
    required this.onTap,
  });

  final DateTime day;
  final Color textColor;
  final Color borderColor;
  final Color? fillColor;
  final int eventCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String badgeText(int c) {
      if (c <= 1) return '';
      if (c >= 10) return '9+';
      return '$c';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.hardEdge, // ✅ чтобы ничто не вылезало наружу
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${day.day}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            if (eventCount > 0)
              Positioned(
                right: 4,
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (eventCount > 1) ...[
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        // ✅ ключ: ограничиваем ширину, чтобы не было RIGHT OVERFLOWED
                        constraints: const BoxConstraints(maxWidth: 22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              badgeText(eventCount),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}