import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/notification_service.dart';
import '../../domain/event.dart';
import '../state/events_controller.dart';
import '../state/selected_day_provider.dart';
import 'event_editor_screen.dart';

class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsControllerProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final selectedDayCtrl = ref.read(selectedDayProvider.notifier);

    final dayLabel = formatDate(selectedDay);
    final weekdayLabel = formatWeekday(selectedDay);

    Future<void> openCreateEvent() async {
      // Старт = текущее время + 10 минут, но дата = выбранный день
      final base = DateTime.now().add(const Duration(minutes: 10));

      final initialStart = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        base.hour,
        base.minute,
      );

      final initialEnd = initialStart.add(const Duration(minutes: 30));

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventEditorScreen(
            initialStart: initialStart,
            initialEnd: initialEnd,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('День'),
        actions: [
          // ✅ навигация как в Month/Week (в AppBar)
          IconButton(
            tooltip: 'Месяц',
            onPressed: () => context.go('/month'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Неделя',
            onPressed: () => context.go('/week'),
            icon: const Icon(Icons.view_week_outlined),
          ),

          // ✅ Today: единая иконка как в Month
          IconButton(
            tooltip: 'Сегодня',
            onPressed: selectedDayCtrl.today,
            icon: const Icon(Icons.my_location_outlined),
          ),

          // Тест уведомлений оставляем (короткий тап = заглушка, лонг = тест)
          IconButton(
            tooltip: 'Уведомления (удерживай для теста)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки уведомлений — скоро')),
              );
            },
            onLongPress: () {
              NotificationService.showInstant(
                id: DateTime.now().millisecondsSinceEpoch % 100000,
                title: 'Chronolink',
                body: 'Instant OK',
              );
              NotificationService.debugScheduleIn20s();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Тест: instant + schedule(20s) отправлены')),
              );
            },
            icon: const Icon(Icons.notifications_active_outlined),
          ),

          IconButton(
            tooltip: 'Удалить все события',
            onPressed: () => confirmDeleteAll(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить событие',
        onPressed: openCreateEvent,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TopBar(
                dayLabel: dayLabel,
                weekdayLabel: weekdayLabel,
                onPrev: selectedDayCtrl.prevDay,
                onNext: selectedDayCtrl.nextDay,
                onPick: () => pickDate(context, ref, selectedDay),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: eventsAsync.when(
                  data: (events) {
                    final filtered = events.where((e) {
                      return dateOnly(e.startDateTime) == selectedDay;
                    }).toList()
                      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

                    return EventsList(
                      selectedDay: selectedDay,
                      events: filtered,
                      onDelete: (id) async {
                        // deleteById уже отменяет напоминание внутри controller,
                        // но пусть будет доп. страховка (не мешает).
                        await ref.read(eventsControllerProvider.notifier).deleteById(id);
                      },
                      onTap: (event) async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventEditorScreen(initialEvent: event),
                          ),
                        );
                      },
                      onAdd: openCreateEvent,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => ErrorState(
                    message: 'Ошибка загрузки событий: $e',
                    onRetry: () => ref.invalidate(eventsControllerProvider),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> pickDate(
      BuildContext context,
      WidgetRef ref,
      DateTime selectedDay,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Выбери дату',
    );
    if (picked == null) return;
    ref.read(selectedDayProvider.notifier).setDay(dateOnly(picked));
  }

  static Future<void> confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить всё?'),
        content: const Text('Все события и напоминания будут удалены. Отменить нельзя.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Удалить')),
        ],
      ),
    );

    if (ok != true) return;

    await ref.read(eventsControllerProvider.notifier).deleteAll();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Всё удалено')),
      );
    }
  }
}

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.dayLabel,
    required this.weekdayLabel,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  final String dayLabel;
  final String weekdayLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          tooltip: 'Предыдущий день',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPick,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(dayLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    weekdayLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Следующий день',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class EventsList extends StatelessWidget {
  const EventsList({
    super.key,
    required this.selectedDay,
    required this.events,
    required this.onDelete,
    required this.onTap,
    required this.onAdd,
  });

  final DateTime selectedDay;
  final List<Event> events;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(Event event) onTap;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return EmptyState(
        dayLabel: formatDate(selectedDay),
        onAdd: onAdd,
      );
    }

    return ListView.separated(
      // ✅ запас снизу под FAB, чтобы ничего не перекрывалось
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = events[index];
        return EventCard(
          event: e,
          onTap: () => onTap(e),
          onDelete: () => onDelete(e.id),
        );
      },
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onDelete,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final timeText = event.allDay
        ? 'Весь день'
        : '${formatTime(event.startDateTime)} — ${formatTime(event.endDateTime)}';

    final reminder = event.reminderBeforeMinutes;
    final reminderText = reminder == null
        ? null
        : (reminder == 0 ? 'Сейчас' : 'За $reminder мин');

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if ((event.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.description!.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (reminderText != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text('Напоминание: $reminderText'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Удалить',
                onPressed: onDelete,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.dayLabel,
    required this.onAdd,
  });

  final String dayLabel;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'На $dayLabel событий нет',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Нажми “+”, чтобы добавить первое.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => onAdd(),
              icon: const Icon(Icons.add),
              label: const Text('Добавить событие'),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------- helpers (RU) --------

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String formatDate(DateTime dt) {
  final dd = dt.day.toString().padLeft(2, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final yyyy = dt.year.toString();
  return '$dd.$mm.$yyyy';
}

String formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$hh:$min';
}

String formatWeekday(DateTime dt) {
  const names = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];
  return names[dt.weekday - 1];
}