import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/utils/date_format.dart';
import '../../domain/event.dart';
import '../state/events_controller.dart';
import '../state/selected_day_provider.dart';

class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsControllerProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final selectedDayNotifier = ref.read(selectedDayProvider.notifier);

    final weekStart = _startOfWeekMonday(selectedDay);
    final weekDays = List.generate(
      7,
          (index) => weekStart.add(Duration(days: index)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Неделя'),
        actions: [
          IconButton(
            tooltip: 'Главный экран',
            onPressed: () => context.go(AppRoute.home),
            icon: const Icon(Icons.home_outlined),
          ),
          IconButton(
            tooltip: 'Месяц',
            onPressed: () => context.go(AppRoute.month),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'День',
            onPressed: () => context.go(AppRoute.day),
            icon: const Icon(Icons.calendar_view_day_outlined),
          ),
          IconButton(
            tooltip: 'Сегодня',
            onPressed: selectedDayNotifier.today,
            icon: const Icon(Icons.my_location_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _WeekHeader(
                weekStart: weekStart,
                onPrev: selectedDayNotifier.prevWeek,
                onNext: selectedDayNotifier.nextWeek,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRect(
                  child: eventsAsync.when(
                    data: (events) {
                      final eventsByDay = _groupEventsByDay(
                        events: events,
                        weekDays: weekDays,
                      );

                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
                        physics: const ClampingScrollPhysics(),
                        itemCount: weekDays.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final day = weekDays[index];
                          final dayKey = dateOnly(day);
                          final dayEvents = eventsByDay[dayKey] ?? const <Event>[];

                          final isSelected = dateOnly(selectedDay) == dayKey;
                          final isToday = dateOnly(DateTime.now()) == dayKey;

                          return _DayBlock(
                            weekdayText: _shortWeekday(day),
                            dateText: _shortDate(day),
                            isSelected: isSelected,
                            isToday: isToday,
                            events: dayEvents,
                            onOpenDay: () {
                              selectedDayNotifier.setDay(day);
                              context.go(AppRoute.day);
                            },
                            onOpenEvent: (event) async {
                              selectedDayNotifier.setDay(day);
                              context.go(AppRoute.day);
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                    const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) =>
                        Center(child: Text('Ошибка: $error')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить событие',
        onPressed: () => context.go(AppRoute.day),
        child: const Icon(Icons.add),
      ),
    );
  }

  static Map<DateTime, List<Event>> _groupEventsByDay({
    required List<Event> events,
    required List<DateTime> weekDays,
  }) {
    final result = <DateTime, List<Event>>{
      for (final day in weekDays) dateOnly(day): <Event>[],
    };

    for (final event in events) {
      final eventDay = dateOnly(event.startDateTime);
      if (result.containsKey(eventDay)) {
        result[eventDay]!.add(event);
      }
    }

    for (final dayEvents in result.values) {
      dayEvents.sort(
            (a, b) => a.startDateTime.compareTo(b.startDateTime),
      );
    }

    return result;
  }

  static DateTime _startOfWeekMonday(DateTime day) {
    final normalized = dateOnly(day);
    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }

  static String _shortWeekday(DateTime day) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return labels[day.weekday - 1];
  }

  static String _shortDate(DateTime day) {
    final dd = day.day.toString().padLeft(2, '0');
    final mm = day.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Предыдущая неделя',
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _weekRangeLabel(weekStart),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Следующая неделя',
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                _WeekdayBadge('Пн'),
                _WeekdayBadge('Вт'),
                _WeekdayBadge('Ср'),
                _WeekdayBadge('Чт'),
                _WeekdayBadge('Пт'),
                _WeekdayBadge('Сб'),
                _WeekdayBadge('Вс'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _weekRangeLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return '${_shortDate(start)} — ${_shortDate(end)}';
  }

  String _shortDate(DateTime day) {
    final dd = day.day.toString().padLeft(2, '0');
    final mm = day.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }
}

class _WeekdayBadge extends StatelessWidget {
  const _WeekdayBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Center(
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.weekdayText,
    required this.dateText,
    required this.isSelected,
    required this.isToday,
    required this.events,
    required this.onOpenDay,
    required this.onOpenEvent,
  });

  final String weekdayText;
  final String dateText;
  final bool isSelected;
  final bool isToday;
  final List<Event> events;
  final VoidCallback onOpenDay;
  final Future<void> Function(Event event) onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final borderColor =
    isSelected ? theme.colorScheme.primary : theme.dividerColor;

    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpenDay,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('$weekdayText • $dateText', style: headerStyle),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Text(
                      'Сегодня',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (events.isEmpty)
              Text(
                'Нет событий',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Column(
                children: [
                  for (final event in events.take(6)) ...[
                    _EventRow(
                      title: event.title,
                      timeText: event.allDay
                          ? 'Весь день'
                          : '${formatTime(event.startDateTime)}–${formatTime(event.endDateTime)}',
                      hasReminder: event.reminderBeforeMinutes != null,
                      reminderText: _reminderText(event.reminderBeforeMinutes),
                      onTap: () => onOpenEvent(event),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (events.length > 6)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ещё ${events.length - 6}…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _reminderText(int? reminderMinutes) {
    if (reminderMinutes == null) return '';
    if (reminderMinutes == 0) return 'к началу';
    return 'за $reminderMinutes мин';
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.title,
    required this.timeText,
    required this.hasReminder,
    required this.reminderText,
    required this.onTap,
  });

  final String title;
  final String timeText;
  final bool hasReminder;
  final String reminderText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasReminder) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  reminderText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}