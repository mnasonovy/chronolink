import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/event.dart';
import '../state/events_controller.dart';
import '../state/selected_day_provider.dart';

class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _startOfWeekMonday(DateTime day) {
    // Dart: weekday 1..7 (Mon..Sun)
    final d = _dateOnly(day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Пн';
      case DateTime.tuesday:
        return 'Вт';
      case DateTime.wednesday:
        return 'Ср';
      case DateTime.thursday:
        return 'Чт';
      case DateTime.friday:
        return 'Пт';
      case DateTime.saturday:
        return 'Сб';
      case DateTime.sunday:
        return 'Вс';
      default:
        return '';
    }
  }

  String _dateLabel(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm';
  }

  String _timeLabel(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsControllerProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final selectedDayCtrl = ref.read(selectedDayProvider.notifier);

    final weekStart = _startOfWeekMonday(selectedDay);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronolink • Неделя'),
        actions: [
          IconButton(
            tooltip: 'Сегодня',
            onPressed: selectedDayCtrl.today,
            icon: const Icon(Icons.today),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _WeekHeader(
              weekStart: weekStart,
              onPrev: selectedDayCtrl.prevWeek,
              onNext: selectedDayCtrl.nextWeek,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: eventsAsync.when(
                data: (events) {
                  // сгруппируем события по дню
                  final byDay = <DateTime, List<Event>>{};
                  for (final d in days) {
                    byDay[_dateOnly(d)] = <Event>[];
                  }

                  for (final e in events) {
                    final d = _dateOnly(e.startDateTime);
                    if (byDay.containsKey(d)) {
                      byDay[d]!.add(e);
                    }
                  }

                  // сортировка по времени начала
                  for (final entry in byDay.entries) {
                    entry.value.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
                  }

                  return ListView.separated(
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final key = _dateOnly(day);
                      final list = byDay[key] ?? const <Event>[];

                      final isSelected = _dateOnly(selectedDay) == key;
                      final isToday = _dateOnly(DateTime.now()) == key;

                      return _DayBlock(
                        day: day,
                        weekdayText: _weekdayLabel(day.weekday),
                        dateText: _dateLabel(day),
                        isSelected: isSelected,
                        isToday: isToday,
                        events: list,
                        timeLabel: _timeLabel,
                        onOpenDay: () {
                          selectedDayCtrl.setDay(day);
                          context.go('/day');
                        },
                        onOpenEvent: (event) async {
                          // Открываем день и сразу переходим — редактирование уже в DayScreen по тапу
                          selectedDayCtrl.setDay(day);
                          context.go('/day');
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Ошибка: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Быстро прыгнуть в Day на выбранную дату и добавить событие там
          context.go('/day');
        },
        icon: const Icon(Icons.add),
        label: const Text('Событие'),
      ),
    );
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

  String _rangeLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    String fmt(DateTime d) {
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd.$mm';
    }

    return '${fmt(start)} — ${fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Предыдущая неделя',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(
              _rangeLabel(weekStart),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Следующая неделя',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.day,
    required this.weekdayText,
    required this.dateText,
    required this.isSelected,
    required this.isToday,
    required this.events,
    required this.timeLabel,
    required this.onOpenDay,
    required this.onOpenEvent,
  });

  final DateTime day;
  final String weekdayText;
  final String dateText;
  final bool isSelected;
  final bool isToday;
  final List<Event> events;
  final String Function(DateTime) timeLabel;
  final VoidCallback onOpenDay;
  final Future<void> Function(Event) onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.dividerColor;

    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpenDay,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('$weekdayText • $dateText', style: headerStyle),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Text(
                      'Сегодня',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
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
                  for (final e in events.take(5)) ...[
                    _EventRow(
                      title: e.title,
                      timeText: '${timeLabel(e.startDateTime)}–${timeLabel(e.endDateTime)}',
                      hasReminder: e.reminderBeforeMinutes != null,
                      reminderText: _reminderInline(e.reminderBeforeMinutes),
                      onTap: () => onOpenEvent(e),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (events.length > 5)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ещё ${events.length - 5}…',
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

  String _reminderInline(int? minutes) {
    if (minutes == null) return '';
    if (minutes == 0) return 'Сейчас';
    return 'за $minutes мин';
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                        fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w600,
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